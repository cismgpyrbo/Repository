-- 拾光誌操作紀錄：資料庫觸發器自動追蹤管理資料異動
-- 僅作用於 blog_* 資料表，不修改其他專案資料表。
alter table public.blog_audit_logs add column if not exists actor_label text;

create or replace function public.blog_capture_audit()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_old jsonb; v_new jsonb; v_before jsonb; v_after jsonb;
  v_actor uuid; v_action text; v_entity text; v_entity_id text;
  v_summary text; v_old_status text; v_new_status text;
  v_actor_label text; v_request_id text;
begin
  v_actor := auth.uid();
  if tg_op <> 'INSERT' then v_old := to_jsonb(old); end if;
  if tg_op <> 'DELETE' then v_new := to_jsonb(new); end if;
  v_old_status := v_old ->> 'status'; v_new_status := v_new ->> 'status';
  v_entity := case tg_table_name
    when 'blog_posts' then 'post' when 'blog_media' then 'media'
    when 'blog_news_articles' then 'news' when 'blog_news_import_batches' then 'news_import_batch'
    when 'blog_categories' then 'category' when 'blog_tags' then 'tag'
    when 'blog_post_tags' then 'post_tag' else tg_table_name end;
  if tg_op = 'INSERT' then
    v_action := case when tg_table_name = 'blog_media' then 'upload' else 'create' end;
  elsif tg_op = 'DELETE' then v_action := 'delete';
  else
    v_action := 'update';
    if v_old_status is distinct from v_new_status then
      if v_new_status = 'published' then v_action := 'publish';
      elsif v_old_status = 'published' and v_new_status <> 'published' then
        v_action := case when v_new_status = 'archived' then 'archive' else 'unpublish' end;
      elsif v_new_status = 'archived' then v_action := 'archive';
      elsif v_old_status = 'archived' and v_new_status <> 'archived' then v_action := 'restore';
      end if;
    end if;
  end if;

  if tg_table_name = 'blog_posts' then
    v_before := case when v_old is null then null else jsonb_build_object('title',v_old->'title','slug',v_old->'slug','status',v_old->'status','category_id',v_old->'category_id','cover_image_id',v_old->'cover_image_id','is_featured',v_old->'is_featured','published_at',v_old->'published_at') end;
    v_after := case when v_new is null then null else jsonb_build_object('title',v_new->'title','slug',v_new->'slug','status',v_new->'status','category_id',v_new->'category_id','cover_image_id',v_new->'cover_image_id','is_featured',v_new->'is_featured','published_at',v_new->'published_at') end;
    v_entity_id := coalesce(v_new->>'id',v_old->>'id'); v_summary := coalesce(v_new->>'title',v_old->>'title','文章') || '：' || v_action;
  elsif tg_table_name = 'blog_media' then
    v_before := case when v_old is null then null else jsonb_build_object('file_name',v_old->'file_name','storage_path',v_old->'storage_path','folder',v_old->'folder','mime_type',v_old->'mime_type','file_size_bytes',v_old->'file_size_bytes','alt_text',v_old->'alt_text','caption',v_old->'caption','status',v_old->'status') end;
    v_after := case when v_new is null then null else jsonb_build_object('file_name',v_new->'file_name','storage_path',v_new->'storage_path','folder',v_new->'folder','mime_type',v_new->'mime_type','file_size_bytes',v_new->'file_size_bytes','alt_text',v_new->'alt_text','caption',v_new->'caption','status',v_new->'status') end;
    v_entity_id := coalesce(v_new->>'id',v_old->>'id'); v_summary := coalesce(v_new->>'file_name',v_old->>'file_name','圖片') || '：' || v_action;
  elsif tg_table_name = 'blog_news_articles' then
    v_before := case when v_old is null then null else jsonb_build_object('title',v_old->'title','slug',v_old->'slug','news_date',v_old->'news_date','category',v_old->'category','source_name',v_old->'source_name','source_url',v_old->'source_url','content_type',v_old->'content_type','status',v_old->'status','published_at',v_old->'published_at') end;
    v_after := case when v_new is null then null else jsonb_build_object('title',v_new->'title','slug',v_new->'slug','news_date',v_new->'news_date','category',v_new->'category','source_name',v_new->'source_name','source_url',v_new->'source_url','content_type',v_new->'content_type','status',v_new->'status','published_at',v_new->'published_at') end;
    v_entity_id := coalesce(v_new->>'id',v_old->>'id'); v_summary := coalesce(v_new->>'title',v_old->>'title','新聞') || '：' || v_action;
  elsif tg_table_name = 'blog_news_import_batches' then
    v_before := case when v_old is null then null else jsonb_build_object('batch_date',v_old->'batch_date','total_count',v_old->'total_count','accepted_count',v_old->'accepted_count','duplicate_count',v_old->'duplicate_count','rejected_count',v_old->'rejected_count','status',v_old->'status') end;
    v_after := case when v_new is null then null else jsonb_build_object('batch_date',v_new->'batch_date','total_count',v_new->'total_count','accepted_count',v_new->'accepted_count','duplicate_count',v_new->'duplicate_count','rejected_count',v_new->'rejected_count','status',v_new->'status') end;
    v_entity_id := coalesce(v_new->>'id',v_old->>'id'); v_summary := '新聞匯入批次 ' || coalesce(v_new->>'batch_date',v_old->>'batch_date','') || '：' || v_action;
  elsif tg_table_name = 'blog_categories' then
    v_before := case when v_old is null then null else jsonb_build_object('name',v_old->'name','slug',v_old->'slug','is_active',v_old->'is_active') end;
    v_after := case when v_new is null then null else jsonb_build_object('name',v_new->'name','slug',v_new->'slug','is_active',v_new->'is_active') end;
    v_entity_id := coalesce(v_new->>'id',v_old->>'id'); v_summary := coalesce(v_new->>'name',v_old->>'name','文章分類') || '：' || v_action;
  elsif tg_table_name = 'blog_tags' then
    v_before := case when v_old is null then null else jsonb_build_object('name',v_old->'name','slug',v_old->'slug') end;
    v_after := case when v_new is null then null else jsonb_build_object('name',v_new->'name','slug',v_new->'slug') end;
    v_entity_id := coalesce(v_new->>'id',v_old->>'id'); v_summary := coalesce(v_new->>'name',v_old->>'name','文章標籤') || '：' || v_action;
  else
    v_before := v_old; v_after := v_new;
    v_entity_id := coalesce(v_new->>'post_id',v_old->>'post_id') || ':' || coalesce(v_new->>'tag_id',v_old->>'tag_id');
    v_summary := '文章標籤關聯：' || v_action;
  end if;

  select a.display_name into v_actor_label from public.blog_admins a where a.user_id = v_actor;
  if v_actor_label is null then v_actor_label := case when v_actor is null then '系統／排程' else '管理者' end; end if;
  begin v_request_id := nullif(current_setting('request.headers', true), '')::jsonb ->> 'x-request-id';
  exception when others then v_request_id := null; end;

  insert into public.blog_audit_logs(actor_id,actor_label,action,entity_type,entity_id,summary,before_data,after_data,request_id)
  values(v_actor,v_actor_label,v_action,v_entity,v_entity_id,v_summary,v_before,v_after,v_request_id);
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;
revoke all on function public.blog_capture_audit() from public, anon, authenticated;

do $$
declare tbl text;
begin
  foreach tbl in array array['blog_posts','blog_media','blog_news_articles','blog_news_import_batches','blog_categories','blog_tags','blog_post_tags'] loop
    execute format('drop trigger if exists %I on public.%I','trg_'||tbl||'_audit',tbl);
    execute format('create trigger %I after insert or update or delete on public.%I for each row execute function public.blog_capture_audit()','trg_'||tbl||'_audit',tbl);
  end loop;
end;
$$;
