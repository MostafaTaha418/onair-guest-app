create or replace function private.respond_booking(p_booking_id uuid,p_decision text,p_reason text,
 p_channel text,p_phone_decision jsonb default null) returns jsonb
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_booking public.bookings%rowtype; v_status text;
begin
 if p_decision not in ('accept','reject') then raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
 select * into v_booking from public.bookings where id=p_booking_id for update;
 if not found then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 if v_booking.status<>'awaiting_owner' or v_booking.owner_response_deadline<=now() then
  raise exception 'BOOKING_RESPONSE_EXPIRED' using errcode='P0001'; end if;
 v_status:=case when p_decision='accept' then 'confirmed' else 'rejected' end;
 if p_decision='accept' then
  update public.property_calendar_locks set kind='booking'
  where booking_id=p_booking_id and kind='hold' and released_at is null;
  if not found then raise exception 'DATES_LOCKED' using errcode='P0001'; end if;
  update public.bookings set status='confirmed',responded_at=now(),responded_by=auth.uid(),
  response_channel=p_channel,phone_decision=p_phone_decision,confirmed_at=now()
  where id=p_booking_id;
 else
  update public.property_calendar_locks set released_at=now(),released_reason='owner_rejected'
  where booking_id=p_booking_id and kind='hold' and released_at is null;
  update public.bookings set status='rejected',responded_at=now(),responded_by=auth.uid(),
  response_channel=p_channel,phone_decision=p_phone_decision,rejection_reason=p_reason where id=p_booking_id;
  if v_booking.paid_minor>0 then
   insert into public.refunds(booking_id,payment_id,amount_minor,reason,method,requested_by)
   values(p_booking_id,(select id from public.payments where booking_id=p_booking_id and status='succeeded'
    order by created_at limit 1),v_booking.paid_minor,'owner_rejected','kashier',auth.uid());
  end if;
 end if;
 insert into public.booking_events(booking_id,event_type,from_status,to_status,actor_user_id,
  actor_scope,channel,note)
 values(p_booking_id,'booking.'||v_status,'awaiting_owner',v_status,auth.uid(),
  case when p_channel='phone' then 'platform' else 'partner' end,p_channel,p_reason);
 insert into public.audit_log(actor_user_id,actor_scope,workspace_id,action,entity_type,entity_id,reason,
  before,after)
 values(auth.uid(),case when p_channel='phone' then 'platform' else 'partner' end,
  v_booking.workspace_id,'booking.'||v_status,'booking',p_booking_id,p_reason,
  jsonb_build_object('status','awaiting_owner'),jsonb_build_object('status',v_status));
 return jsonb_build_object('booking_id',p_booking_id,'status',v_status);
end $$;
create or replace function public.partner_respond_booking(p_booking_id uuid,p_decision text,
 p_reason text default null,p_idempotency_key text default null) returns jsonb
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_workspace uuid; v_property uuid;
begin
 select workspace_id,property_id into v_workspace,v_property from public.bookings where id=p_booking_id;
 if not found then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 if not private.has_permission(v_workspace,'bookings.respond',v_property) then
  raise exception 'PERMISSION_DENIED' using errcode='P0001'; end if;
 return private.respond_booking(p_booking_id,p_decision,p_reason,'app');
end $$;
create or replace function public.admin_record_owner_phone_decision(p_booking_id uuid,p_decision text,
 p_call_at timestamptz,p_summary text) returns jsonb
language plpgsql security definer set search_path=public,private,pg_temp as $$
begin
 if not private.has_platform_permission('bookings.record_phone_decision') then
  raise exception 'STAFF_LOGIN_CODE_REQUIRED' using errcode='P0001'; end if;
 if p_call_at>now() or p_call_at<now()-interval '7 days' or length(trim(p_summary))<10 then
  raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
 return private.respond_booking(p_booking_id,p_decision,p_summary,'phone',
 jsonb_build_object('call_at',p_call_at,'summary',p_summary,'staff_user_id',auth.uid()));
end $$;
create or replace function public.partner_get_booking(p_booking_id uuid) returns jsonb
language plpgsql stable security definer set search_path=public,private,pg_temp as $$
declare v_workspace uuid; v_property uuid; v_result jsonb;
begin
 select workspace_id,property_id into v_workspace,v_property from public.bookings where id=p_booking_id;
 if not found then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 if not private.has_permission(v_workspace,'bookings.view',v_property) then
  raise exception 'PERMISSION_DENIED' using errcode='P0001'; end if;
 select jsonb_build_object('id',b.id,'code',b.code,'property_id',b.property_id,
 'guest_name',p.full_name,'guests_count',b.guests_count,'check_in',b.check_in,'check_out',b.check_out,
 'status',b.status,'base_total_minor',b.base_nightly_minor*b.nights,'currency',b.currency,
 'owner_response_deadline',b.owner_response_deadline,'created_at',b.created_at)
 into v_result from public.bookings b join public.profiles p on p.id=b.guest_user_id where b.id=p_booking_id;
 return v_result;
end $$;
create or replace function public.partner_list_bookings(p_workspace_id uuid,p_tab text default null,
 p_cursor timestamptz default null) returns jsonb
language plpgsql stable security definer set search_path=public,private,pg_temp as $$
declare v_result jsonb;
begin
 if not private.has_permission(p_workspace_id,'bookings.view') then
  raise exception 'PERMISSION_DENIED' using errcode='P0001'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',b.id,'code',b.code,
 'property_id',b.property_id,'guest_name',p.full_name,'guests_count',b.guests_count,
 'check_in',b.check_in,'check_out',b.check_out,'status',b.status,
 'base_total_minor',b.base_nightly_minor*b.nights,'created_at',b.created_at)
 order by b.created_at desc),'[]'::jsonb) into v_result
 from (select * from public.bookings where workspace_id=p_workspace_id
 and (p_tab is null or status=p_tab) and (p_cursor is null or created_at<p_cursor)
 order by created_at desc limit 30) b join public.profiles p on p.id=b.guest_user_id
 where private.has_permission(p_workspace_id,'bookings.view',b.property_id);
 return v_result;
end $$;
revoke all on function private.respond_booking(uuid,text,text,text,jsonb) from public,anon,authenticated;
revoke all on function public.partner_respond_booking(uuid,text,text,text),
 public.admin_record_owner_phone_decision(uuid,text,timestamptz,text),
 public.partner_get_booking(uuid),public.partner_list_bookings(uuid,text,timestamptz)
 from public,anon;
grant execute on function public.partner_respond_booking(uuid,text,text,text),
 public.admin_record_owner_phone_decision(uuid,text,timestamptz,text),
 public.partner_get_booking(uuid),public.partner_list_bookings(uuid,text,timestamptz)
 to authenticated;
