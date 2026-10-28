create table public.notification_types (
 key text primary key, category text not null check(category in ('account','partner','staff','property','booking','payment','stay','refund','finance','support','review','task','system')),
 recipients jsonb not null default '[]', channels jsonb not null default '{}',
 priority text not null default 'normal' check(priority in ('normal','high','critical')),
 is_mandatory boolean not null default false, entity_type text not null,
 is_active boolean not null default true
);
create table public.notifications (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
 audience text not null check(audience in ('guest','partner','platform')),
 workspace_id uuid references public.workspaces(id), type_key text not null references public.notification_types(key),
 category text not null, priority text not null,
 entity_type text not null, entity_id uuid not null, title_key text not null, body_key text not null,
 params jsonb not null default '{}', read_at timestamptz, resolved_at timestamptz,
 resolved_by uuid references public.profiles(id), created_at timestamptz not null default now()
);
create index notifications_user_idx on public.notifications(user_id,created_at desc);
create index notifications_open_idx on public.notifications(user_id,created_at desc) where read_at is null;
create table public.notification_deliveries (
 id uuid primary key default gen_random_uuid(), notification_id uuid references public.notifications(id),
 channel text not null check(channel in ('push','web_push','email')),
 to_user_id uuid references public.profiles(id), to_address text, template_key text not null,
 payload jsonb not null default '{}', status text not null default 'queued' check(status in ('queued','sending','sent','failed','skipped')),
 attempts integer not null default 0, next_attempt_at timestamptz not null default now(),
 last_error text, provider_message_id text, sent_at timestamptz,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index deliveries_queue_idx on public.notification_deliveries(status,next_attempt_at);
create table public.notification_preferences (
 user_id uuid not null references public.profiles(id), category text not null,
 channel text not null check(channel in ('push','email','web_push')),
 enabled boolean not null default true, primary key(user_id,category,channel)
);
create table public.device_tokens (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
 app text not null check(app in ('guest','partner','admin_web')),
 platform text not null check(platform in ('android','ios','web')),
 token text not null unique, locale text not null default 'ar' check(locale in ('ar','en')),
 last_seen_at timestamptz not null default now(), created_at timestamptz not null default now()
);
alter table public.notification_types enable row level security;
alter table public.notifications enable row level security;
alter table public.notification_deliveries enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.device_tokens enable row level security;
create policy notification_types_read on public.notification_types for select to authenticated using(is_active);
create policy notifications_self_read on public.notifications for select to authenticated using(user_id=(select auth.uid()));
create policy deliveries_platform_read on public.notification_deliveries for select to authenticated using(private.has_platform_permission('settings.manage'));
create policy preferences_self_read on public.notification_preferences for select to authenticated using(user_id=(select auth.uid()));
create policy tokens_self_read on public.device_tokens for select to authenticated using(user_id=(select auth.uid()));
grant select on public.notification_types,public.notifications,public.notification_deliveries,
 public.notification_preferences,public.device_tokens to authenticated;
create trigger touch_deliveries before update on public.notification_deliveries for each row execute function private.touch_updated_at();
