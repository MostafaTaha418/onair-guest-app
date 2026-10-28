create schema if not exists private;
create extension if not exists pgcrypto with schema extensions;
create extension if not exists btree_gist with schema extensions;
create extension if not exists pg_trgm with schema extensions;
create extension if not exists unaccent with schema extensions;
create extension if not exists pg_cron with schema pg_catalog;

create or replace function private.touch_updated_at()
returns trigger language plpgsql set search_path = pg_catalog as $$
begin
  new.updated_at := now();
  return new;
end $$;

revoke all on schema private from public, anon, authenticated;
revoke all on all functions in schema private from public, anon, authenticated;
alter default privileges in schema private revoke execute on functions from public;
alter default privileges in schema public revoke execute on functions from public;
