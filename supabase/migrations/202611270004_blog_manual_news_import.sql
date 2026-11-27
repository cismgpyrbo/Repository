-- 拾光誌：手動新聞匯入 RPC
-- 只操作 blog_news_import_batches / blog_news_articles。
-- 使用 SECURITY INVOKER，並由資料庫再次檢查管理者身分；整批 RPC 在單一交易中執行。
create or replace function public.blog_import_news_batch(
  p_raw_content text,
  p_items jsonb,
  p_rejected_count integer default 0
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_batch_id uuid;
  v_batch_date date;
  v_item jsonb;
  v_inserted integer := 0;
  v_duplicates integer := 0;
  v_rows integer;
  v_slug text;
  v_type text;
begin
  if v_uid is null or not public.is_blog_admin() then
    raise exception 'Only authenticated blog administrators may import news' using errcode = '42501';
  end if;
  if p_raw_content is null or length(trim(p_raw_content)) = 0 then
    raise exception 'Raw import content is required';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'At least one valid news item is required';
  end if;
  if coalesce(p_rejected_count, 0) < 0 then
    raise exception 'Rejected count cannot be negative';
  end if;

  select min((x.value->>'date')::date)
    into v_batch_date
    from jsonb_array_elements(p_items) as x(value);

  insert into public.blog_news_import_batches(
    batch_date, raw_content, total_count, accepted_count,
    duplicate_count, rejected_count, status, imported_by
  )
  values (
    v_batch_date, p_raw_content, jsonb_array_length(p_items) + coalesce(p_rejected_count, 0),
    0, 0, coalesce(p_rejected_count, 0), 'draft', v_uid
  )
  returning id into v_batch_id;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    v_slug := v_item->>'slug';
    v_type := coalesce(v_item->>'content_type', 'article');
    if coalesce(trim(v_item->>'title'), '') = ''
      or coalesce(trim(v_item->>'category'), '') = ''
      or coalesce(trim(v_item->>'source'), '') = ''
      or coalesce(trim(v_item->>'summary'), '') = ''
      or coalesce(trim(v_item->>'detail'), '') = ''
      or coalesce(trim(v_item->>'url'), '') !~* '^https?://'
      or coalesce(v_slug, '') !~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'
      or v_type not in ('article','daily_briefing')
    then
      raise exception 'Invalid news item supplied to import function';
    end if;

    insert into public.blog_news_articles(
      batch_id, content_type, title, slug, news_date, category,
      source_name, source_url, summary, content, keywords,
      status, is_featured, author_id
    )
    values (
      v_batch_id, v_type, trim(v_item->>'title'), v_slug,
      (v_item->>'date')::date, trim(v_item->>'category'),
      trim(v_item->>'source'), trim(v_item->>'url'),
      trim(v_item->>'summary'), trim(v_item->>'detail'),
      coalesce(array(select jsonb_array_elements_text(coalesce(v_item->'keywords','[]'::jsonb))), '{}'::text[]),
      'draft', false, v_uid
    )
    on conflict (slug) do nothing;

    get diagnostics v_rows = row_count;
    if v_rows = 1 then v_inserted := v_inserted + 1;
    else v_duplicates := v_duplicates + 1;
    end if;
  end loop;

  update public.blog_news_import_batches
  set accepted_count = v_inserted,
      duplicate_count = v_duplicates,
      status = 'completed'
  where id = v_batch_id;

  return jsonb_build_object(
    'batch_id', v_batch_id,
    'inserted_count', v_inserted,
    'duplicate_count', v_duplicates,
    'rejected_count', coalesce(p_rejected_count, 0),
    'total_count', jsonb_array_length(p_items) + coalesce(p_rejected_count, 0),
    'status', 'completed'
  );
end;
$function$;

revoke all on function public.blog_import_news_batch(text, jsonb, integer) from public, anon;
grant execute on function public.blog_import_news_batch(text, jsonb, integer) to authenticated;
