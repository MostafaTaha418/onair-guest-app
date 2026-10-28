insert into public.ledger_accounts(code,name_ar,name_en,type,is_system) values
 ('1100','مستحقات كاشير','Kashier clearing','asset',true),
 ('1110','البنك','Bank','asset',true),
 ('1120','عهدة نقدية','Cash custody','asset',true),
 ('2100','التزامات للمستأجرين','Guest liabilities','liability',true),
 ('2200','ذمم الملاك','Owner payables','liability',true),
 ('4100','إيراد هامش أون إير','OnAir markup revenue','revenue',true),
 ('4200','إيراد الإلغاء','Cancellation revenue','revenue',true),
 ('5100','رسوم الدفع','Payment processing fees','expense',true);
create or replace function private.post_journal(p_source_type text,p_source_id uuid,p_source_event text,
 p_description text,p_lines jsonb) returns uuid
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_id uuid; v_line jsonb; v_debit bigint:=0; v_credit bigint:=0;
begin
 if jsonb_typeof(p_lines)<>'array' or jsonb_array_length(p_lines)<2 then
  raise exception 'JOURNAL_UNBALANCED' using errcode='P0001'; end if;
 select id into v_id from public.journal_entries where source_type=p_source_type
 and source_id=p_source_id and source_event=p_source_event;
 if found then return v_id; end if;
 for v_line in select * from jsonb_array_elements(p_lines) loop
  v_debit:=v_debit+coalesce((v_line->>'debit_minor')::bigint,0);
  v_credit:=v_credit+coalesce((v_line->>'credit_minor')::bigint,0);
 end loop;
 if v_debit=0 or v_debit<>v_credit then raise exception 'JOURNAL_UNBALANCED' using errcode='P0001'; end if;
 insert into public.journal_entries(entry_date,source_type,source_id,source_event,status,description)
 values((now() at time zone 'Africa/Cairo')::date,p_source_type,p_source_id,p_source_event,'draft',p_description)
 returning id into v_id;
 for v_line in select * from jsonb_array_elements(p_lines) loop
  insert into public.journal_lines(entry_id,account_id,debit_minor,credit_minor,workspace_id,booking_id,user_id)
  select v_id,a.id,coalesce((v_line->>'debit_minor')::bigint,0),
  coalesce((v_line->>'credit_minor')::bigint,0),(v_line->>'workspace_id')::uuid,
  (v_line->>'booking_id')::uuid,(v_line->>'user_id')::uuid
  from public.ledger_accounts a where a.code=v_line->>'account_code' and a.is_active;
  if not found then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 end loop;
 update public.journal_entries set status='posted',posted_at=now() where id=v_id;
 return v_id;
end $$;
create or replace function private.attach_payment_session(p_payment_id uuid,p_provider_order_id text,
 p_url text,p_expires_at timestamptz) returns void
language plpgsql security definer set search_path=public,private,pg_temp as $$
begin
 if session_user not in ('postgres','service_role') then raise exception 'PERMISSION_DENIED' using errcode='P0001'; end if;
 if p_provider_order_id is null or p_url !~ '^https://' or p_expires_at<=now() then
  raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
 update public.payments set provider_order_id=p_provider_order_id,payment_url=p_url,
 payment_url_expires_at=p_expires_at where id=p_payment_id and method='kashier'
 and status='pending' and (provider_order_id is null or provider_order_id=p_provider_order_id);
 if not found then raise exception 'INVALID_BOOKING_STATE' using errcode='P0001'; end if;
end $$;
create or replace function private.apply_kashier_event(p_event_id uuid) returns text
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_event private.provider_webhook_events%rowtype; v_payment public.payments%rowtype;
 v_booking public.bookings%rowtype; v_tx text; v_status text; v_amount bigint;
 v_refund uuid; v_journal uuid; v_deadline integer;
begin
 if session_user not in ('postgres','service_role') then raise exception 'PERMISSION_DENIED' using errcode='P0001'; end if;
 select * into v_event from private.provider_webhook_events where id=p_event_id for update;
 if not found then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 if v_event.processed_at is not null then return 'duplicate'; end if;
 if not v_event.signature_valid then raise exception 'PERMISSION_DENIED' using errcode='P0001'; end if;
 v_status:=v_event.payload->>'status'; v_tx:=v_event.payload->>'provider_transaction_id';
 v_amount:=(v_event.payload->>'amount_minor')::bigint;
 select * into v_payment from public.payments
 where provider_order_id=v_event.payload->>'provider_order_id' for update;
 if not found then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 if v_payment.amount_minor<>v_amount or v_payment.currency is distinct from v_event.payload->>'currency' then
  raise exception 'PAYMENT_AMOUNT_MISMATCH' using errcode='P0001'; end if;
 if v_status<>'SUCCESS' then
  if v_status in ('FAILURE','FAILED','CANCELLED','EXPIRED') then
   update public.payments set status='failed' where id=v_payment.id and status<>'succeeded';
  end if;
  update private.provider_webhook_events set processed_at=now() where id=p_event_id;
  return 'ignored';
 end if;
 if v_tx is null or v_tx='' then raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
 if v_payment.status='succeeded' then
  update private.provider_webhook_events set processed_at=now() where id=p_event_id;
  return 'duplicate'; end if;
 update public.payments set status='succeeded',provider_transaction_id=v_tx,
  verified_at=now(),verified_via='webhook' where id=v_payment.id;
 select * into v_booking from public.bookings where id=v_payment.booking_id for update;
 update public.bookings set paid_minor=paid_minor+v_amount where id=v_booking.id;
 if v_payment.purpose='initial' and v_booking.status in ('payment_pending','payment_verifying') then
  begin
   insert into public.property_calendar_locks(property_id,kind,booking_id,stay_range)
   values(v_booking.property_id,'hold',v_booking.id,daterange(v_booking.check_in,v_booking.check_out,'[)'));
   select (value #>> '{}')::integer into v_deadline from public.platform_settings where key='owner_response_hours';
   update public.bookings set status='awaiting_owner',owner_response_deadline=now()+make_interval(hours=>coalesce(v_deadline,24))
   where id=v_booking.id;
   insert into public.booking_events(booking_id,event_type,from_status,to_status,actor_scope,channel)
   values(v_booking.id,'booking.request_received',v_booking.status,'awaiting_owner','system','webhook');
  exception when exclusion_violation then
   update public.bookings set status='payment_conflict' where id=v_booking.id;
   insert into public.refunds(booking_id,payment_id,amount_minor,reason,method,status)
   values(v_booking.id,v_payment.id,v_amount,'payment_conflict','kashier',
    case when (select value='true'::jsonb from public.platform_settings where key='auto_approve_conflict_refunds')
      then 'approved' else 'requested' end)
   returning id into v_refund;
   insert into public.booking_events(booking_id,event_type,from_status,to_status,actor_scope,channel)
   values(v_booking.id,'booking.payment_conflict',v_booking.status,'payment_conflict','system','webhook');
  end;
 end if;
 v_journal:=private.post_journal('payment',v_payment.id,'succeeded','Verified Kashier payment',
  jsonb_build_array(
   jsonb_build_object('account_code','1100','debit_minor',v_amount,'booking_id',v_booking.id),
   jsonb_build_object('account_code','2100','credit_minor',v_amount,'booking_id',v_booking.id)));
 update private.provider_webhook_events set processed_at=now() where id=p_event_id;
 return 'processed';
end $$;
revoke all on function private.post_journal(text,uuid,text,text,jsonb),
 private.attach_payment_session(uuid,text,text,timestamptz),private.apply_kashier_event(uuid)
 from public,anon,authenticated;
grant execute on function private.attach_payment_session(uuid,text,text,timestamptz),
 private.apply_kashier_event(uuid) to service_role;
