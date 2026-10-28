create table public.locations (
  id uuid primary key default gen_random_uuid(), parent_id uuid references public.locations(id),
  level text not null check (level in ('governorate','city','area')),
  name_ar text not null, name_en text not null, search_text text not null default '',
  is_active boolean not null default true, sort_order integer not null default 0,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index locations_parent_idx on public.locations(parent_id);
create index locations_search_idx on public.locations using gin (search_text gin_trgm_ops);
create table public.amenities (
  key text primary key, label_ar text not null, label_en text not null, icon text,
  is_active boolean not null default true, sort_order integer not null default 0
);
create table public.property_types (
  key text primary key, label_ar text not null, label_en text not null,
  is_active boolean not null default true, sort_order integer not null default 0
);
create table public.app_config (
  id smallint primary key default 1 check (id=1),
  min_build_guest_android integer not null default 1, min_build_guest_ios integer not null default 1,
  min_build_partner_android integer not null default 1, min_build_partner_ios integer not null default 1,
  support_phone text, support_whatsapp text, guest_terms_version text not null default '1',
  partner_terms_version text not null default '1', terms_url text, privacy_url text,
  updated_at timestamptz not null default now(), updated_by uuid
);
create table public.platform_settings (
  key text primary key, value jsonb not null,
  domain text not null check (domain in ('bookings','payments','refunds','settlements','notifications','security','general')),
  is_sensitive boolean not null default false,
  updated_at timestamptz not null default now(), updated_by uuid
);
create table public.faq_items (
  id uuid primary key default gen_random_uuid(), audience text not null check (audience in ('guest','partner')),
  question_ar text not null, answer_ar text not null, question_en text, answer_en text,
  sort_order integer not null default 0, is_published boolean not null default false,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.permissions (
  key text primary key, scope text not null check (scope in ('partner','platform')),
  label_ar text not null, description_ar text, is_sensitive boolean not null default false
);
create table public.role_presets (
  key text primary key, scope text not null check (scope in ('partner','platform')),
  label_ar text not null, permission_keys text[] not null default '{}', is_system boolean not null default true
);
alter table public.locations enable row level security;
alter table public.amenities enable row level security;
alter table public.property_types enable row level security;
alter table public.app_config enable row level security;
alter table public.platform_settings enable row level security;
alter table public.faq_items enable row level security;
alter table public.permissions enable row level security;
alter table public.role_presets enable row level security;
create policy locations_read on public.locations for select to anon, authenticated using (is_active);
create policy amenities_read on public.amenities for select to anon, authenticated using (is_active);
create policy property_types_read on public.property_types for select to anon, authenticated using (is_active);
create policy app_config_read on public.app_config for select to anon, authenticated using (true);
create policy faq_read on public.faq_items for select to anon, authenticated using (is_published);
create policy permissions_read on public.permissions for select to authenticated using (true);
create policy role_presets_read on public.role_presets for select to authenticated using (true);
grant select on public.locations, public.amenities, public.property_types, public.app_config, public.faq_items to anon, authenticated;
grant select on public.permissions, public.role_presets to authenticated;
insert into public.app_config(id) values(1);
create trigger touch_locations before update on public.locations for each row execute function private.touch_updated_at();
create trigger touch_faq before update on public.faq_items for each row execute function private.touch_updated_at();
