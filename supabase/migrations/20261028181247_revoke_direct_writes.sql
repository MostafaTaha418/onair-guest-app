do $$
declare r record;
begin
 for r in select tablename from pg_tables where schemaname='public' loop
   execute format('revoke insert,update,delete,truncate,references,trigger on table public.%I from anon,authenticated',r.tablename);
 end loop;
end $$;
grant insert,delete on public.favorites to authenticated;
alter default privileges in schema public revoke insert,update,delete,truncate,references,trigger on tables from anon,authenticated;
