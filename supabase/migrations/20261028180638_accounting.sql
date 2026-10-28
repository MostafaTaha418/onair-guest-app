create table public.ledger_accounts (
 id uuid primary key default gen_random_uuid(), code text not null unique,
 name_ar text not null, name_en text not null,
 type text not null check(type in ('asset','liability','equity','revenue','expense')),
 parent_id uuid references public.ledger_accounts(id), is_system boolean not null default false,
 is_active boolean not null default true, created_at timestamptz not null default now()
);
create table public.journal_entries (
 id uuid primary key default gen_random_uuid(), entry_no bigint generated always as identity unique,
 entry_date date not null default current_date,
 source_type text not null check(source_type in ('payment','refund','booking','cash_handover','kashier_payout','settlement','manual')),
 source_id uuid, source_event text,
 status text not null default 'draft' check(status in ('draft','pending_approval','posted','reversed')),
 description text not null, created_by uuid references public.profiles(id),
 approved_by uuid references public.profiles(id), posted_at timestamptz,
 reversal_of uuid references public.journal_entries(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(source_type,source_id,source_event), check(created_by is null or approved_by is null or created_by<>approved_by)
);
create table public.journal_lines (
 id uuid primary key default gen_random_uuid(), entry_id uuid not null references public.journal_entries(id),
 account_id uuid not null references public.ledger_accounts(id),
 debit_minor bigint not null default 0 check(debit_minor>=0), credit_minor bigint not null default 0 check(credit_minor>=0),
 workspace_id uuid references public.workspaces(id), booking_id uuid references public.bookings(id),
 user_id uuid references public.profiles(id), created_at timestamptz not null default now(),
 check((debit_minor>0 and credit_minor=0) or (credit_minor>0 and debit_minor=0))
);
create index journal_lines_entry_idx on public.journal_lines(entry_id);
create index journal_lines_account_idx on public.journal_lines(account_id);
create or replace function private.check_journal_posting() returns trigger
language plpgsql set search_path=public,private,pg_temp as $$
declare dr bigint; cr bigint;
begin
 if old.status in ('posted','reversed') and row(new.*) is distinct from row(old.*) then
   raise exception 'JOURNAL_IMMUTABLE' using errcode='P0001';
 end if;
 if new.status='posted' and old.status is distinct from 'posted' then
   select coalesce(sum(debit_minor),0),coalesce(sum(credit_minor),0) into dr,cr
   from public.journal_lines where entry_id=new.id;
   if dr=0 or dr<>cr then raise exception 'JOURNAL_NOT_BALANCED' using errcode='P0001'; end if;
 end if;
 return new;
end $$;
create trigger check_journal_posting before update on public.journal_entries
for each row execute function private.check_journal_posting();
create or replace function private.check_journal_line_mutation() returns trigger
language plpgsql set search_path=public,private,pg_temp as $$
begin
 if exists(select 1 from public.journal_entries where id=coalesce(new.entry_id,old.entry_id) and status in ('posted','reversed')) then
  raise exception 'JOURNAL_IMMUTABLE' using errcode='P0001';
 end if;
 return coalesce(new,old);
end $$;
create trigger check_journal_line_mutation before insert or update or delete on public.journal_lines
for each row execute function private.check_journal_line_mutation();
alter table public.ledger_accounts enable row level security;
alter table public.journal_entries enable row level security;
alter table public.journal_lines enable row level security;
create policy ledger_read on public.ledger_accounts for select to authenticated using(private.has_platform_permission('accounting.view'));
create policy entries_read on public.journal_entries for select to authenticated using(private.has_platform_permission('accounting.view'));
create policy lines_read on public.journal_lines for select to authenticated using(private.has_platform_permission('accounting.view'));
grant select on public.ledger_accounts,public.journal_entries,public.journal_lines to authenticated;
create view public.trial_balance_v with(security_invoker=true) as
 select a.id,a.code,a.name_ar,a.name_en,a.type,
 coalesce(sum(l.debit_minor),0)::bigint debit_minor,coalesce(sum(l.credit_minor),0)::bigint credit_minor
 from public.ledger_accounts a left join public.journal_lines l on l.account_id=a.id
 left join public.journal_entries e on e.id=l.entry_id and e.status='posted'
 group by a.id;
create view public.general_ledger_v with(security_invoker=true) as
 select e.id entry_id,e.entry_no,e.entry_date,e.description,l.account_id,l.debit_minor,l.credit_minor,
 l.workspace_id,l.booking_id,l.user_id from public.journal_entries e join public.journal_lines l on l.entry_id=e.id where e.status='posted';
create view public.cash_custody_balances with(security_invoker=true) as
 select u.user_id,coalesce(sum(u.delta_minor),0)::bigint balance_minor from (
   select collector_user_id user_id,amount_minor delta_minor from public.payments where method='cash' and status='succeeded'
   union all select from_user_id,-amount_minor from public.cash_handovers where status='confirmed'
   union all select to_user_id,amount_minor from public.cash_handovers where status='confirmed'
 ) u group by u.user_id;
create view public.financial_transactions_v with(security_invoker=true) as
 select id,booking_id,'payment'::text kind,amount_minor,created_at from public.payments
 union all select id,booking_id,'refund',-amount_minor,created_at from public.refunds;
revoke all on public.trial_balance_v,public.general_ledger_v,public.cash_custody_balances,public.financial_transactions_v from anon,authenticated;
