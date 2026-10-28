alter table public.payments add column provider_kashier_order_id text;
create unique index payments_kashier_order_unique on public.payments(provider_kashier_order_id)
where provider_kashier_order_id is not null;
create or replace function private.capture_kashier_order_id() returns trigger
language plpgsql security definer set search_path=public,private,pg_temp as $$
begin
 if new.processed_at is not null and old.processed_at is null and new.signature_valid
 and new.payload->>'kashier_order_id' is not null then
  update public.payments set provider_kashier_order_id=new.payload->>'kashier_order_id'
  where provider_order_id=new.payload->>'provider_order_id';
 end if;
 return new;
end $$;
create trigger capture_kashier_order_id after update of processed_at on private.provider_webhook_events
for each row execute function private.capture_kashier_order_id();
revoke all on function private.capture_kashier_order_id() from public,anon,authenticated;
