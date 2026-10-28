insert into public.notification_types(key,category,recipients,channels,priority,is_mandatory,entity_type)
values
 ('stay.host_handover_confirmed','stay','[{"audience":"guest","rule":"booking_guest"}]',
 '{"guest":["in_app","push"]}','high',false,'booking'),
 ('stay.guest_checkin_confirmed','stay','[{"audience":"partner","perm":"stays.handover"}]',
 '{"partner":["in_app","push"]}','high',false,'booking'),
 ('stay.checked_in','stay','[{"audience":"guest","rule":"booking_guest"},{"audience":"partner","perm":"bookings.view"}]',
 '{"guest":["in_app"],"partner":["in_app"]}','normal',false,'booking'),
 ('stay.guest_checkout_confirmed','stay','[{"audience":"partner","perm":"stays.handover"}]',
 '{"partner":["in_app","push"]}','high',false,'booking'),
 ('stay.completed','stay','[{"audience":"guest","rule":"booking_guest"},{"audience":"partner","perm":"bookings.view"}]',
 '{"guest":["in_app","push"],"partner":["in_app"]}','normal',false,'booking');
create or replace function private.advance_stay(p_booking_id uuid) returns text
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_booking public.bookings%rowtype; v_base bigint; v_markup bigint;
begin
 select * into v_booking from public.bookings where id=p_booking_id for update;
 if not found then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 if v_booking.status='confirmed' and v_booking.checkin_guest_at is not null
 and v_booking.checkin_host_at is not null then
  if v_booking.paid_minor<v_booking.total_minor then
   raise exception 'REMAINING_NOT_PAID' using errcode='P0001'; end if;
  v_base:=v_booking.base_nightly_minor*v_booking.nights;
  insert into public.owner_payables(workspace_id,booking_id,type,amount_minor)
  values(v_booking.workspace_id,v_booking.id,'stay_base',v_base);
  perform private.post_journal('booking',v_booking.id,'checkin','Guest check-in verified',
   jsonb_build_array(
    jsonb_build_object('account_code','2100','debit_minor',v_base,'booking_id',v_booking.id),
    jsonb_build_object('account_code','2200','credit_minor',v_base,'booking_id',v_booking.id,
     'workspace_id',v_booking.workspace_id)));
  update public.bookings set status='checked_in' where id=p_booking_id;
  insert into public.booking_events(booking_id,event_type,from_status,to_status,actor_scope,channel)
  values(p_booking_id,'stay.checked_in','confirmed','checked_in','system','system');
  return 'checked_in';
 elsif v_booking.status='checked_in' and v_booking.checkout_guest_at is not null
 and v_booking.checkout_host_at is not null then
  v_markup:=v_booking.markup_nightly_minor*v_booking.nights;
  if v_markup>0 then
   perform private.post_journal('booking',v_booking.id,'checkout','Stay completed',
    jsonb_build_array(
     jsonb_build_object('account_code','2100','debit_minor',v_markup,'booking_id',v_booking.id),
     jsonb_build_object('account_code','4100','credit_minor',v_markup,'booking_id',v_booking.id)));
  end if;
  update public.bookings set status='completed' where id=p_booking_id;
  insert into public.booking_events(booking_id,event_type,from_status,to_status,actor_scope,channel)
  values(p_booking_id,'stay.completed','checked_in','completed','system','system');
  return 'completed';
 end if;
 return v_booking.status;
end $$;
create or replace function public.guest_confirm_checkin(p_booking_id uuid) returns text
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_booking public.bookings%rowtype;
begin
 select * into v_booking from public.bookings where id=p_booking_id for update;
 if not found or v_booking.guest_user_id<>auth.uid() then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 if v_booking.status<>'confirmed' then raise exception 'INVALID_BOOKING_STATE' using errcode='P0001'; end if;
 if v_booking.checkin_guest_at is null then
  update public.bookings set checkin_guest_at=now() where id=p_booking_id;
  insert into public.booking_events(booking_id,event_type,actor_user_id,actor_scope,channel)
  values(p_booking_id,'stay.guest_checkin_confirmed',auth.uid(),'guest','app');
 end if;
 return private.advance_stay(p_booking_id);
end $$;
create or replace function public.partner_confirm_handover(p_booking_id uuid) returns text
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_booking public.bookings%rowtype;
begin
 select * into v_booking from public.bookings where id=p_booking_id for update;
 if not found then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 if not private.has_permission(v_booking.workspace_id,'stays.handover',v_booking.property_id) then
  raise exception 'PERMISSION_DENIED' using errcode='P0001'; end if;
 if v_booking.status<>'confirmed' then raise exception 'INVALID_BOOKING_STATE' using errcode='P0001'; end if;
 if v_booking.checkin_host_at is null then
  update public.bookings set checkin_host_at=now(),checkin_host_by=auth.uid() where id=p_booking_id;
  insert into public.booking_events(booking_id,event_type,actor_user_id,actor_scope,channel)
  values(p_booking_id,'stay.host_handover_confirmed',auth.uid(),'partner','app');
 end if;
 return private.advance_stay(p_booking_id);
end $$;
create or replace function public.guest_confirm_checkout(p_booking_id uuid) returns text
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_booking public.bookings%rowtype;
begin
 select * into v_booking from public.bookings where id=p_booking_id for update;
 if not found or v_booking.guest_user_id<>auth.uid() then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 if v_booking.status<>'checked_in' then raise exception 'INVALID_BOOKING_STATE' using errcode='P0001'; end if;
 if v_booking.checkout_guest_at is null then
  update public.bookings set checkout_guest_at=now() where id=p_booking_id;
  insert into public.booking_events(booking_id,event_type,actor_user_id,actor_scope,channel)
  values(p_booking_id,'stay.guest_checkout_confirmed',auth.uid(),'guest','app');
 end if;
 return private.advance_stay(p_booking_id);
end $$;
create or replace function public.partner_confirm_checkout(p_booking_id uuid,p_key_left_safe boolean)
returns text language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_booking public.bookings%rowtype;
begin
 select * into v_booking from public.bookings where id=p_booking_id for update;
 if not found then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 if not private.has_permission(v_booking.workspace_id,'stays.handover',v_booking.property_id) then
  raise exception 'PERMISSION_DENIED' using errcode='P0001'; end if;
 if v_booking.status<>'checked_in' then raise exception 'INVALID_BOOKING_STATE' using errcode='P0001'; end if;
 if v_booking.checkout_host_at is null then
  update public.bookings set checkout_host_at=now(),checkout_host_by=auth.uid(),key_left_safe=p_key_left_safe
  where id=p_booking_id;
 end if;
 return private.advance_stay(p_booking_id);
end $$;
create or replace function public.guest_submit_review(p_booking_id uuid,p_rating integer,p_comment text)
returns uuid language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_booking public.bookings%rowtype; v_id uuid; v_limits jsonb;
begin
 select * into v_booking from public.bookings where id=p_booking_id;
 if not found or v_booking.guest_user_id<>auth.uid() then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 if v_booking.status<>'completed' then raise exception 'REVIEW_NOT_ALLOWED' using errcode='P0001'; end if;
 select value into v_limits from public.platform_settings where key='review_comment_min_max';
 if p_rating not between 1 and 5 or
 (p_comment is not null and char_length(p_comment) not between
  coalesce((v_limits->>0)::integer,10) and coalesce((v_limits->>1)::integer,1000)) then
  raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
 insert into public.property_reviews(booking_id,property_id,guest_user_id,rating,comment)
 values(p_booking_id,v_booking.property_id,auth.uid(),p_rating,p_comment)
 returning id into v_id;
 return v_id;
end $$;
revoke all on function private.advance_stay(uuid) from public,anon,authenticated;
revoke all on function public.guest_confirm_checkin(uuid),public.partner_confirm_handover(uuid),
 public.guest_confirm_checkout(uuid),public.partner_confirm_checkout(uuid,boolean),
 public.guest_submit_review(uuid,integer,text) from public,anon;
grant execute on function public.guest_confirm_checkin(uuid),public.partner_confirm_handover(uuid),
 public.guest_confirm_checkout(uuid),public.partner_confirm_checkout(uuid,boolean),
 public.guest_submit_review(uuid,integer,text) to authenticated;
