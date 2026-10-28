create table public.kashier_payouts (
 id uuid primary key default gen_random_uuid(), provider_batch_id text unique,
 period_from date not null, period_to date not null,
 gross_minor bigint not null check(gross_minor>=0), fees_minor bigint not null check(fees_minor>=0),
 net_minor bigint not null check(net_minor>=0),
 status text not null default 'synced' check(status in ('synced','bank_verified','discrepancy')),
 synced_at timestamptz not null default now(), bank_verified_by uuid references public.profiles(id),
 bank_verified_at timestamptz, note text, created_at timestamptz not null default now(),
 check(period_to>=period_from), check(net_minor+fees_minor=gross_minor)
);
create table public.payments (
 id uuid primary key default gen_random_uuid(), booking_id uuid not null references public.bookings(id),
 purpose text not null check(purpose in ('initial','remaining','replacement_difference')),
 method text not null check(method in ('kashier','cash')),
 status text not null default 'pending' check(status in ('pending','verifying','pending_guest_confirmation','succeeded','failed','cancelled','expired')),
 amount_minor bigint not null check(amount_minor>0), currency text not null default 'EGP' check(currency='EGP'),
 idempotency_key text not null, provider_order_id text unique, provider_transaction_id text unique,
 payment_url text, payment_url_expires_at timestamptz,
 verified_at timestamptz, verified_via text check(verified_via in ('webhook','api_query','guest_otp')),
 collector_user_id uuid references public.profiles(id), guest_confirmed_at timestamptz,
 kashier_payout_id uuid references public.kashier_payouts(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(booking_id,purpose,idempotency_key)
);
create index payments_booking_idx on public.payments(booking_id,status);
create table private.provider_webhook_events (
 id uuid primary key default gen_random_uuid(), provider text not null check(provider='kashier'),
 provider_event_id text not null unique, event_type text not null, payload jsonb not null,
 signature_valid boolean not null, received_at timestamptz not null default now(),
 processed_at timestamptz, processing_error text
);
create table public.refunds (
 id uuid primary key default gen_random_uuid(), booking_id uuid not null references public.bookings(id),
 payment_id uuid references public.payments(id), amount_minor bigint not null check(amount_minor>0),
 currency text not null default 'EGP' check(currency='EGP'),
 reason text not null check(reason in ('owner_rejected','owner_timeout','payment_conflict','guest_cancellation','platform_cancellation','replacement_difference','other')),
 method text not null check(method in ('kashier','bank_transfer','mobile_wallet','cash')),
 status text not null default 'requested' check(status in ('requested','approved','executed','verified','failed','cancelled')),
 requested_by uuid references public.profiles(id), requested_at timestamptz not null default now(),
 approved_by uuid references public.profiles(id), approved_at timestamptz,
 executed_by uuid references public.profiles(id), executed_at timestamptz,
 verified_by uuid references public.profiles(id), verified_at timestamptz,
 provider_refund_id text unique, idempotency_key text unique,
 failure_reason text, due_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(approved_by is null or executed_by is null or approved_by<>executed_by),
 check(executed_by is null or verified_by is null or executed_by<>verified_by)
);
create index refunds_booking_idx on public.refunds(booking_id,status);
create table public.cash_handovers (
 id uuid primary key default gen_random_uuid(), from_user_id uuid not null references public.profiles(id),
 to_user_id uuid not null references public.profiles(id), workspace_id uuid references public.workspaces(id),
 amount_minor bigint not null check(amount_minor>0),
 status text not null default 'pending_confirmation' check(status in ('pending_confirmation','confirmed','rejected','cancelled')),
 confirmed_at timestamptz, receipt_no text unique, note text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(from_user_id<>to_user_id)
);
create table public.settlements (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id),
 period_from date not null, period_to date not null,
 method text not null check(method in ('bank_transfer','mobile_wallet','cash','ledger_offset')),
 total_minor bigint not null default 0 check(total_minor>=0),
 status text not null default 'draft' check(status in ('draft','approved','paid','verified','cancelled')),
 reference_no text, prepared_by uuid references public.profiles(id), prepared_at timestamptz,
 approved_by uuid references public.profiles(id), approved_at timestamptz,
 executed_by uuid references public.profiles(id), executed_at timestamptz,
 verified_by uuid references public.profiles(id), verified_at timestamptz,
 note text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(period_to>=period_from),
 check(prepared_by is null or approved_by is null or prepared_by<>approved_by),
 check(approved_by is null or verified_by is null or approved_by<>verified_by)
);
create table public.owner_payables (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id),
 booking_id uuid not null references public.bookings(id),
 type text not null check(type in ('stay_base','cancellation_share','forfeited_deposit_share','adjustment')),
 amount_minor bigint not null,
 status text not null default 'eligible' check(status in ('eligible','in_settlement','paid','on_hold_dispute','reversed')),
 eligible_at timestamptz not null default now(), settlement_id uuid references public.settlements(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.kashier_payouts enable row level security;
alter table public.payments enable row level security;
alter table private.provider_webhook_events enable row level security;
alter table public.refunds enable row level security;
alter table public.cash_handovers enable row level security;
alter table public.settlements enable row level security;
alter table public.owner_payables enable row level security;
create policy payouts_platform_read on public.kashier_payouts for select to authenticated
 using(private.has_platform_permission('kashier.reconcile') or private.has_platform_permission('accounting.view'));
create policy payments_platform_read on public.payments for select to authenticated
 using(private.has_platform_permission('bookings.view_all') or private.has_platform_permission('kashier.reconcile'));
create policy refunds_platform_read on public.refunds for select to authenticated
 using(private.has_platform_permission('refunds.request') or private.has_platform_permission('accounting.view'));
create policy handovers_read on public.cash_handovers for select to authenticated
 using(from_user_id=(select auth.uid()) or to_user_id=(select auth.uid()) or
 private.has_permission(workspace_id,'finance.view') or private.has_platform_permission('cash.receive_handover'));
create policy settlements_read on public.settlements for select to authenticated
 using(private.has_permission(workspace_id,'finance.view') or private.has_platform_permission('settlements.prepare') or private.has_platform_permission('accounting.view'));
create policy payables_read on public.owner_payables for select to authenticated
 using(private.has_permission(workspace_id,'finance.view') or private.has_platform_permission('settlements.prepare') or private.has_platform_permission('accounting.view'));
grant select on public.kashier_payouts,public.payments,public.refunds,public.cash_handovers,
 public.settlements,public.owner_payables to authenticated;
create trigger touch_payments before update on public.payments for each row execute function private.touch_updated_at();
create trigger touch_refunds before update on public.refunds for each row execute function private.touch_updated_at();
create trigger touch_handovers before update on public.cash_handovers for each row execute function private.touch_updated_at();
create trigger touch_settlements before update on public.settlements for each row execute function private.touch_updated_at();
create trigger touch_payables before update on public.owner_payables for each row execute function private.touch_updated_at();
