insert into public.notification_types(key,category,recipients,channels,priority,is_mandatory,entity_type)
values('booking.response_reminder','booking',
 '[{"audience":"partner","perm":"bookings.respond"},{"audience":"platform","perm":"support.handle"}]',
 '{"partner":["in_app","push","email"],"platform":["in_app","web_push"]}',
 'critical',false,'booking');
create or replace function private.expire_owner_requests() returns integer
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_booking public.bookings%rowtype; v_count integer:=0;
begin
 for v_booking in select * from public.bookings where status='awaiting_owner'
 and owner_response_deadline<=now() for update skip locked loop
  update public.bookings set status='expired' where id=v_booking.id;
  update public.property_calendar_locks set released_at=now(),released_reason='owner_timeout'
  where booking_id=v_booking.id and kind='hold' and released_at is null;
  if v_booking.paid_minor>0 then
   insert into public.refunds(booking_id,payment_id,amount_minor,reason,method)
   values(v_booking.id,(select id from public.payments where booking_id=v_booking.id and status='succeeded'
    order by created_at limit 1),v_booking.paid_minor,'owner_timeout','kashier');
  end if;
  insert into public.booking_events(booking_id,event_type,from_status,to_status,actor_scope,channel)
  values(v_booking.id,'booking.expired','awaiting_owner','expired','system','system');
  v_count:=v_count+1;
 end loop;
 return v_count;
end $$;
create or replace function private.abandon_stale_payments() returns integer
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_minutes integer; v_count integer;
begin
 select (value #>> '{}')::integer into v_minutes from public.platform_settings
 where key='payment_pending_abandon_minutes';
 update public.bookings b set status='abandoned' where b.status='payment_pending'
 and b.created_at<now()-make_interval(mins=>coalesce(v_minutes,30))
 and not exists(select 1 from public.payments p where p.booking_id=b.id and p.status='succeeded');
 get diagnostics v_count=row_count;
 update public.payments p set status='expired' from public.bookings b
 where p.booking_id=b.id and b.status='abandoned' and p.status='pending';
 return v_count;
end $$;
create or replace function private.send_owner_response_reminders() returns integer
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_booking public.bookings%rowtype; v_offset integer; v_count integer:=0;
begin
 for v_offset in select jsonb_array_elements_text(value)::integer from public.platform_settings
 where key='owner_response_reminder_minutes' loop
  for v_booking in select * from public.bookings where status='awaiting_owner'
   and owner_response_deadline>now() and owner_response_deadline<=now()+make_interval(mins=>v_offset)
   and not exists(select 1 from public.booking_events e where e.booking_id=bookings.id
    and e.event_type='booking.response_reminder' and (e.data->>'offset_minutes')::integer=v_offset)
  for update skip locked loop
   insert into public.booking_events(booking_id,event_type,actor_scope,channel,data)
   values(v_booking.id,'booking.response_reminder','system','system',
    jsonb_build_object('offset_minutes',v_offset));
   v_count:=v_count+1;
  end loop;
 end loop;
 return v_count;
end $$;
create or replace function private.cleanup_expired() returns jsonb
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_quotes integer; v_challenges integer;
begin
 delete from public.booking_quotes where expires_at<now()-interval '1 day';
 get diagnostics v_quotes=row_count;
 delete from private.otp_challenges where expires_at<now()-interval '30 days';
 get diagnostics v_challenges=row_count;
 return jsonb_build_object('quotes',v_quotes,'challenges',v_challenges);
end $$;
revoke all on function private.expire_owner_requests(),private.abandon_stale_payments(),
 private.send_owner_response_reminders(),private.cleanup_expired() from public,anon,authenticated;
select cron.schedule('onair-expire-owner-requests','* * * * *','select private.expire_owner_requests()');
select cron.schedule('onair-abandon-stale-payments','*/5 * * * *','select private.abandon_stale_payments()');
select cron.schedule('onair-owner-response-reminders','*/5 * * * *','select private.send_owner_response_reminders()');
select cron.schedule('onair-cleanup-expired','15 3 * * *','select private.cleanup_expired()');
