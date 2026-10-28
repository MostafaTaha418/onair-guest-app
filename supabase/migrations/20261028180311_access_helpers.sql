create table public.member_property_assignments (
  member_id uuid not null references public.workspace_members(id),
  property_id uuid not null, primary key(member_id,property_id)
);
alter table public.member_property_assignments enable row level security;
create or replace function private.current_profile_active() returns boolean
language sql stable security definer set search_path = public, private, pg_temp as $$
  select exists(select 1 from public.profiles where id=(select auth.uid()) and status='active')
$$;
create or replace function private.member_permissions(p_member_id uuid) returns text[]
language sql stable security definer set search_path = public, private, pg_temp as $$
  select coalesce(array(
    select distinct p from (
      select unnest(m.extra_permissions) p
      union all
      select unnest(r.permission_keys) p from public.role_presets r where r.key=any(m.role_preset_keys)
    ) x where not p=any(m.revoked_permissions)
  ), '{}') from public.workspace_members m where m.id=p_member_id
$$;
create or replace function private.staff_session_verified() returns boolean
language sql stable security definer set search_path = public, private, pg_temp as $$
  select exists(select 1 from private.otp_challenges c
    where c.purpose='staff_login' and c.recipient_user_id=(select auth.uid())
      and c.session_id=(select auth.jwt()->>'session_id')
      and c.session_id is not null and c.consumed_at is not null
      and c.expires_at>now())
$$;
create or replace function private.has_permission(p_workspace_id uuid,p_perm text,p_property_id uuid default null) returns boolean
language sql stable security definer set search_path = public, private, pg_temp as $$
  select private.current_profile_active() and exists (
    select 1 from public.workspace_members m join public.workspaces w on w.id=m.workspace_id
    where m.workspace_id=p_workspace_id and m.user_id=(select auth.uid())
      and m.status='active' and w.verification_status <> 'suspended'
      and p_perm=any(private.member_permissions(m.id))
      and (p_property_id is null or m.all_properties or exists(
        select 1 from public.member_property_assignments a
        where a.member_id=m.id and a.property_id=p_property_id))
  )
$$;
create or replace function private.has_platform_permission(p_perm text) returns boolean
language sql stable security definer set search_path = public, private, pg_temp as $$
  select private.current_profile_active() and private.staff_session_verified() and exists (
    select 1 from public.workspace_members m join public.workspaces w on w.id=m.workspace_id
    where w.kind='platform' and m.user_id=(select auth.uid()) and m.status='active'
      and w.verification_status <> 'suspended' and p_perm=any(private.member_permissions(m.id)))
$$;
grant usage on schema private to authenticated;
grant execute on function private.current_profile_active() to authenticated;
grant execute on function private.member_permissions(uuid) to authenticated;
grant execute on function private.staff_session_verified() to authenticated;
grant execute on function private.has_permission(uuid,text,uuid) to authenticated;
grant execute on function private.has_platform_permission(text) to authenticated;
create policy profiles_platform_read on public.profiles for select to authenticated
  using(private.has_platform_permission('users.view'));
create policy platform_settings_read on public.platform_settings for select to authenticated
  using(private.has_platform_permission('settings.manage') or private.has_platform_permission('audit.view'));
create policy audit_platform_read on public.audit_log for select to authenticated
  using(private.has_platform_permission('audit.view'));
create policy audit_partner_read on public.audit_log for select to authenticated
  using(workspace_id is not null and private.has_permission(workspace_id,'staff.manage'));
create policy workspaces_read on public.workspaces for select to authenticated
  using(private.has_permission(id,'workspace.manage') or private.has_permission(id,'properties.view') or private.has_platform_permission('users.view'));
create policy members_self_read on public.workspace_members for select to authenticated
  using(user_id=(select auth.uid()));
create policy members_manager_read on public.workspace_members for select to authenticated
  using(private.has_permission(workspace_id,'staff.manage') or private.has_platform_permission('platform.staff.manage'));
create policy invites_manager_read on public.workspace_invites for select to authenticated
  using(private.has_permission(workspace_id,'staff.manage') or private.has_platform_permission('platform.staff.manage'));
create policy verification_docs_read on public.verification_documents for select to authenticated
  using(private.has_permission(workspace_id,'workspace.manage') or private.has_platform_permission('identity_documents.view') or private.has_platform_permission('partners.review'));
create policy payout_methods_read on public.workspace_payout_methods for select to authenticated
  using(private.has_permission(workspace_id,'workspace.manage') or private.has_permission(workspace_id,'finance.view') or private.has_platform_permission('settlements.prepare'));
create policy assignments_read on public.member_property_assignments for select to authenticated
  using(exists(select 1 from public.workspace_members m where m.id=member_id and
    (m.user_id=(select auth.uid()) or private.has_permission(m.workspace_id,'staff.manage') or private.has_platform_permission('platform.staff.manage'))));
grant select on public.platform_settings,public.audit_log,public.workspaces,public.workspace_members,
  public.workspace_invites,public.verification_documents,public.workspace_payout_methods,
  public.member_property_assignments to authenticated;
