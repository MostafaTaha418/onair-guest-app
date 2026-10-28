begin;

insert into auth.users(id,email,raw_user_meta_data)
values('11111111-1111-4111-8111-111111111111','guest-test@example.invalid',
 '{"full_name":"Guest Test","phone_e164":"+201011111111","phone_has_whatsapp":true,"accepted_terms_version":"1","locale":"ar"}');
update auth.users set email_confirmed_at=now() where id='11111111-1111-4111-8111-111111111111';
insert into auth.users(id,email,raw_user_meta_data)
values('55555555-5555-4555-8555-555555555555','owner-test@example.invalid',
 '{"full_name":"Owner Test","phone_e164":"+201022222222","phone_has_whatsapp":true,"accepted_terms_version":"1","locale":"ar"}');
update auth.users set email_confirmed_at=now() where id='55555555-5555-4555-8555-555555555555';
insert into public.workspaces(id,kind,display_name,verification_status)
values('22222222-2222-4222-8222-222222222222','individual_owner','Test Owner','approved');
update public.workspaces set principal_user_id='55555555-5555-4555-8555-555555555555'
where id='22222222-2222-4222-8222-222222222222';
insert into public.workspace_members(workspace_id,user_id,is_principal,role_preset_keys)
values('22222222-2222-4222-8222-222222222222','55555555-5555-4555-8555-555555555555',true,array['partner_owner']);
insert into public.properties(id,workspace_id,status,base_nightly_price_minor)
values('33333333-3333-4333-8333-333333333333','22222222-2222-4222-8222-222222222222',
 'published',100000);
insert into public.property_versions(id,property_id,version_no,status,title,max_guests)
values('44444444-4444-4444-8444-444444444444','33333333-3333-4333-8333-333333333333',
 1,'approved','Test apartment',4);
update public.properties set published_version_id='44444444-4444-4444-8444-444444444444'
where id='33333333-3333-4333-8333-333333333333';
select set_config('test.terms_hash',private.resolve_booking_terms('33333333-3333-4333-8333-333333333333')->>'terms_hash',true);

set local role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
select set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',true);

do $$
declare v_quote jsonb; v_booking jsonb; v_detail jsonb;
begin
 v_quote:=public.guest_quote_booking('33333333-3333-4333-8333-333333333333',
 current_date+7,current_date+9,2,current_setting('test.terms_hash'));
 if (v_quote->>'total_minor')::bigint<>230000 then raise exception 'Unexpected price: %',v_quote; end if;
 v_booking:=public.guest_start_booking((v_quote->>'quote_id')::uuid,current_setting('test.terms_hash'),
 'test-idempotency-key-1');
 if v_booking->>'status'<>'payment_pending' then raise exception 'Booking not pending: %',v_booking; end if;
 v_detail:=public.guest_get_booking((v_booking->>'booking_id')::uuid);
 if v_detail ? 'base_nightly_minor' or v_detail ? 'markup_nightly_minor' then
  raise exception 'Guest price internals exposed'; end if;
 if v_detail->>'status'<>'payment_pending' then raise exception 'Guest detail mismatch'; end if;
 perform set_config('test.booking_id',v_booking->>'booking_id',true);
 perform set_config('test.payment_id',v_booking->>'payment_id',true);
end $$;

reset role;
select private.attach_payment_session(current_setting('test.payment_id')::uuid,'test-order-1',
 'https://example.invalid/pay',now()+interval '15 minutes');
insert into private.provider_webhook_events(provider,provider_event_id,event_type,payload,signature_valid)
values('kashier','test-event-1','payment.success',jsonb_build_object(
 'provider_order_id','test-order-1','provider_transaction_id','test-tx-1',
 'amount_minor',69000,'currency','EGP','status','SUCCESS'),true);
do $$
declare v_result text;
begin
 v_result:=private.apply_kashier_event((select id from private.provider_webhook_events
  where provider_event_id='test-event-1'));
 if v_result<>'processed' then raise exception 'Webhook not processed: %',v_result; end if;
 if not exists(select 1 from public.bookings where id=current_setting('test.booking_id')::uuid
  and status='awaiting_owner' and paid_minor=69000) then raise exception 'Payment state wrong'; end if;
 if not exists(select 1 from public.property_calendar_locks
  where booking_id=current_setting('test.booking_id')::uuid and kind='hold' and released_at is null)
  then raise exception 'Hold missing'; end if;
 if (select count(*) from public.notifications where entity_id=current_setting('test.booking_id')::uuid
  and type_key='booking.request_received')<>2 then raise exception 'Wrong notification recipients'; end if;
end $$;
set local role authenticated;
select set_config('request.jwt.claim.sub','55555555-5555-4555-8555-555555555555',true);
select set_config('request.jwt.claims','{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated"}',true);
do $$
declare v_response jsonb; v_detail jsonb;
begin
 v_detail:=public.partner_get_booking(current_setting('test.booking_id')::uuid);
 if v_detail ? 'markup_nightly_minor' or v_detail ? 'email' or v_detail ? 'phone_e164'
 then raise exception 'Partner detail leaked internals'; end if;
 v_response:=public.partner_respond_booking(current_setting('test.booking_id')::uuid,'accept',null,'test-response-key');
 if v_response->>'status'<>'confirmed' then raise exception 'Partner response failed: %',v_response; end if;
end $$;
reset role;
insert into public.payments(booking_id,purpose,method,status,amount_minor,idempotency_key,verified_at,verified_via)
values(current_setting('test.booking_id')::uuid,'remaining','kashier','succeeded',161000,
 'test-remaining-payment',now(),'webhook');
update public.bookings set paid_minor=230000 where id=current_setting('test.booking_id')::uuid;
do $$ begin
 if not exists(select 1 from public.property_calendar_locks where booking_id=current_setting('test.booking_id')::uuid
 and kind='booking' and released_at is null) then raise exception 'Booking lock missing'; end if;
 if not exists(select 1 from public.notifications where entity_id=current_setting('test.booking_id')::uuid
 and type_key='booking.confirmed' and user_id='11111111-1111-4111-8111-111111111111')
 then raise exception 'Guest confirmation notification missing'; end if;
end $$;
set local role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
select set_config('request.jwt.claims','{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',true);
select public.guest_confirm_checkin(current_setting('test.booking_id')::uuid);
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','55555555-5555-4555-8555-555555555555',true);
select set_config('request.jwt.claims','{"sub":"55555555-5555-4555-8555-555555555555","role":"authenticated"}',true);
do $$ begin
 if public.partner_confirm_handover(current_setting('test.booking_id')::uuid)<>'checked_in'
 then raise exception 'Check-in failed'; end if;
end $$;
reset role;
do $$ begin
 if not exists(select 1 from public.owner_payables where booking_id=current_setting('test.booking_id')::uuid
 and amount_minor=200000) then raise exception 'Owner payable missing'; end if;
 if not exists(select 1 from public.journal_entries where source_type='booking'
 and source_id=current_setting('test.booking_id')::uuid and source_event='checkin' and status='posted')
 then raise exception 'Check-in journal missing'; end if;
end $$;
rollback;
