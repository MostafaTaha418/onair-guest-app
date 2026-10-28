create or replace function private.is_property_public(p_property_id uuid) returns boolean
language sql stable security definer set search_path=public,private,pg_temp as $$
 select exists(select 1 from public.properties p
 join public.workspaces w on w.id=p.workspace_id
 join public.property_versions v on v.id=p.published_version_id and v.property_id=p.id
 where p.id=p_property_id and p.status='published' and v.status='approved'
 and w.verification_status='approved')
$$;
create or replace function private.effective_nightly_price(p_property_id uuid,p_on_date date)
returns table(base_minor bigint,markup_minor bigint,nightly_final_minor bigint,markup_mode text)
language plpgsql stable security definer set search_path=public,private,pg_temp as $$
declare v_base bigint; v_workspace uuid; v_policy public.markup_policies%rowtype; v_markup bigint;
begin
 select p.base_nightly_price_minor,p.workspace_id into v_base,v_workspace
 from public.properties p where p.id=p_property_id;
 if not found then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 select * into v_policy from public.markup_policies mp
 where mp.effective_from <= p_on_date::timestamptz
 and (mp.effective_to is null or mp.effective_to > p_on_date::timestamptz)
 and ((mp.scope='property' and mp.property_id=p_property_id)
   or (mp.scope='workspace' and mp.workspace_id=v_workspace)
   or mp.scope='platform')
 order by case mp.scope when 'property' then 1 when 'workspace' then 2 else 3 end,
 mp.effective_from desc,mp.created_at desc limit 1;
 if not found then raise exception 'POLICY_NOT_CONFIGURED' using errcode='P0001'; end if;
 v_markup := case when v_policy.mode='fixed' then coalesce(v_policy.fixed_minor,0)
 else (v_base*coalesce(v_policy.percent_bp,0)+9999)/10000 end;
 v_markup := greatest(v_markup,coalesce(v_policy.min_minor,0));
 if v_policy.max_minor is not null then v_markup:=least(v_markup,v_policy.max_minor); end if;
 return query select v_base,v_markup,v_base+v_markup,v_policy.mode;
end $$;
create or replace function private.resolve_booking_terms(p_property_id uuid) returns jsonb
language plpgsql stable security definer set search_path=public,private,pg_temp as $$
declare v_workspace uuid; v_policy public.booking_policies%rowtype; v_terms jsonb;
begin
 select workspace_id into v_workspace from public.properties where id=p_property_id;
 if not found then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 select * into v_policy from public.booking_policies bp
 where bp.effective_from<=now() and (bp.effective_to is null or bp.effective_to>now())
 and ((bp.scope='property' and bp.property_id=p_property_id)
 or (bp.scope='workspace' and bp.workspace_id=v_workspace) or bp.scope='platform')
 order by case bp.scope when 'property' then 1 when 'workspace' then 2 else 3 end,
 bp.effective_from desc,bp.created_at desc limit 1;
 if not found then raise exception 'POLICY_NOT_CONFIGURED' using errcode='P0001'; end if;
 v_terms:=jsonb_build_object('deposit_type',v_policy.deposit_type,
 'deposit_percent_bp',v_policy.deposit_percent_bp,'deposit_fixed_minor',v_policy.deposit_fixed_minor,
 'free_cancellation_hours',v_policy.free_cancellation_hours);
 return v_terms || jsonb_build_object('terms_hash',encode(digest(v_terms::text,'sha256'),'hex'));
end $$;
create or replace function public.guest_get_reference_data(p_locale text default 'ar') returns jsonb
language sql stable security definer set search_path=public,private,pg_temp as $$
 select jsonb_build_object(
  'locations',coalesce((select jsonb_agg(jsonb_build_object('id',id,'parent_id',parent_id,'level',level,
  'label',case when p_locale='en' then name_en else name_ar end) order by sort_order) from public.locations where is_active),'[]'::jsonb),
  'amenities',coalesce((select jsonb_agg(jsonb_build_object('key',key,'label',case when p_locale='en' then label_en else label_ar end,'icon',icon) order by sort_order) from public.amenities where is_active),'[]'::jsonb),
  'property_types',coalesce((select jsonb_agg(jsonb_build_object('key',key,'label',case when p_locale='en' then label_en else label_ar end) order by sort_order) from public.property_types where is_active),'[]'::jsonb))
$$;
create or replace function public.guest_search_locations(p_query text,p_limit integer default 20) returns jsonb
language sql stable security definer set search_path=public,private,pg_temp as $$
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'parent_id',parent_id,'level',level,
 'name_ar',name_ar,'name_en',name_en) order by sort_order),'[]'::jsonb)
 from (select * from public.locations where is_active and
 (name_ar ilike '%'||replace(replace(p_query,'%',''), '_','')||'%' or
 name_en ilike '%'||replace(replace(p_query,'%',''), '_','')||'%')
 order by sort_order limit least(greatest(p_limit,1),50)) q
$$;
create or replace function public.guest_get_property(p_property_id uuid,p_locale text default 'ar') returns jsonb
language plpgsql stable security definer set search_path=public,private,pg_temp as $$
declare v_result jsonb;
begin
 if not private.is_property_public(p_property_id) then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 select jsonb_build_object('id',p.id,'title',v.title,'description',v.description,
 'property_type',v.property_type,'location_id',v.location_id,'address_text',v.address_text,
 'bedrooms',v.bedrooms,'bathrooms',v.bathrooms,'beds',v.beds,'max_guests',v.max_guests,
 'area_sqm',v.area_sqm,'amenity_keys',v.amenity_keys,'rules',v.rules,
 'media',coalesce((select jsonb_agg(jsonb_build_object('id',m.id,'variants',m.variants,'blurhash',m.blurhash)
 order by array_position(v.media_ids,m.id)) from public.property_media m
 where m.id=any(v.media_ids) and m.status='ready'),'[]'::jsonb),
 'base_nightly_price_minor',null,'currency',p.currency)
 into v_result from public.properties p join public.property_versions v on v.id=p.published_version_id
 where p.id=p_property_id;
 return v_result - 'base_nightly_price_minor';
end $$;
create or replace function public.guest_get_property_unavailable_dates(
 p_property_id uuid,p_from date,p_to date) returns jsonb
language plpgsql stable security definer set search_path=public,private,pg_temp as $$
declare v_result jsonb;
begin
 if not private.is_property_public(p_property_id) then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 if p_to<=p_from or p_to>p_from+365 then raise exception 'VALIDATION_FAILED' using errcode='P0001'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('from',greatest(lower(stay_range),p_from),
 'to',least(upper(stay_range),p_to)) order by lower(stay_range)),'[]'::jsonb)
 into v_result from public.property_calendar_locks
 where property_id=p_property_id and released_at is null and stay_range && daterange(p_from,p_to,'[)');
 return v_result;
end $$;
create or replace function public.guest_list_property_reviews(
 p_property_id uuid,p_cursor timestamptz default null,p_limit integer default 20) returns jsonb
language plpgsql stable security definer set search_path=public,private,pg_temp as $$
declare v_result jsonb;
begin
 if not private.is_property_public(p_property_id) then raise exception 'NOT_FOUND' using errcode='P0001'; end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',id,'rating',rating,'comment',comment,
 'created_at',created_at) order by created_at desc),'[]'::jsonb) into v_result
 from (select id,rating,comment,created_at from public.property_reviews
 where property_id=p_property_id and status='approved' and (p_cursor is null or created_at<p_cursor)
 order by created_at desc limit least(greatest(p_limit,1),50)) q;
 return v_result;
end $$;
revoke all on function public.guest_get_reference_data(text),public.guest_search_locations(text,integer),
 public.guest_get_property(uuid,text),public.guest_get_property_unavailable_dates(uuid,date,date),
 public.guest_list_property_reviews(uuid,timestamptz,integer) from public;
grant execute on function public.guest_get_reference_data(text),public.guest_search_locations(text,integer),
 public.guest_get_property(uuid,text),public.guest_get_property_unavailable_dates(uuid,date,date),
 public.guest_list_property_reviews(uuid,timestamptz,integer) to anon,authenticated;
