create or replace function public.guest_quote_booking(p_property_id uuid,p_check_in date,p_check_out date,
 p_guests integer,p_terms_hash text) returns jsonb
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_user uuid:=auth.uid(); v_nights integer; v_max_guests integer;
 v_price record; v_terms jsonb; v_deposit bigint; v_total bigint; v_pay_now bigint; v_id uuid;
 v_ttl integer; v_day date; v_check record;
begin
 if not private.current_profile_active() then raise exception 'ACCOUNT_SUSPENDED' using errcode='P0001'; end if;
 if not private.is_property_public(p_property_id) then raise exception 'PROPERTY_NOT_AVAILABLE' using errcode='P0001'; end if;
 if p_check_in<current_date or p_check_out<=p_check_in or p_check_out>p_check_in+90 then
  raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
 v_nights:=p_check_out-p_check_in;
 select v.max_guests into v_max_guests from public.properties p
 join public.property_versions v on v.id=p.published_version_id where p.id=p_property_id;
 if p_guests<1 or p_guests>v_max_guests then raise exception 'GUESTS_EXCEEDED' using errcode='P0001'; end if;
 if exists(select 1 from public.property_calendar_locks l where l.property_id=p_property_id
  and l.released_at is null and l.stay_range && daterange(p_check_in,p_check_out,'[)')) then
  raise exception 'DATES_UNAVAILABLE' using errcode='P0001'; end if;
 select * into v_price from private.effective_nightly_price(p_property_id,p_check_in);
 for v_day in select generate_series(p_check_in+1,p_check_out-1,interval '1 day')::date loop
  select * into v_check from private.effective_nightly_price(p_property_id,v_day);
  if v_check.base_minor<>v_price.base_minor or v_check.markup_minor<>v_price.markup_minor then
   raise exception 'POLICY_OUT_OF_BOUNDS' using errcode='P0001'; end if;
 end loop;
 v_terms:=private.resolve_booking_terms(p_property_id);
 if v_terms->>'terms_hash' is distinct from p_terms_hash then
  raise exception 'TERMS_CHANGED' using errcode='P0001'; end if;
 v_total:=v_price.nightly_final_minor*v_nights;
 v_deposit:=case v_terms->>'deposit_type' when 'full' then v_total
  when 'fixed' then least(v_total,coalesce((v_terms->>'deposit_fixed_minor')::bigint,0))
  else least(v_total,(v_total*coalesce((v_terms->>'deposit_percent_bp')::integer,0)+9999)/10000) end;
 v_pay_now:=v_deposit;
 select (value #>> '{}')::integer into v_ttl from public.platform_settings where key='quote_ttl_minutes';
 insert into public.booking_quotes(guest_user_id,property_id,check_in,check_out,guests_count,nights,
  base_nightly_minor,markup_nightly_minor,nightly_final_minor,total_minor,pay_now_minor,remaining_minor,
  policy,terms_hash,expires_at)
 values(v_user,p_property_id,p_check_in,p_check_out,p_guests,v_nights,v_price.base_minor,
  v_price.markup_minor,v_price.nightly_final_minor,v_total,v_pay_now,v_total-v_pay_now,
  v_terms,p_terms_hash,now()+make_interval(mins=>coalesce(v_ttl,15))) returning id into v_id;
 return jsonb_build_object('quote_id',v_id,'property_id',p_property_id,'check_in',p_check_in,
  'check_out',p_check_out,'nights',v_nights,'guests_count',p_guests,'nightly_minor',v_price.nightly_final_minor,
  'total_minor',v_total,'pay_now_minor',v_pay_now,'remaining_minor',v_total-v_pay_now,
  'currency','EGP','terms_hash',p_terms_hash,'expires_at',(select expires_at from public.booking_quotes where id=v_id));
end $$;
create or replace function public.guest_start_booking(p_quote_id uuid,p_terms_hash text,
 p_idempotency_key text) returns jsonb
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_quote public.booking_quotes%rowtype; v_booking public.bookings%rowtype;
 v_workspace uuid; v_version uuid; v_mode text; v_code text;
begin
 if not private.current_profile_active() then raise exception 'ACCOUNT_SUSPENDED' using errcode='P0001'; end if;
 if not exists(select 1 from public.profiles where id=auth.uid() and phone_verified_at is not null) then
  raise exception 'PHONE_NOT_VERIFIED' using errcode='P0001'; end if;
 if not exists(select 1 from auth.users where id=auth.uid() and email_confirmed_at is not null) then
  raise exception 'EMAIL_NOT_VERIFIED' using errcode='P0001'; end if;
 if length(p_idempotency_key)<8 or length(p_idempotency_key)>128 then
  raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
 select * into v_booking from public.bookings where guest_user_id=auth.uid() and idempotency_key=p_idempotency_key;
 if found then return jsonb_build_object('booking_id',v_booking.id,'payment_id',
  (select id from public.payments where booking_id=v_booking.id and purpose='initial' order by created_at limit 1),
  'status',v_booking.status); end if;
 select * into v_quote from public.booking_quotes where id=p_quote_id and guest_user_id=auth.uid() for update;
 if not found or v_quote.used_at is not null or v_quote.expires_at<=now() then
  raise exception 'QUOTE_EXPIRED' using errcode='P0001'; end if;
 if v_quote.terms_hash<>p_terms_hash or private.resolve_booking_terms(v_quote.property_id)->>'terms_hash'<>p_terms_hash then
  raise exception 'TERMS_CHANGED' using errcode='P0001'; end if;
 if not private.is_property_public(v_quote.property_id) then raise exception 'PROPERTY_NOT_AVAILABLE' using errcode='P0001'; end if;
 if exists(select 1 from public.property_calendar_locks l where l.property_id=v_quote.property_id
 and l.released_at is null and l.stay_range && daterange(v_quote.check_in,v_quote.check_out,'[)')) then
  raise exception 'DATES_UNAVAILABLE' using errcode='P0001'; end if;
 select p.workspace_id,p.published_version_id into v_workspace,v_version
 from public.properties p where p.id=v_quote.property_id;
 select markup_mode into v_mode from private.effective_nightly_price(v_quote.property_id,v_quote.check_in);
 v_code:='OA-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,7));
 insert into public.bookings(code,property_id,workspace_id,property_version_id,guest_user_id,
  check_in,check_out,nights,guests_count,base_nightly_minor,markup_nightly_minor,markup_mode,
  nightly_final_minor,total_minor,deposit_minor,pay_now_minor,policy_snapshot,terms_snapshot,
  terms_hash,terms_accepted_at,idempotency_key)
 values(v_code,v_quote.property_id,v_workspace,v_version,auth.uid(),v_quote.check_in,v_quote.check_out,
 v_quote.nights,v_quote.guests_count,v_quote.base_nightly_minor,v_quote.markup_nightly_minor,v_mode,
 v_quote.nightly_final_minor,v_quote.total_minor,v_quote.pay_now_minor,v_quote.pay_now_minor,
 v_quote.policy,v_quote.policy,p_terms_hash,now(),p_idempotency_key) returning * into v_booking;
 insert into public.payments(booking_id,purpose,method,amount_minor,idempotency_key)
 values(v_booking.id,'initial','kashier',v_quote.pay_now_minor,p_idempotency_key);
 update public.booking_quotes set used_at=now() where id=p_quote_id;
 insert into public.booking_events(booking_id,event_type,to_status,actor_user_id,actor_scope,channel)
 values(v_booking.id,'booking.started','payment_pending',auth.uid(),'guest','app');
 return jsonb_build_object('booking_id',v_booking.id,'payment_id',
  (select id from public.payments where booking_id=v_booking.id and purpose='initial'),
  'status',v_booking.status,'amount_minor',v_booking.pay_now_minor,'currency','EGP');
end $$;
create or replace function public.guest_get_booking(p_booking_id uuid) returns jsonb
language plpgsql stable security definer set search_path=public,private,pg_temp as $$
declare v_result jsonb;
begin
 if auth.uid() is null then raise exception 'UNAUTHENTICATED' using errcode='P0001'; end if;
 select jsonb_build_object('id',b.id,'code',b.code,'property_id',b.property_id,
 'title',v.title,'check_in',b.check_in,'check_out',b.check_out,'nights',b.nights,
 'guests_count',b.guests_count,'status',b.status,'nightly_minor',b.nightly_final_minor,
 'total_minor',b.total_minor,'pay_now_minor',b.pay_now_minor,'paid_minor',b.paid_minor,
 'currency',b.currency,'owner_response_deadline',b.owner_response_deadline,
 'access_instructions',case when b.status in ('confirmed','checked_in','completed') then v.access_instructions else null end,
 'events',coalesce((select jsonb_agg(jsonb_build_object('event_type',e.event_type,'to_status',e.to_status,
 'created_at',e.created_at,'note',e.note) order by e.created_at) from public.booking_events e
 where e.booking_id=b.id and e.visibility='all'),'[]'::jsonb)) into v_result
 from public.bookings b join public.property_versions v on v.id=b.property_version_id
 where b.id=p_booking_id and b.guest_user_id=auth.uid();
 if v_result is null then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 return v_result;
end $$;
create or replace function public.guest_list_bookings(p_tab text default null,p_cursor timestamptz default null)
returns jsonb language plpgsql stable security definer set search_path=public,private,pg_temp as $$
declare v_result jsonb;
begin
 if auth.uid() is null then raise exception 'UNAUTHENTICATED' using errcode='P0001'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'code',code,'property_id',property_id,
 'check_in',check_in,'check_out',check_out,'status',status,'total_minor',total_minor,
 'paid_minor',paid_minor,'currency',currency,'created_at',created_at)
 order by created_at desc),'[]'::jsonb) into v_result from (
 select * from public.bookings where guest_user_id=auth.uid() and
 (p_tab is null or (p_tab='upcoming' and status in ('awaiting_owner','confirmed','checked_in')) or
 (p_tab='past' and status in ('completed','cancelled','rejected','expired','no_show','abandoned','payment_conflict')) or
 (p_tab='pending' and status in ('payment_pending','payment_verifying')))
 and (p_cursor is null or created_at<p_cursor) order by created_at desc limit 30) q;
 return v_result;
end $$;
revoke all on function public.guest_quote_booking(uuid,date,date,integer,text),
 public.guest_start_booking(uuid,text,text),public.guest_get_booking(uuid),
 public.guest_list_bookings(text,timestamptz) from public,anon;
grant execute on function public.guest_quote_booking(uuid,date,date,integer,text),
 public.guest_start_booking(uuid,text,text),public.guest_get_booking(uuid),
 public.guest_list_bookings(text,timestamptz) to authenticated;
