alter function private.resolve_booking_terms(uuid) set search_path=public,private,extensions,pg_temp;
alter function private.verify_challenge(uuid,text,text) set search_path=public,private,extensions,pg_temp;
