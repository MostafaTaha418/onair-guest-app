create or replace function private.workspace_recipients(p_workspace_id uuid,p_perm text,p_property_id uuid default null)
returns setof uuid language sql stable security definer set search_path=public,private,pg_temp as $$
 select m.user_id from public.workspace_members m join public.profiles p on p.id=m.user_id
 join public.workspaces w on w.id=m.workspace_id
 where m.workspace_id=p_workspace_id and m.status='active' and p.status='active'
 and w.verification_status<>'suspended' and p_perm=any(private.member_permissions(m.id))
 and (p_property_id is null or m.all_properties or exists(select 1 from public.member_property_assignments a
 where a.member_id=m.id and a.property_id=p_property_id))
$$;
create or replace function private.platform_recipients(p_perm text)
returns setof uuid language sql stable security definer set search_path=public,private,pg_temp as $$
 select m.user_id from public.workspace_members m join public.profiles p on p.id=m.user_id
 join public.workspaces w on w.id=m.workspace_id
 where w.kind='platform' and m.status='active' and p.status='active'
 and w.verification_status<>'suspended' and p_perm=any(private.member_permissions(m.id))
$$;
create or replace function private.notify(p_type_key text,p_entity_type text,p_entity_id uuid,
 p_workspace_id uuid default null,p_property_id uuid default null,p_params jsonb default '{}'::jsonb)
returns integer language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_type public.notification_types%rowtype; v_rule jsonb; v_user uuid;
 v_audience text; v_workspace uuid; v_notification_id uuid; v_channel text; v_count integer:=0;
begin
 select * into v_type from public.notification_types where key=p_type_key and is_active;
 if not found then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 if v_type.entity_type<>p_entity_type or p_params ?| array['phone','email','address','markup','amount_minor'] then
  raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
 for v_rule in select * from jsonb_array_elements(v_type.recipients) loop
  v_audience:=v_rule->>'audience';
  for v_user in
   select distinct id from (
    select b.guest_user_id id from public.bookings b
    where v_audience='guest' and v_rule->>'rule'='booking_guest' and b.id=p_entity_id
    union all
    select p.id from public.profiles p where v_rule->>'rule'='member_self'
     and p.id=(p_params->>'user_id')::uuid
    union all
    select p.id from public.profiles p where v_rule->>'rule'='actor' and p.id=auth.uid()
    union all
    select x from private.workspace_recipients(p_workspace_id,v_rule->>'perm',p_property_id) x
     where v_audience='partner' and v_rule ? 'perm'
    union all
    select x from private.platform_recipients(v_rule->>'perm') x
     where v_audience='platform' and v_rule ? 'perm'
   ) recipients where id is not null
  loop
   if v_user=auth.uid() and coalesce((v_rule->>'include_actor')::boolean,false)=false then continue; end if;
   v_workspace:=case when v_audience='guest' then null when v_audience='platform'
    then '00000000-0000-4000-8000-000000000001'::uuid else p_workspace_id end;
   insert into public.notifications(user_id,audience,workspace_id,type_key,category,priority,
    entity_type,entity_id,title_key,body_key,params)
   values(v_user,v_audience,v_workspace,p_type_key,v_type.category,v_type.priority,
    p_entity_type,p_entity_id,'notif_'||replace(p_type_key,'.','_')||'_title',
    'notif_'||replace(p_type_key,'.','_')||'_body',p_params)
   returning id into v_notification_id;
   v_count:=v_count+1;
   for v_channel in select jsonb_array_elements_text(coalesce(v_type.channels->v_audience,'[]'::jsonb)) loop
    if v_channel='in_app' then continue; end if;
    if not v_type.is_mandatory and exists(select 1 from public.notification_preferences np
     where np.user_id=v_user and np.category=v_type.category and np.channel=v_channel and not np.enabled) then
     continue; end if;
    insert into public.notification_deliveries(notification_id,channel,to_user_id,template_key,payload)
    values(v_notification_id,v_channel,v_user,p_type_key,
     jsonb_build_object('type',p_type_key,'entity_type',p_entity_type,'entity_id',p_entity_id));
   end loop;
  end loop;
 end loop;
 return v_count;
end $$;
insert into public.notification_types(key,category,recipients,channels,priority,is_mandatory,entity_type)
values
 ('booking.request_received','booking','[{"audience":"guest","rule":"booking_guest","include_actor":true},{"audience":"partner","perm":"bookings.respond"},{"audience":"platform","perm":"bookings.monitor"}]',
 '{"guest":["in_app","push"],"partner":["in_app","push","email"],"platform":["in_app","web_push"]}','critical',true,'booking'),
 ('booking.confirmed','booking','[{"audience":"guest","rule":"booking_guest"},{"audience":"partner","perm":"bookings.view"},{"audience":"platform","perm":"bookings.monitor"}]',
 '{"guest":["in_app","push","email"],"partner":["in_app","push"],"platform":["in_app"]}','high',true,'booking'),
 ('booking.rejected','booking','[{"audience":"guest","rule":"booking_guest"},{"audience":"partner","perm":"bookings.view"},{"audience":"platform","perm":"support.handle"}]',
 '{"guest":["in_app","push","email"],"partner":["in_app"],"platform":["in_app","web_push"]}','high',true,'booking'),
 ('booking.expired','booking','[{"audience":"guest","rule":"booking_guest"},{"audience":"partner","perm":"bookings.respond"},{"audience":"platform","perm":"support.handle"}]',
 '{"guest":["in_app","push","email"],"partner":["in_app","push"],"platform":["in_app","web_push"]}','high',true,'booking'),
 ('booking.payment_conflict','booking','[{"audience":"guest","rule":"booking_guest"},{"audience":"platform","perm":"support.handle"}]',
 '{"guest":["in_app","push","email"],"platform":["in_app","web_push"]}','critical',true,'booking');
revoke all on function private.workspace_recipients(uuid,text,uuid),
 private.platform_recipients(text),private.notify(text,text,uuid,uuid,uuid,jsonb)
 from public,anon,authenticated;
