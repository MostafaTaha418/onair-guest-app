create table public.booking_quotes (
 id uuid primary key default gen_random_uuid(), guest_user_id uuid not null references public.profiles(id),
 property_id uuid not null references public.properties(id), check_in date not null, check_out date not null,
 guests_count integer not null check(guests_count>0), nights integer not null check(nights>0),
 base_nightly_minor bigint not null check(base_nightly_minor>=0), markup_nightly_minor bigint not null check(markup_nightly_minor>=0),
 nightly_final_minor bigint not null check(nightly_final_minor>=0), total_minor bigint not null check(total_minor>=0),
 pay_now_minor bigint not null check(pay_now_minor>=0), remaining_minor bigint not null check(remaining_minor>=0),
 policy jsonb not null, terms_hash text not null, expires_at timestamptz not null, used_at timestamptz,
 created_at timestamptz not null default now(), check(check_out>check_in)
);
create table public.bookings (
 id uuid primary key default gen_random_uuid(), code text not null unique,
 property_id uuid not null references public.properties(id), workspace_id uuid not null references public.workspaces(id),
 property_version_id uuid not null references public.property_versions(id), guest_user_id uuid not null references public.profiles(id),
 check_in date not null, check_out date not null, nights integer not null check(nights>0), guests_count integer not null check(guests_count>0),
 status text not null default 'payment_pending' check(status in ('payment_pending','payment_verifying','awaiting_owner','payment_conflict','confirmed','checked_in','completed','rejected','expired','cancelled','no_show','abandoned')),
 base_nightly_minor bigint not null check(base_nightly_minor>=0), markup_nightly_minor bigint not null check(markup_nightly_minor>=0),
 markup_mode text not null check(markup_mode in ('fixed','percent')),
 nightly_final_minor bigint not null check(nightly_final_minor>=0), total_minor bigint not null check(total_minor>=0),
 deposit_minor bigint not null check(deposit_minor>=0), pay_now_minor bigint not null check(pay_now_minor>=0),
 currency text not null default 'EGP' check(currency='EGP'),
 policy_snapshot jsonb not null, terms_snapshot jsonb not null, terms_hash text not null, terms_accepted_at timestamptz not null,
 paid_minor bigint not null default 0 check(paid_minor>=0), idempotency_key text not null,
 owner_response_deadline timestamptz, responded_at timestamptz, responded_by uuid references public.profiles(id),
 response_channel text check(response_channel in ('app','phone_via_support')),
 phone_decision jsonb, rejection_reason text, confirmed_at timestamptz,
 cancelled_at timestamptz, cancelled_by_scope text, cancellation_reason text,
 checkin_host_at timestamptz, checkin_host_by uuid references public.profiles(id), checkin_guest_at timestamptz,
 checkout_guest_at timestamptz, checkout_host_at timestamptz, checkout_host_by uuid references public.profiles(id),
 key_left_safe boolean, stay_exception jsonb, no_show_at timestamptz, reopened_at timestamptz,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(guest_user_id,idempotency_key), check(check_out>check_in)
);
create index bookings_guest_idx on public.bookings(guest_user_id,created_at desc);
create index bookings_workspace_idx on public.bookings(workspace_id,status,created_at desc);
create index bookings_property_idx on public.bookings(property_id,check_in,check_out);
alter table public.property_calendar_locks add constraint locks_booking_fk foreign key(booking_id) references public.bookings(id);
create table public.booking_events (
 id uuid primary key default gen_random_uuid(), booking_id uuid not null references public.bookings(id),
 event_type text not null, from_status text, to_status text, actor_user_id uuid references public.profiles(id),
 actor_scope text not null check(actor_scope in ('guest','partner','platform','system')),
 channel text not null check(channel in ('app','phone','system','webhook')),
 note text, data jsonb not null default '{}', visibility text not null default 'all' check(visibility in ('all','partner_platform','platform')),
 created_at timestamptz not null default now()
);
create index booking_events_booking_idx on public.booking_events(booking_id,created_at);
create table public.replacement_offers (
 id uuid primary key default gen_random_uuid(), booking_id uuid not null references public.bookings(id),
 offered_property_id uuid not null references public.properties(id), check_in date not null, check_out date not null,
 price_difference_minor bigint not null, note text,
 status text not null default 'pending' check(status in ('pending','accepted','declined','expired','withdrawn')),
 created_by uuid not null references public.profiles(id), expires_at timestamptz not null,
 responded_at timestamptz, new_booking_id uuid references public.bookings(id), created_at timestamptz not null default now(),
 check(check_out>check_in)
);
create table public.damage_claims (
 id uuid primary key default gen_random_uuid(), booking_id uuid not null references public.bookings(id),
 workspace_id uuid not null references public.workspaces(id), opened_by uuid not null references public.profiles(id),
 description text not null, amount_minor bigint not null check(amount_minor>=0),
 status text not null default 'open' check(status in ('open','guest_accepted','guest_disputed','in_mediation','resolved','withdrawn')),
 guest_response_note text, guest_responded_at timestamptz, resolution jsonb,
 resolved_by uuid references public.profiles(id), support_case_id uuid,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.property_reviews (
 id uuid primary key default gen_random_uuid(), booking_id uuid not null unique references public.bookings(id),
 property_id uuid not null references public.properties(id), guest_user_id uuid not null references public.profiles(id),
 rating smallint not null check(rating between 1 and 5), comment text,
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 moderated_by uuid references public.profiles(id), moderated_at timestamptz, rejection_reason text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.favorites (
 user_id uuid not null references public.profiles(id), property_id uuid not null references public.properties(id),
 created_at timestamptz not null default now(), primary key(user_id,property_id)
);
alter table public.booking_quotes enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_events enable row level security;
alter table public.replacement_offers enable row level security;
alter table public.damage_claims enable row level security;
alter table public.property_reviews enable row level security;
alter table public.favorites enable row level security;
create policy quotes_self_read on public.booking_quotes for select to authenticated using(guest_user_id=(select auth.uid()));
create policy bookings_platform_read on public.bookings for select to authenticated using(private.has_platform_permission('bookings.view_all'));
create policy booking_events_read on public.booking_events for select to authenticated using(
 exists(select 1 from public.bookings b where b.id=booking_id and
 ((b.guest_user_id=(select auth.uid()) and visibility='all') or
  (visibility<>'platform' and private.has_permission(b.workspace_id,'bookings.view',b.property_id)) or
  private.has_platform_permission('bookings.view_all'))));
create policy offers_read on public.replacement_offers for select to authenticated using(
 exists(select 1 from public.bookings b where b.id=booking_id and b.guest_user_id=(select auth.uid())) or private.has_platform_permission('bookings.manage'));
create policy damage_read on public.damage_claims for select to authenticated using(
 exists(select 1 from public.bookings b where b.id=booking_id and b.guest_user_id=(select auth.uid())) or
 private.has_permission(workspace_id,'damage.manage') or private.has_platform_permission('support.handle'));
create policy reviews_read on public.property_reviews for select to authenticated using(
 guest_user_id=(select auth.uid()) or private.has_platform_permission('reviews.moderate') or
 exists(select 1 from public.properties p where p.id=property_id and private.has_permission(p.workspace_id,'properties.view',p.id)));
create policy favorites_read on public.favorites for select to authenticated using(user_id=(select auth.uid()));
create policy favorites_insert on public.favorites for insert to authenticated with check(user_id=(select auth.uid()));
create policy favorites_delete on public.favorites for delete to authenticated using(user_id=(select auth.uid()));
grant select on public.booking_quotes,public.bookings,public.booking_events,public.replacement_offers,
 public.damage_claims,public.property_reviews,public.favorites to authenticated;
grant insert,delete on public.favorites to authenticated;
create trigger touch_bookings before update on public.bookings for each row execute function private.touch_updated_at();
create trigger touch_damage before update on public.damage_claims for each row execute function private.touch_updated_at();
create trigger touch_reviews before update on public.property_reviews for each row execute function private.touch_updated_at();
