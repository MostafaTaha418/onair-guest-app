create or replace function private.new_challenge(p_purpose text,p_recipient uuid,p_payload jsonb default '{}'::jsonb,
 p_entity_type text default null,p_entity_id uuid default null,p_session_id text default null) returns uuid
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_id uuid; v_ttl integer; v_resend integer;
begin
 if auth.uid() is null then raise exception 'UNAUTHENTICATED' using errcode='P0001'; end if;
 select coalesce((value #>> '{}')::integer,10) into v_ttl from public.platform_settings where key='otp_ttl_minutes';
 select coalesce((value #>> '{}')::integer,60) into v_resend from public.platform_settings where key='otp_resend_seconds';
 if exists(select 1 from private.otp_challenges c where c.requested_by_user_id=auth.uid()
   and c.purpose=p_purpose and c.consumed_at is null and c.created_at>now()-make_interval(secs=>v_resend)) then
   raise exception 'RATE_LIMITED' using errcode='P0001'; end if;
 insert into private.otp_challenges(purpose,recipient_user_id,requested_by_user_id,entity_type,entity_id,payload,session_id,expires_at)
 values(p_purpose,p_recipient,auth.uid(),p_entity_type,p_entity_id,p_payload,p_session_id,
 now()+make_interval(mins=>v_ttl)) returning id into v_id;
 return v_id;
end $$;
create or replace function public.common_request_phone_change(p_new_phone text,p_has_whatsapp boolean,
 p_whatsapp_e164 text default null) returns uuid
language plpgsql security definer set search_path=public,private,pg_temp as $$
begin
 if not private.current_profile_active() then raise exception 'ACCOUNT_SUSPENDED' using errcode='P0001'; end if;
 if p_new_phone !~ '^\+201[0125][0-9]{8}$' or
  (p_whatsapp_e164 is not null and p_whatsapp_e164 !~ '^\+201[0125][0-9]{8}$') then
   raise exception 'PHONE_COUNTRY_NOT_SUPPORTED' using errcode='P0001'; end if;
 if p_has_whatsapp and p_whatsapp_e164 is not null then raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
 if exists(select 1 from public.profiles where phone_e164=p_new_phone and status<>'deleted' and id<>auth.uid()) then
   raise exception 'PHONE_ALREADY_USED' using errcode='P0001'; end if;
 return private.new_challenge('phone_change',auth.uid(),jsonb_build_object(
  'phone_e164',p_new_phone,'phone_has_whatsapp',p_has_whatsapp,'whatsapp_e164',p_whatsapp_e164));
end $$;
create or replace function public.admin_start_login_challenge() returns uuid
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_session text := auth.jwt()->>'session_id';
begin
 if not private.current_profile_active() then raise exception 'ACCOUNT_SUSPENDED' using errcode='P0001'; end if;
 if v_session is null or not exists(select 1 from public.workspace_members m
 join public.workspaces w on w.id=m.workspace_id where w.kind='platform'
 and m.user_id=auth.uid() and m.status='active') then
   raise exception 'PERMISSION_DENIED' using errcode='P0001'; end if;
 return private.new_challenge('staff_login',auth.uid(),'{}'::jsonb,null,null,v_session);
end $$;
create or replace function private.set_otp_code(p_challenge_id uuid,p_code_hash text) returns void
language plpgsql security invoker set search_path=public,private,pg_temp as $$
declare v_resend integer;
begin
 if current_user not in ('postgres','service_role') then raise exception 'PERMISSION_DENIED' using errcode='P0001'; end if;
 if p_code_hash !~ '^\$2[aby]\$' then raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
 select (value #>> '{}')::integer into v_resend from public.platform_settings where key='otp_resend_seconds';
 update private.otp_challenges set code_hash=p_code_hash,sent_count=sent_count+1,
  last_sent_at=now(),attempts=0 where id=p_challenge_id and consumed_at is null
  and expires_at>now() and (last_sent_at is null or last_sent_at<=now()-make_interval(secs=>coalesce(v_resend,60)));
 if not found then raise exception 'RATE_LIMITED' using errcode='P0001'; end if;
end $$;
create or replace function private.verify_challenge(p_challenge_id uuid,p_code text,p_purpose text default null)
returns private.otp_challenges language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_challenge private.otp_challenges%rowtype; v_max_attempts integer;
begin
 select * into v_challenge from private.otp_challenges where id=p_challenge_id for update;
 if not found or v_challenge.recipient_user_id<>auth.uid() or v_challenge.consumed_at is not null
 or (p_purpose is not null and v_challenge.purpose<>p_purpose) then
  raise exception 'OTP_INVALID' using errcode='P0001'; end if;
 if v_challenge.expires_at<=now() then raise exception 'OTP_EXPIRED' using errcode='P0001'; end if;
 if v_challenge.purpose='staff_login' and v_challenge.session_id is distinct from auth.jwt()->>'session_id' then
  raise exception 'OTP_INVALID' using errcode='P0001'; end if;
 select (value #>> '{}')::integer into v_max_attempts from public.platform_settings where key='otp_max_attempts';
 if v_challenge.attempts>=coalesce(v_max_attempts,5) then raise exception 'RATE_LIMITED' using errcode='P0001'; end if;
 if v_challenge.code_hash is null or crypt(p_code,v_challenge.code_hash)<>v_challenge.code_hash then
  update private.otp_challenges set attempts=attempts+1 where id=p_challenge_id;
  return null;
 end if;
 update private.otp_challenges set consumed_at=now() where id=p_challenge_id;
 return v_challenge;
end $$;
create or replace function public.common_verify_otp(p_challenge_id uuid,p_code text) returns jsonb
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_challenge private.otp_challenges%rowtype;
begin
 if auth.uid() is null then raise exception 'UNAUTHENTICATED' using errcode='P0001'; end if;
 v_challenge:=private.verify_challenge(p_challenge_id,p_code,null);
 if v_challenge.id is null then return jsonb_build_object('verified',false,'error','OTP_INVALID'); end if;
 if v_challenge.purpose='phone_change' then
  update public.profiles set phone_e164=v_challenge.payload->>'phone_e164',
   phone_has_whatsapp=(v_challenge.payload->>'phone_has_whatsapp')::boolean,
   whatsapp_e164=v_challenge.payload->>'whatsapp_e164',phone_verified_at=now()
  where id=auth.uid();
  insert into public.audit_log(actor_user_id,actor_scope,action,entity_type,entity_id)
  values(auth.uid(),'guest','phone.changed','profile',auth.uid());
 elsif v_challenge.purpose not in ('staff_login','account_deletion') then
  raise exception 'ACTION_NOT_ALLOWED' using errcode='P0001';
 end if;
 return jsonb_build_object('purpose',v_challenge.purpose,'verified',true);
end $$;
revoke all on function private.new_challenge(text,uuid,jsonb,text,uuid,text),
 private.verify_challenge(uuid,text,text) from public,anon,authenticated;
revoke all on function private.set_otp_code(uuid,text) from public,anon,authenticated;
grant execute on function private.set_otp_code(uuid,text) to service_role;
revoke all on function public.common_request_phone_change(text,boolean,text),
 public.admin_start_login_challenge(),public.common_verify_otp(uuid,text) from public,anon;
grant execute on function public.common_request_phone_change(text,boolean,text),
 public.admin_start_login_challenge(),public.common_verify_otp(uuid,text) to authenticated;
