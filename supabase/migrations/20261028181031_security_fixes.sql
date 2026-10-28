revoke all on function public.rls_auto_enable() from public,anon,authenticated;
create or replace function private.staff_session_verified() returns boolean
language sql stable security definer set search_path = public, private, pg_temp as $$
  select exists(select 1 from private.otp_challenges c
    where c.purpose='staff_login' and c.recipient_user_id=(select auth.uid())
      and c.session_id=(select auth.jwt()->>'session_id')
      and c.session_id is not null and c.consumed_at is not null
      and c.consumed_at<=c.expires_at)
$$;
create or replace function private.can_read_booking_event(p_booking_id uuid,p_visibility text) returns boolean
language sql stable security definer set search_path=public,private,pg_temp as $$
 select exists(select 1 from public.bookings b where b.id=p_booking_id and
  ((b.guest_user_id=(select auth.uid()) and p_visibility='all') or
   (p_visibility<>'platform' and private.has_permission(b.workspace_id,'bookings.view',b.property_id)) or
   private.has_platform_permission('bookings.view_all')))
$$;
grant execute on function private.can_read_booking_event(uuid,text) to authenticated;
drop policy booking_events_read on public.booking_events;
create policy booking_events_read on public.booking_events for select to authenticated
 using(private.can_read_booking_event(booking_id,visibility));
create or replace function private.can_read_offer(p_booking_id uuid) returns boolean
language sql stable security definer set search_path=public,private,pg_temp as $$
 select exists(select 1 from public.bookings where id=p_booking_id and guest_user_id=(select auth.uid()))
$$;
create or replace function private.can_read_damage(p_booking_id uuid) returns boolean
language sql stable security definer set search_path=public,private,pg_temp as $$
 select exists(select 1 from public.bookings where id=p_booking_id and guest_user_id=(select auth.uid()))
$$;
grant execute on function private.can_read_offer(uuid),private.can_read_damage(uuid) to authenticated;
drop policy offers_read on public.replacement_offers;
create policy offers_read on public.replacement_offers for select to authenticated
 using(private.can_read_offer(booking_id) or private.has_platform_permission('bookings.manage'));
drop policy damage_read on public.damage_claims;
create policy damage_read on public.damage_claims for select to authenticated
 using(private.can_read_damage(booking_id) or private.has_permission(workspace_id,'damage.manage') or private.has_platform_permission('support.handle'));
create or replace view public.trial_balance_v with(security_invoker=true) as
 select a.id,a.code,a.name_ar,a.name_en,a.type,
 coalesce(sum(l.debit_minor) filter(where e.status='posted'),0)::bigint debit_minor,
 coalesce(sum(l.credit_minor) filter(where e.status='posted'),0)::bigint credit_minor
 from public.ledger_accounts a left join public.journal_lines l on l.account_id=a.id
 left join public.journal_entries e on e.id=l.entry_id
 group by a.id;
