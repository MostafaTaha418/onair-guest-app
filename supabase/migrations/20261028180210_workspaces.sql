create table public.workspaces (
  id uuid primary key default gen_random_uuid(),
  kind text not null check(kind in ('individual_owner','office','platform')),
  display_name text not null, legal_name text,
  principal_user_id uuid references public.profiles(id),
  contact_phone_e164 text, contact_email text,
  governorate_id uuid references public.locations(id), address_text text,
  verification_status text not null default 'draft' check(verification_status in ('draft','pending','approved','rejected','suspended')),
  verification_note text, reviewed_by uuid references public.profiles(id), reviewed_at timestamptz,
  settlement_schedule text check(settlement_schedule in ('weekly','biweekly','monthly','manual')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index one_platform_workspace on public.workspaces(kind) where kind='platform';
create index workspaces_principal_idx on public.workspaces(principal_user_id);
create table public.workspace_members (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id),
  user_id uuid not null references public.profiles(id), is_principal boolean not null default false,
  role_preset_keys text[] not null default '{}', extra_permissions text[] not null default '{}',
  revoked_permissions text[] not null default '{}', all_properties boolean not null default true,
  status text not null default 'active' check(status in ('active','suspended','ended')),
  invited_by uuid references public.profiles(id), joined_at timestamptz not null default now(),
  ended_at timestamptz, status_reason text, last_active_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(workspace_id,user_id)
);
create index members_user_idx on public.workspace_members(user_id,status);
create table public.workspace_invites (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id),
  email text not null, role_preset_keys text[] not null default '{}', extra_permissions text[] not null default '{}',
  all_properties boolean not null default true, property_ids uuid[] not null default '{}', token_hash text not null,
  status text not null default 'pending' check(status in ('pending','accepted','revoked','expired')),
  expires_at timestamptz not null, invited_by uuid not null references public.profiles(id),
  accepted_by uuid references public.profiles(id), accepted_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create unique index invites_token_idx on public.workspace_invites(token_hash);
create table public.verification_documents (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id),
  property_id uuid, doc_type text not null check(doc_type in ('national_id','passport','ownership_proof','rental_authorization','commercial_register','activity_proof','representation_authorization')),
  storage_key text not null, status text not null default 'submitted' check(status in ('submitted','approved','rejected','superseded')),
  uploaded_by uuid not null references public.profiles(id), reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz, rejection_reason text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.workspace_payout_methods (
  id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id),
  method text not null check(method in ('bank_transfer','mobile_wallet','cash')),
  details jsonb not null default '{}', is_active boolean not null default false,
  verified_by uuid references public.profiles(id), verified_at timestamptz,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.workspaces enable row level security;
alter table public.workspace_members enable row level security;
alter table public.workspace_invites enable row level security;
alter table public.verification_documents enable row level security;
alter table public.workspace_payout_methods enable row level security;
create trigger touch_workspaces before update on public.workspaces for each row execute function private.touch_updated_at();
create trigger touch_members before update on public.workspace_members for each row execute function private.touch_updated_at();
create trigger touch_invites before update on public.workspace_invites for each row execute function private.touch_updated_at();
create trigger touch_verification_documents before update on public.verification_documents for each row execute function private.touch_updated_at();
create trigger touch_payout_methods before update on public.workspace_payout_methods for each row execute function private.touch_updated_at();
