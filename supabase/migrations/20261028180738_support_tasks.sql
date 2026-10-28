create table public.support_cases (
 id uuid primary key default gen_random_uuid(), code text not null unique,
 type text not null check(type in ('booking','payment','refund','property_issue','damage_dispute','owner_cancellation_request','stay_exception','complaint','partner_support','other')),
 opened_by_user_id uuid not null references public.profiles(id), opener_scope text not null check(opener_scope in ('guest','partner','platform')),
 workspace_id uuid references public.workspaces(id), booking_id uuid references public.bookings(id),
 property_id uuid references public.properties(id),
 status text not null default 'open' check(status in ('open','in_progress','waiting_user','resolved','closed')),
 priority text not null default 'normal' check(priority in ('normal','high','urgent')),
 assigned_to uuid references public.profiles(id), sla_due_at timestamptz,
 disputed_amount_minor bigint check(disputed_amount_minor>=0), hold_scope text,
 resolution text, resolved_by uuid references public.profiles(id), resolved_at timestamptz,
 appeal_of_case_id uuid references public.support_cases(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.case_messages (
 id uuid primary key default gen_random_uuid(), case_id uuid not null references public.support_cases(id),
 author_user_id uuid not null references public.profiles(id), author_scope text not null check(author_scope in ('guest','partner','platform')),
 body text not null, visibility text not null default 'participants' check(visibility in ('participants','internal')),
 channel text not null default 'app' check(channel in ('app','phone','email','internal')),
 call_meta jsonb, created_at timestamptz not null default now()
);
create index case_messages_case_idx on public.case_messages(case_id,created_at);
create table public.attachments (
 id uuid primary key default gen_random_uuid(),
 entity_type text not null check(entity_type in ('support_case','case_message','damage_claim','refund','settlement','kashier_payout','cash_handover','journal_entry')),
 entity_id uuid not null, storage_key text not null unique, mime_type text not null,
 size_bytes bigint not null check(size_bytes>0), uploaded_by uuid not null references public.profiles(id),
 created_at timestamptz not null default now()
);
create table public.staff_tasks (
 id uuid primary key default gen_random_uuid(),
 type text not null check(type in ('property_review','support_visit','office_training','audit','other')),
 title text not null, description text, priority text not null default 'normal' check(priority in ('normal','high','urgent')),
 due_at timestamptz, status text not null default 'open' check(status in ('open','in_progress','done','cancelled')),
 assigned_to uuid not null references public.profiles(id), created_by uuid not null references public.profiles(id),
 related_entity_type text, related_entity_id uuid,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.staff_task_updates (
 id uuid primary key default gen_random_uuid(), task_id uuid not null references public.staff_tasks(id),
 author_user_id uuid not null references public.profiles(id), from_status text, to_status text not null,
 note text, created_at timestamptz not null default now()
);
alter table public.damage_claims add constraint damage_support_case_fk foreign key(support_case_id) references public.support_cases(id);
alter table public.support_cases enable row level security;
alter table public.case_messages enable row level security;
alter table public.attachments enable row level security;
alter table public.staff_tasks enable row level security;
alter table public.staff_task_updates enable row level security;
create policy support_cases_read on public.support_cases for select to authenticated
 using(opened_by_user_id=(select auth.uid()) or assigned_to=(select auth.uid()) or private.has_platform_permission('support.handle') or
 (workspace_id is not null and opener_scope='partner' and private.has_permission(workspace_id,'bookings.view',property_id)));
create policy case_messages_read on public.case_messages for select to authenticated
 using(author_user_id=(select auth.uid()) or private.has_platform_permission('support.handle') or
 exists(select 1 from public.support_cases c where c.id=case_id and visibility='participants' and
 ((c.opened_by_user_id=(select auth.uid()) and author_scope=c.opener_scope) or
 (c.workspace_id is not null and author_scope='partner' and private.has_permission(c.workspace_id,'bookings.view',c.property_id)))));
create policy staff_tasks_read on public.staff_tasks for select to authenticated
 using(assigned_to=(select auth.uid()) or created_by=(select auth.uid()) or private.has_platform_permission('tasks.assign'));
create policy task_updates_read on public.staff_task_updates for select to authenticated
 using(exists(select 1 from public.staff_tasks t where t.id=task_id and
 (t.assigned_to=(select auth.uid()) or t.created_by=(select auth.uid()) or private.has_platform_permission('tasks.assign'))));
grant select on public.support_cases,public.case_messages,public.staff_tasks,public.staff_task_updates to authenticated;
create trigger touch_support_cases before update on public.support_cases for each row execute function private.touch_updated_at();
create trigger touch_staff_tasks before update on public.staff_tasks for each row execute function private.touch_updated_at();
