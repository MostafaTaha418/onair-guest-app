create or replace function private.notify_booking_event() returns trigger
language plpgsql security definer set search_path=public,private,pg_temp as $$
declare v_workspace uuid; v_property uuid;
begin
 if exists(select 1 from public.notification_types where key=new.event_type and is_active) then
  select workspace_id,property_id into v_workspace,v_property from public.bookings where id=new.booking_id;
  perform private.notify(new.event_type,'booking',new.booking_id,v_workspace,v_property,'{}'::jsonb);
 end if;
 return new;
end $$;
create trigger booking_event_notify after insert on public.booking_events
for each row execute function private.notify_booking_event();
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.case_messages;
revoke all on function private.notify_booking_event() from public,anon,authenticated;
