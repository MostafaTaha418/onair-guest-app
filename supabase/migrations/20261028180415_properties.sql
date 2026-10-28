create table public.properties (
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.workspaces(id),
 status text not null default 'draft' check(status in ('draft','in_review','published','rejected','paused','archived')),
 published_version_id uuid, base_nightly_price_minor bigint not null default 0 check(base_nightly_price_minor>=0),
 currency text not null default 'EGP' check(currency='EGP'), cash_collection_allowed boolean not null default false,
 paused_by_scope text check(paused_by_scope in ('partner','platform')), paused_reason text, paused_at timestamptz,
 published_at timestamptz, created_by uuid references public.profiles(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index properties_workspace_idx on public.properties(workspace_id,status);
create table public.property_versions (
 id uuid primary key default gen_random_uuid(), property_id uuid not null references public.properties(id),
 version_no integer not null check(version_no>0),
 status text not null default 'draft' check(status in ('draft','submitted','approved','rejected','superseded')),
 title text not null, description text, property_type text references public.property_types(key),
 location_id uuid references public.locations(id), address_text text,
 latitude numeric(10,7), longitude numeric(10,7),
 bedrooms integer not null default 0 check(bedrooms>=0), bathrooms integer not null default 0 check(bathrooms>=0),
 beds integer not null default 0 check(beds>=0), max_guests integer not null default 1 check(max_guests>0),
 area_sqm integer check(area_sqm>0), amenity_keys text[] not null default '{}', media_ids uuid[] not null default '{}',
 rules jsonb not null default '{}', access_instructions text,
 submitted_at timestamptz, submitted_by uuid references public.profiles(id),
 reviewed_by uuid references public.profiles(id), reviewed_at timestamptz, review_note text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(property_id,version_no)
);
create unique index one_editable_version on public.property_versions(property_id) where status in ('draft','submitted');
create index versions_location_idx on public.property_versions(location_id,status);
create index versions_amenities_idx on public.property_versions using gin(amenity_keys);
alter table public.properties add constraint published_version_fk foreign key(published_version_id) references public.property_versions(id);
create table public.property_media (
 id uuid primary key default gen_random_uuid(), property_id uuid not null references public.properties(id),
 storage_key text not null, variants jsonb not null default '[]', blurhash text,
 status text not null default 'uploaded' check(status in ('uploaded','ready','rejected')),
 uploaded_by uuid references public.profiles(id), created_at timestamptz not null default now()
);
create table public.markup_policies (
 id uuid primary key default gen_random_uuid(), scope text not null check(scope in ('platform','workspace','property')),
 workspace_id uuid references public.workspaces(id), property_id uuid references public.properties(id),
 mode text not null check(mode in ('fixed','percent')), fixed_minor bigint check(fixed_minor>=0),
 percent_bp integer check(percent_bp between 0 and 10000), min_minor bigint check(min_minor>=0),
 max_minor bigint check(max_minor>=0), effective_from timestamptz not null default now(), effective_to timestamptz,
 created_by uuid references public.profiles(id), created_at timestamptz not null default now(),
 check((scope='platform' and workspace_id is null and property_id is null) or
       (scope='workspace' and workspace_id is not null and property_id is null) or
       (scope='property' and property_id is not null))
);
create table public.booking_policies (
 id uuid primary key default gen_random_uuid(), scope text not null check(scope in ('platform','workspace','property')),
 workspace_id uuid references public.workspaces(id), property_id uuid references public.properties(id),
 deposit_type text not null check(deposit_type in ('percent','fixed','full')),
 deposit_percent_bp integer check(deposit_percent_bp between 0 and 10000), deposit_fixed_minor bigint check(deposit_fixed_minor>=0),
 free_cancellation_hours integer not null default 0 check(free_cancellation_hours>=0),
 effective_from timestamptz not null default now(), effective_to timestamptz,
 created_by uuid references public.profiles(id), created_at timestamptz not null default now()
);
create table public.property_cash_collectors (
 property_id uuid not null references public.properties(id), user_id uuid not null references public.profiles(id),
 granted_by uuid not null references public.profiles(id), is_active boolean not null default true,
 created_at timestamptz not null default now(), primary key(property_id,user_id)
);
create table public.property_calendar_locks (
 id uuid primary key default gen_random_uuid(), property_id uuid not null references public.properties(id),
 kind text not null check(kind in ('hold','booking','owner_block')), booking_id uuid,
 stay_range daterange not null check(not isempty(stay_range) and lower_inc(stay_range) and not upper_inc(stay_range)),
 reason text, created_by uuid references public.profiles(id), created_at timestamptz not null default now(),
 released_at timestamptz, released_reason text,
 check((kind='owner_block' and booking_id is null) or (kind<>'owner_block' and booking_id is not null))
);
alter table public.property_calendar_locks add constraint no_overlapping_locks
 exclude using gist(property_id with =, stay_range with &&) where(released_at is null);
alter table public.verification_documents add constraint verification_documents_property_fk foreign key(property_id) references public.properties(id);
alter table public.member_property_assignments add constraint member_assignment_property_fk foreign key(property_id) references public.properties(id);
alter table public.properties enable row level security;
alter table public.property_versions enable row level security;
alter table public.property_media enable row level security;
alter table public.markup_policies enable row level security;
alter table public.booking_policies enable row level security;
alter table public.property_cash_collectors enable row level security;
alter table public.property_calendar_locks enable row level security;
create policy properties_partner_read on public.properties for select to authenticated
 using(private.has_permission(workspace_id,'properties.view',id) or private.has_platform_permission('properties.review'));
create policy versions_partner_read on public.property_versions for select to authenticated
 using(exists(select 1 from public.properties p where p.id=property_id and
  (private.has_permission(p.workspace_id,'properties.view',p.id) or private.has_platform_permission('properties.review'))));
create policy media_partner_read on public.property_media for select to authenticated
 using(exists(select 1 from public.properties p where p.id=property_id and
  (private.has_permission(p.workspace_id,'properties.view',p.id) or private.has_platform_permission('properties.review'))));
create policy markup_platform_read on public.markup_policies for select to authenticated
 using(private.has_platform_permission('settings.manage_finance'));
create policy booking_policies_read on public.booking_policies for select to authenticated
 using(private.has_platform_permission('settings.manage') or
  (scope='workspace' and private.has_permission(workspace_id,'policies.manage')) or
  (scope='property' and exists(select 1 from public.properties p where p.id=property_id and private.has_permission(p.workspace_id,'policies.manage',p.id))));
create policy collectors_read on public.property_cash_collectors for select to authenticated
 using(private.has_platform_permission('properties.suspend') or exists(select 1 from public.properties p where p.id=property_id and private.has_permission(p.workspace_id,'properties.view',p.id)));
create policy locks_read on public.property_calendar_locks for select to authenticated
 using(private.has_platform_permission('bookings.view_all') or exists(select 1 from public.properties p where p.id=property_id and private.has_permission(p.workspace_id,'calendar.manage',p.id)));
grant select on public.properties,public.property_versions,public.property_media,public.markup_policies,
 public.booking_policies,public.property_cash_collectors,public.property_calendar_locks to authenticated;
create trigger touch_properties before update on public.properties for each row execute function private.touch_updated_at();
create trigger touch_versions before update on public.property_versions for each row execute function private.touch_updated_at();
