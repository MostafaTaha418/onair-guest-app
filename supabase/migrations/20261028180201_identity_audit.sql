create table public.profiles (
  id uuid primary key references auth.users(id) on delete restrict,
  full_name text not null check (char_length(full_name) between 2 and 80),
  email text not null, phone_e164 text not null check (phone_e164 ~ '^\+201[0125][0-9]{8}$'),
  phone_verified_at timestamptz, phone_has_whatsapp boolean not null default false,
  whatsapp_e164 text check (whatsapp_e164 is null or whatsapp_e164 ~ '^\+201[0125][0-9]{8}$'),
  avatar_key text, locale text not null default 'ar' check (locale in ('ar','en')),
  accepted_terms_version text not null, accepted_terms_at timestamptz not null default now(),
  status text not null default 'active' check (status in ('active','suspended','deleted')),
  last_seen_at timestamptz, anonymized_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  constraint whatsapp_consistent check (not (phone_has_whatsapp and whatsapp_e164 is not null))
);
create unique index profiles_active_phone_unique on public.profiles(phone_e164) where status <> 'deleted';
create index profiles_email_idx on public.profiles(email);
create table private.otp_challenges (
  id uuid primary key default gen_random_uuid(),
  purpose text not null check (purpose in ('phone_change','staff_login','cash_payment_confirm','cash_handover_confirm','account_deletion')),
  recipient_user_id uuid not null references public.profiles(id),
  requested_by_user_id uuid not null references public.profiles(id),
  entity_type text, entity_id uuid, payload jsonb not null default '{}', session_id text,
  code_hash text, sent_count integer not null default 0, last_sent_at timestamptz,
  attempts integer not null default 0, expires_at timestamptz not null,
  consumed_at timestamptz, created_at timestamptz not null default now()
);
create index otp_recipient_idx on private.otp_challenges(recipient_user_id,purpose,expires_at);
create index otp_session_idx on private.otp_challenges(session_id) where purpose='staff_login';
create table public.audit_log (
  id uuid primary key default gen_random_uuid(), actor_user_id uuid references public.profiles(id),
  actor_scope text not null check (actor_scope in ('guest','partner','platform','system')),
  workspace_id uuid, action text not null, entity_type text not null, entity_id uuid,
  before jsonb, after jsonb, reason text, request_id text,
  created_at timestamptz not null default now()
);
create index audit_entity_idx on public.audit_log(entity_type,entity_id,created_at desc);
create index audit_workspace_idx on public.audit_log(workspace_id,created_at desc);
alter table public.profiles enable row level security;
alter table public.audit_log enable row level security;
alter table private.otp_challenges enable row level security;
create policy profiles_self_read on public.profiles for select to authenticated using (id=(select auth.uid()));
grant select on public.profiles to authenticated;
create trigger touch_profiles before update on public.profiles for each row execute function private.touch_updated_at();

create or replace function private.handle_new_user() returns trigger
language plpgsql security definer set search_path = public, private, pg_temp as $$
declare meta jsonb := new.raw_user_meta_data;
begin
  if coalesce(meta->>'phone_e164','') !~ '^\+201[0125][0-9]{8}$' then
    raise exception 'PHONE_COUNTRY_NOT_SUPPORTED' using errcode='P0001';
  end if;
  if coalesce(meta->>'full_name','') = '' or char_length(meta->>'full_name') not between 2 and 80 then
    raise exception 'VALIDATION_FAILED' using errcode='P0001';
  end if;
  if meta->>'accepted_terms_version' is distinct from (select guest_terms_version from public.app_config where id=1) then
    raise exception 'TERMS_CHANGED' using errcode='P0001';
  end if;
  if exists(select 1 from public.profiles where phone_e164=meta->>'phone_e164' and status <> 'deleted') then
    raise exception 'PHONE_ALREADY_USED' using errcode='P0001';
  end if;
  insert into public.profiles(id,full_name,email,phone_e164,phone_has_whatsapp,whatsapp_e164,locale,accepted_terms_version)
  values(new.id,meta->>'full_name',new.email,meta->>'phone_e164',coalesce((meta->>'phone_has_whatsapp')::boolean,false),
         nullif(meta->>'whatsapp_e164',''),coalesce(meta->>'locale','ar'),meta->>'accepted_terms_version');
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function private.handle_new_user();
create or replace function private.handle_email_confirmed() returns trigger
language plpgsql security definer set search_path = public, private, pg_temp as $$
begin
  update public.profiles set email=new.email,
    phone_verified_at=case when old.email_confirmed_at is null and new.email_confirmed_at is not null then now() else phone_verified_at end
  where id=new.id;
  return new;
end $$;
create trigger on_auth_user_updated after update of email,email_confirmed_at on auth.users
for each row when (old.email is distinct from new.email or old.email_confirmed_at is distinct from new.email_confirmed_at)
execute function private.handle_email_confirmed();
create or replace function private.audit_immutable() returns trigger language plpgsql set search_path = pg_catalog as $$
begin raise exception 'AUDIT_IMMUTABLE' using errcode='P0001'; end $$;
create trigger audit_immutable before update or delete on public.audit_log for each row execute function private.audit_immutable();
