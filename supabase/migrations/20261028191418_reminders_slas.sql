insert into public.notification_types(key,category,recipients,channels,priority,is_mandatory,entity_type) values
 ('payment.remaining_due','payment','[{"audience":"guest","rule":"booking_guest"}]','{"guest":["in_app","push","email"]}','high',true,'booking'),
 ('stay.checkin_reminder','stay','[{"audience":"guest","rule":"booking_guest"},{"audience":"partner","perm":"stays.handover"}]','{"guest":["in_app","push"],"partner":["in_app","push"]}','normal',false,'booking'),
 ('stay.checkout_reminder','stay','[{"audience":"guest","rule":"booking_guest"},{"audience":"partner","perm":"stays.handover"}]','{"guest":["in_app","push"],"partner":["in_app","push"]}','normal',false,'booking'),
 ('support.sla_breached','support','[{"audience":"platform","perm":"support.assign"}]','{"platform":["in_app","web_push"]}','critical',false,'support_case'),
 ('refund.overdue','refund','[{"audience":"platform","perm":"refunds.approve"},{"audience":"platform","perm":"support.handle"}]','{"platform":["in_app","web_push"]}','critical',false,'refund');
create or replace function private.run_stay_and_payment_reminders() returns integer
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_booking public.bookings%rowtype; v_offset integer; v_type text; v_count integer:=0;
begin
 for v_type,v_offset in
  select 'payment.remaining_due',jsonb_array_elements_text(value)::integer from public.platform_settings where key='remaining_payment_reminder_hours'
  union all
  select 'stay.checkin_reminder',jsonb_array_elements_text(value)::integer from public.platform_settings where key='stay_reminder_hours'
  union all
  select 'stay.checkout_reminder',jsonb_array_elements_text(value)::integer from public.platform_settings where key='stay_reminder_hours'
 loop
  for v_booking in select * from public.bookings b where b.status in ('confirmed','checked_in')
   and ((case when v_type='stay.checkout_reminder' then b.check_out else b.check_in end)::timestamp at time zone 'Africa/Cairo')
    between now() and now()+make_interval(hours=>v_offset)
   and (v_type<>'payment.remaining_due' or b.paid_minor<b.total_minor)
   and not exists(select 1 from public.booking_events e where e.booking_id=b.id and e.event_type=v_type
    and (e.data->>'offset_hours')::integer=v_offset)
  for update skip locked loop
   insert into public.booking_events(booking_id,event_type,actor_scope,channel,data)
   values(v_booking.id,v_type,'system','system',jsonb_build_object('offset_hours',v_offset));
   v_count:=v_count+1;
  end loop;
 end loop;
 return v_count;
end $$;
create or replace function private.check_slas() returns integer
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_case public.support_cases%rowtype; v_refund public.refunds%rowtype; v_count integer:=0;
begin
 for v_case in select * from public.support_cases c where c.sla_due_at<now()
 and c.status not in ('resolved','closed') and not exists(select 1 from public.notifications n
 where n.type_key='support.sla_breached' and n.entity_id=c.id)
 for update skip locked loop
  v_count:=v_count+private.notify('support.sla_breached','support_case',v_case.id,v_case.workspace_id,v_case.property_id);
 end loop;
 for v_refund in select * from public.refunds r where r.due_at<now()
 and r.status not in ('verified','cancelled') and not exists(select 1 from public.notifications n
 where n.type_key='refund.overdue' and n.entity_id=r.id)
 for update skip locked loop
  v_count:=v_count+private.notify('refund.overdue','refund',v_refund.id);
 end loop;
 return v_count;
end $$;
revoke all on function private.run_stay_and_payment_reminders(),private.check_slas() from public,anon,authenticated;
select cron.schedule('onair-stay-payment-reminders','0 * * * *','select private.run_stay_and_payment_reminders()');
select cron.schedule('onair-check-slas','*/15 * * * *','select private.check_slas()');
