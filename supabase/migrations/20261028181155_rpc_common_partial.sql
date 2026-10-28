create or replace function public.common_get_my_context() returns jsonb
language plpgsql stable security definer set search_path=public,private,pg_temp as $$
declare v_user uuid := auth.uid();
begin
 if v_user is null then raise exception 'UNAUTHENTICATED' using errcode='P0001'; end if;
 return jsonb_build_object(
  'profile',(select to_jsonb(p) from public.profiles p where p.id=v_user),
  'workspaces',coalesce((select jsonb_agg(jsonb_build_object(
    'workspace_id',m.workspace_id,'kind',w.kind,'name',w.display_name,'status',m.status,
    'permissions',private.member_permissions(m.id)))
    from public.workspace_members m join public.workspaces w on w.id=m.workspace_id
    where m.user_id=v_user),'[]'::jsonb),
  'staff_session_verified',private.staff_session_verified());
end $$;
create or replace function public.common_update_profile(
 p_full_name text,p_phone_has_whatsapp boolean,p_whatsapp_e164 text,p_locale text,p_avatar_key text
) returns jsonb language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_user uuid:=auth.uid(); v_profile jsonb;
begin
 if not private.current_profile_active() then raise exception 'ACCOUNT_SUSPENDED' using errcode='P0001'; end if;
 if char_length(p_full_name) not between 2 and 80 or p_locale not in ('ar','en') or
   (p_phone_has_whatsapp and p_whatsapp_e164 is not null) or
   (p_whatsapp_e164 is not null and p_whatsapp_e164 !~ '^\+201[0125][0-9]{8}$') then
   raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
 update public.profiles set full_name=p_full_name,phone_has_whatsapp=p_phone_has_whatsapp,
   whatsapp_e164=p_whatsapp_e164,locale=p_locale,avatar_key=p_avatar_key where id=v_user
 returning to_jsonb(profiles) into v_profile;
 insert into public.audit_log(actor_user_id,actor_scope,action,entity_type,entity_id,after)
 values(v_user,'guest','profile.updated','profile',v_user,
   jsonb_build_object('full_name',p_full_name,'locale',p_locale));
 return v_profile;
end $$;
create or replace function public.common_heartbeat(p_workspace_id uuid default null) returns void
language plpgsql security definer set search_path=public,private,pg_temp as $$
begin
 if not private.current_profile_active() then raise exception 'ACCOUNT_SUSPENDED' using errcode='P0001'; end if;
 update public.profiles set last_seen_at=now() where id=auth.uid();
 if p_workspace_id is not null then
   update public.workspace_members set last_active_at=now()
   where workspace_id=p_workspace_id and user_id=auth.uid() and status='active';
 end if;
end $$;
create or replace function public.common_list_notifications(
 p_category text default null,p_unread_only boolean default false,p_workspace_id uuid default null,
 p_cursor timestamptz default null,p_limit integer default 30
) returns setof public.notifications language plpgsql stable security definer set search_path=public,private,pg_temp as $$
begin
 if auth.uid() is null then raise exception 'UNAUTHENTICATED' using errcode='P0001'; end if;
 return query select n.* from public.notifications n where n.user_id=auth.uid()
  and (p_category is null or n.category=p_category) and (not p_unread_only or n.read_at is null)
  and (p_workspace_id is null or n.workspace_id=p_workspace_id)
  and (p_cursor is null or n.created_at<p_cursor)
  order by n.created_at desc limit least(greatest(p_limit,1),100);
end $$;
create or replace function public.common_unread_count(p_workspace_id uuid default null) returns bigint
language sql stable security definer set search_path=public,private,pg_temp as $$
 select count(*) from public.notifications where user_id=auth.uid() and read_at is null
 and (p_workspace_id is null or workspace_id=p_workspace_id)
$$;
create or replace function public.common_mark_notifications_read(p_ids uuid[] default null) returns integer
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_count integer;
begin
 if auth.uid() is null then raise exception 'UNAUTHENTICATED' using errcode='P0001'; end if;
 update public.notifications set read_at=coalesce(read_at,now())
 where user_id=auth.uid() and read_at is null and (p_ids is null or id=any(p_ids));
 get diagnostics v_count=row_count;
 return v_count;
end $$;
create or replace function public.common_get_notification_preferences() returns setof public.notification_preferences
language sql stable security definer set search_path=public,private,pg_temp as $$
 select * from public.notification_preferences where user_id=auth.uid()
$$;
create or replace function public.common_set_notification_preferences(p_items jsonb) returns void
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_item jsonb;
begin
 if not private.current_profile_active() then raise exception 'ACCOUNT_SUSPENDED' using errcode='P0001'; end if;
 if jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)>50 then
  raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
 for v_item in select * from jsonb_array_elements(p_items) loop
  if v_item->>'channel' not in ('push','email','web_push') then
   raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
  insert into public.notification_preferences(user_id,category,channel,enabled)
  values(auth.uid(),v_item->>'category',v_item->>'channel',(v_item->>'enabled')::boolean)
  on conflict(user_id,category,channel) do update set enabled=excluded.enabled;
 end loop;
end $$;
create or replace function public.common_register_device(
 p_token text,p_app text,p_platform text,p_locale text default 'ar'
) returns uuid language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_id uuid;
begin
 if not private.current_profile_active() then raise exception 'ACCOUNT_SUSPENDED' using errcode='P0001'; end if;
 if length(p_token)<16 or length(p_token)>4096 or p_app not in ('guest','partner','admin_web') or
 p_platform not in ('android','ios','web') or p_locale not in ('ar','en') then
 raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
 if exists(select 1 from public.device_tokens where token=p_token and user_id<>auth.uid()) then
  raise exception 'CONFLICT' using errcode='P0001'; end if;
 insert into public.device_tokens(user_id,app,platform,token,locale)
 values(auth.uid(),p_app,p_platform,p_token,p_locale)
 on conflict(token) do update set user_id=excluded.user_id,app=excluded.app,
 platform=excluded.platform,locale=excluded.locale,last_seen_at=now()
 returning id into v_id;
 return v_id;
end $$;
create or replace function public.common_unregister_device(p_token text) returns void
language plpgsql security definer set search_path=public,private,pg_temp as $$
begin delete from public.device_tokens where token=p_token and user_id=auth.uid(); end $$;
create or replace function public.common_list_faq(p_audience text) returns setof public.faq_items
language sql stable security definer set search_path=public,private,pg_temp as $$
 select * from public.faq_items where is_published and audience=p_audience order by sort_order,id
$$;
revoke all on function public.common_get_my_context(),
 public.common_update_profile(text,boolean,text,text,text),public.common_heartbeat(uuid),
 public.common_list_notifications(text,boolean,uuid,timestamptz,integer),public.common_unread_count(uuid),
 public.common_mark_notifications_read(uuid[]),public.common_get_notification_preferences(),
 public.common_set_notification_preferences(jsonb),public.common_register_device(text,text,text,text),
 public.common_unregister_device(text),public.common_list_faq(text) from public,anon;
grant execute on function public.common_get_my_context(),
 public.common_update_profile(text,boolean,text,text,text),public.common_heartbeat(uuid),
 public.common_list_notifications(text,boolean,uuid,timestamptz,integer),public.common_unread_count(uuid),
 public.common_mark_notifications_read(uuid[]),public.common_get_notification_preferences(),
 public.common_set_notification_preferences(jsonb),public.common_register_device(text,text,text,text),
 public.common_unregister_device(text),public.common_list_faq(text) to authenticated;
grant execute on function public.common_list_faq(text) to anon;
