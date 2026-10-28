alter table public.refunds add column provider_refund_status text
 check(provider_refund_status in ('PENDING','SUCCESS','FAILURE'));
create or replace function public.admin_request_refund(p_booking_id uuid,p_payment_id uuid,p_amount_minor bigint,
 p_reason text,p_method text) returns uuid
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_payment public.payments%rowtype; v_refunded bigint; v_id uuid; v_sla integer;
begin
 if not private.has_platform_permission('refunds.request') then raise exception 'PERMISSION_DENIED' using errcode='P0001'; end if;
 select * into v_payment from public.payments where id=p_payment_id and booking_id=p_booking_id for update;
 if not found or v_payment.status<>'succeeded' then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 select coalesce(sum(amount_minor),0) into v_refunded from public.refunds where payment_id=p_payment_id
 and status not in ('cancelled','failed');
 if p_amount_minor<=0 or p_amount_minor>v_payment.amount_minor-v_refunded then
  raise exception 'PAYMENT_AMOUNT_MISMATCH' using errcode='P0001'; end if;
 select (value #>> '{}')::integer into v_sla from public.platform_settings where key='refund_sla_hours';
 insert into public.refunds(booking_id,payment_id,amount_minor,reason,method,requested_by,due_at)
 values(p_booking_id,p_payment_id,p_amount_minor,p_reason,p_method,auth.uid(),
 now()+make_interval(hours=>coalesce(v_sla,72))) returning id into v_id;
 insert into public.audit_log(actor_user_id,actor_scope,action,entity_type,entity_id)
 values(auth.uid(),'platform','refund.requested','refund',v_id);
 return v_id;
end $$;
create or replace function public.admin_approve_refund(p_refund_id uuid) returns text
language plpgsql security definer set search_path=public,private,pg_temp as $$
begin
 if not private.has_platform_permission('refunds.approve') then raise exception 'PERMISSION_DENIED' using errcode='P0001'; end if;
 update public.refunds set status='approved',approved_by=auth.uid(),approved_at=now()
 where id=p_refund_id and status='requested';
 if not found then raise exception 'INVALID_BOOKING_STATE' using errcode='P0001'; end if;
 insert into public.audit_log(actor_user_id,actor_scope,action,entity_type,entity_id)
 values(auth.uid(),'platform','refund.approved','refund',p_refund_id);
 return 'approved';
end $$;
create or replace function public.admin_mark_refund_executed(p_refund_id uuid,p_reference text)
returns text language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_refund public.refunds%rowtype;
begin
 if not private.has_platform_permission('refunds.execute') then raise exception 'PERMISSION_DENIED' using errcode='P0001'; end if;
 select * into v_refund from public.refunds where id=p_refund_id for update;
 if not found or v_refund.status<>'approved' or v_refund.method='kashier' then
  raise exception 'INVALID_BOOKING_STATE' using errcode='P0001'; end if;
 if auth.uid() in (v_refund.requested_by,v_refund.approved_by) then
  raise exception 'SEPARATION_OF_DUTIES' using errcode='P0001'; end if;
 if length(trim(p_reference))<4 then raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
 update public.refunds set status='executed',executed_by=auth.uid(),executed_at=now(),
 provider_refund_id=p_reference where id=p_refund_id;
 insert into public.audit_log(actor_user_id,actor_scope,action,entity_type,entity_id)
 values(auth.uid(),'platform','refund.executed','refund',p_refund_id);
 return 'executed';
end $$;
create or replace function private.record_kashier_refund_result(p_refund_id uuid,p_status text,
 p_provider_refund_id text,p_executor uuid) returns text
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_refund public.refunds%rowtype;
begin
 if session_user not in ('postgres','service_role') then raise exception 'PERMISSION_DENIED' using errcode='P0001'; end if;
 select * into v_refund from public.refunds where id=p_refund_id for update;
 if not found or v_refund.method<>'kashier' or v_refund.status not in ('approved','executed') then
  raise exception 'INVALID_BOOKING_STATE' using errcode='P0001'; end if;
 if v_refund.status='executed' then
  if p_status='SUCCESS' and v_refund.provider_refund_status='PENDING' then
   update public.refunds set provider_refund_status='SUCCESS' where id=p_refund_id;
   return 'confirmed';
  end if;
  return 'duplicate';
 end if;
 if p_executor in (v_refund.requested_by,v_refund.approved_by) then
  raise exception 'SEPARATION_OF_DUTIES' using errcode='P0001'; end if;
 if p_status='FAILURE' then
  update public.refunds set status='failed',provider_refund_status='FAILURE',
   failure_reason='Kashier rejected refund'
  where id=p_refund_id;
  return 'failed';
 elsif p_status in ('SUCCESS','PENDING') then
  update public.refunds set status='executed',executed_by=p_executor,executed_at=now(),
   provider_refund_status=p_status,
   provider_refund_id=p_provider_refund_id where id=p_refund_id;
  return 'executed';
 else raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
end $$;
create or replace function public.admin_verify_refund(p_refund_id uuid,p_proof_attachment_id uuid default null)
returns text language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_refund public.refunds%rowtype;
begin
 if not private.has_platform_permission('refunds.verify') then raise exception 'PERMISSION_DENIED' using errcode='P0001'; end if;
 select * into v_refund from public.refunds where id=p_refund_id for update;
 if not found or v_refund.status<>'executed' then raise exception 'INVALID_BOOKING_STATE' using errcode='P0001'; end if;
 if auth.uid() in (v_refund.requested_by,v_refund.approved_by,v_refund.executed_by) then
  raise exception 'SEPARATION_OF_DUTIES' using errcode='P0001'; end if;
 if p_proof_attachment_id is not null and not exists(select 1 from public.attachments
  where id=p_proof_attachment_id and entity_type='refund' and entity_id=p_refund_id) then
  raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 if v_refund.method<>'kashier' and p_proof_attachment_id is null then
  raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
 if v_refund.method='kashier' and v_refund.provider_refund_status<>'SUCCESS' then
  raise exception 'ACTION_NOT_ALLOWED' using errcode='P0001'; end if;
 update public.refunds set status='verified',verified_by=auth.uid(),verified_at=now() where id=p_refund_id;
 insert into public.audit_log(actor_user_id,actor_scope,action,entity_type,entity_id)
 values(auth.uid(),'platform','refund.verified','refund',p_refund_id);
 return 'verified';
end $$;
revoke all on function public.admin_request_refund(uuid,uuid,bigint,text,text),
 public.admin_approve_refund(uuid),public.admin_mark_refund_executed(uuid,text),
 public.admin_verify_refund(uuid,uuid) from public,anon;
grant execute on function public.admin_request_refund(uuid,uuid,bigint,text,text),
 public.admin_approve_refund(uuid),public.admin_mark_refund_executed(uuid,text),
 public.admin_verify_refund(uuid,uuid) to authenticated;
revoke all on function private.record_kashier_refund_result(uuid,text,text,uuid) from public,anon,authenticated;
grant execute on function private.record_kashier_refund_result(uuid,text,text,uuid) to service_role;
