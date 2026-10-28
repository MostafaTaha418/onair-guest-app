create or replace function public.guest_start_remaining_payment(p_booking_id uuid,p_idempotency_key text)
returns jsonb language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_booking public.bookings%rowtype; v_payment public.payments%rowtype; v_amount bigint;
begin
 if not private.current_profile_active() then raise exception 'ACCOUNT_SUSPENDED' using errcode='P0001'; end if;
 if length(p_idempotency_key)<8 or length(p_idempotency_key)>128 then
  raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
 select * into v_booking from public.bookings where id=p_booking_id for update;
 if not found or v_booking.guest_user_id<>auth.uid() then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 if v_booking.status<>'confirmed' then raise exception 'INVALID_BOOKING_STATE' using errcode='P0001'; end if;
 select * into v_payment from public.payments where booking_id=p_booking_id
 and purpose='remaining' and idempotency_key=p_idempotency_key;
 if found then return jsonb_build_object('booking_id',p_booking_id,'payment_id',v_payment.id,
  'amount_minor',v_payment.amount_minor,'currency',v_payment.currency,'status',v_payment.status); end if;
 if exists(select 1 from public.payments where booking_id=p_booking_id and purpose='remaining'
 and status in ('pending','verifying')) then raise exception 'CONFLICT' using errcode='P0001'; end if;
 v_amount:=v_booking.total_minor-v_booking.paid_minor;
 if v_amount<=0 then raise exception 'INVALID_BOOKING_STATE' using errcode='P0001'; end if;
 insert into public.payments(booking_id,purpose,method,amount_minor,idempotency_key)
 values(p_booking_id,'remaining','kashier',v_amount,p_idempotency_key) returning * into v_payment;
 return jsonb_build_object('booking_id',p_booking_id,'payment_id',v_payment.id,
  'amount_minor',v_amount,'currency','EGP','status',v_payment.status);
end $$;
revoke all on function public.guest_start_remaining_payment(uuid,text) from public,anon;
grant execute on function public.guest_start_remaining_payment(uuid,text) to authenticated;
