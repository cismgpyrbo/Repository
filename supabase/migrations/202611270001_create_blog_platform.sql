-- 拾光誌 / Daily News Center database schema v1
-- Target: existing Supabase project shared with other applications.
-- All objects created here use the blog_ prefix. Existing acc_*, maocheng_*,
-- checkin_* and shareholders objects are not modified.
-- Review and back up the target project before applying in Supabase SQL Editor.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Administrator allowlist
-- ---------------------------------------------------------------------------
create table if not exists public.blog_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now()
);

create or replace function public.is_blog_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.blog_admins
    where user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_blog_admin() from public;
grant execute on function public.is_blog_admin() to authenticated;

-- ---------------------------------------------------------------------------
-- Blog content
-- ---------------------------------------------------------------------------
create table if not exists public.blog_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  description text not null default '',
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.blog_tags (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  created_at timestamptz not null default now()
);

create table if not exists public.blog_posts (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.blog_categories(id) on delete set null,
  title text not null check (length(trim(title)) > 0),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  excerpt text not null default '',
  content text not null default '',
  cover_image_id uuid,
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  is_featured boolean not null default false,
  seo_title text not null default '',
  seo_description text not null default '',
  published_at timestamptz,
  author_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint blog_posts_published_at_required
    check (status <> 'published' or published_at is not null)
);

create table if not exists public.blog_post_tags (
  post_id uuid not null references public.blog_posts(id) on delete cascade,
  tag_id uuid not null references public.blog_tags(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, tag_id)
);

-- ---------------------------------------------------------------------------
-- Daily News Center
-- ---------------------------------------------------------------------------
create table if not exists public.blog_news_import_batches (
  id uuid primary key default gen_random_uuid(),
  batch_date date not null,
  raw_content text not null,
  total_count integer not null default 0 check (total_count >= 0),
  accepted_count integer not null default 0 check (accepted_count >= 0),
  duplicate_count integer not null default 0 check (duplicate_count >= 0),
  rejected_count integer not null default 0 check (rejected_count >= 0),
  status text not null default 'draft'
    check (status in ('draft', 'reviewed', 'completed', 'failed')),
  imported_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.blog_news_articles (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid references public.blog_news_import_batches(id) on delete set null,
  content_type text not null default 'article'
    check (content_type in ('article', 'daily_briefing')),
  title text not null check (length(trim(title)) > 0),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  news_date date not null,
  category text not null,
  source_name text not null,
  source_url text not null check (source_url ~* '^https?://'),
  summary text not null,
  content text not null,
  keywords text[] not null default '{}',
  status text not null default 'draft'
    check (status in ('draft', 'published', 'archived')),
  is_featured boolean not null default false,
  published_at timestamptz,
  author_id uuid references auth.users(id) on delete set null,
  duplicate_of uuid references public.blog_news_articles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint blog_news_published_at_required
    check (status <> 'published' or published_at is not null)
);

-- ---------------------------------------------------------------------------
-- Website settings
-- Public settings may be read by visitors. Private settings are admin-only.
-- Never store API secrets, service-role keys, or deployment tokens here.
-- ---------------------------------------------------------------------------
create table if not exists public.blog_site_settings (
  setting_key text primary key check (setting_key ~ '^[a-z][a-z0-9_.-]*$'),
  setting_value jsonb not null,
  is_public boolean not null default false,
  description text not null default '',
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Media library metadata. Actual binary files live in Supabase Storage.
-- ---------------------------------------------------------------------------
create table if not exists public.blog_media (
  id uuid primary key default gen_random_uuid(),
  storage_bucket text not null default 'blog-media',
  storage_path text not null unique,
  file_name text not null,
  mime_type text not null,
  file_size_bytes bigint not null check (file_size_bytes >= 0),
  width integer check (width is null or width > 0),
  height integer check (height is null or height > 0),
  alt_text text not null default '',
  caption text not null default '',
  folder text not null default 'uploads',
  status text not null default 'active' check (status in ('active', 'archived')),
  uploaded_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.blog_posts
  drop constraint if exists blog_posts_cover_image_id_fkey;
alter table public.blog_posts
  add constraint blog_posts_cover_image_id_fkey
  foreign key (cover_image_id) references public.blog_media(id) on delete set null;

-- ---------------------------------------------------------------------------
-- Audit log. Rows are append-only for browser roles.
-- The application/server workflow must write an audit row for each mutation.
-- ---------------------------------------------------------------------------
create table if not exists public.blog_audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id) on delete set null,
  action text not null check (action in (
    'create', 'update', 'delete', 'publish', 'unpublish',
    'upload', 'archive', 'restore', 'settings_update', 'login'
  )),
  entity_type text not null,
  entity_id text,
  summary text not null default '',
  before_data jsonb,
  after_data jsonb,
  request_id text,
  created_at timestamptz not null default now()
);

create index if not exists idx_blog_posts_publication
  on public.blog_posts(status, published_at desc);
create index if not exists idx_blog_posts_category
  on public.blog_posts(category_id, status);
create index if not exists idx_blog_news_publication
  on public.blog_news_articles(status, news_date desc, published_at desc);
create index if not exists idx_blog_news_category_date
  on public.blog_news_articles(category, news_date desc);
create index if not exists idx_blog_news_batch
  on public.blog_news_import_batches(batch_date desc, created_at desc);
create index if not exists idx_blog_media_folder
  on public.blog_media(folder, created_at desc);
create index if not exists idx_blog_audit_created
  on public.blog_audit_logs(created_at desc);
create index if not exists idx_blog_audit_entity
  on public.blog_audit_logs(entity_type, entity_id, created_at desc);

-- updated_at maintenance
create or replace function public.blog_set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

do $$
declare
  tbl text;
begin
  foreach tbl in array array[
    'blog_categories', 'blog_posts', 'blog_news_import_batches',
    'blog_news_articles', 'blog_site_settings', 'blog_media'
  ]
  loop
    execute format('drop trigger if exists %I on public.%I', 'trg_' || tbl || '_updated_at', tbl);
    execute format(
      'create trigger %I before update on public.%I for each row execute function public.blog_set_updated_at()',
      'trg_' || tbl || '_updated_at', tbl
    );
  end loop;
end;
$$;

-- Make audit rows immutable through normal table operations.
create or replace function public.blog_reject_audit_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'blog_audit_logs is append-only';
end;
$$;

drop trigger if exists trg_blog_audit_no_update_delete on public.blog_audit_logs;
create trigger trg_blog_audit_no_update_delete
before update or delete on public.blog_audit_logs
for each row execute function public.blog_reject_audit_mutation();

-- ---------------------------------------------------------------------------
-- RLS and grants
-- ---------------------------------------------------------------------------
alter table public.blog_admins enable row level security;
alter table public.blog_categories enable row level security;
alter table public.blog_tags enable row level security;
alter table public.blog_posts enable row level security;
alter table public.blog_post_tags enable row level security;
alter table public.blog_news_import_batches enable row level security;
alter table public.blog_news_articles enable row level security;
alter table public.blog_site_settings enable row level security;
alter table public.blog_media enable row level security;
alter table public.blog_audit_logs enable row level security;

revoke all on public.blog_admins, public.blog_categories, public.blog_tags,
  public.blog_posts, public.blog_post_tags, public.blog_news_import_batches,
  public.blog_news_articles, public.blog_site_settings, public.blog_media,
  public.blog_audit_logs from anon, authenticated;

grant select on public.blog_categories, public.blog_tags, public.blog_posts,
  public.blog_post_tags, public.blog_news_articles, public.blog_site_settings,
  public.blog_media to anon, authenticated;
grant select, insert, update, delete on public.blog_categories, public.blog_tags,
  public.blog_posts, public.blog_post_tags, public.blog_news_import_batches,
  public.blog_news_articles, public.blog_site_settings, public.blog_media
  to authenticated;
grant select on public.blog_admins, public.blog_audit_logs to authenticated;
grant insert on public.blog_audit_logs to authenticated;

-- Admin allowlist: no browser write access.
create policy "blog admins can read own allowlist"
  on public.blog_admins for select to authenticated
  using (public.is_blog_admin());

-- Categories and tags: public can read active categories/all tags;
-- all writes require an administrator.
create policy "public reads active blog categories"
  on public.blog_categories for select to anon, authenticated
  using (is_active);
create policy "blog admins read all categories"
  on public.blog_categories for select to authenticated
  using (public.is_blog_admin());
create policy "blog admins manage categories"
  on public.blog_categories for all to authenticated
  using (public.is_blog_admin()) with check (public.is_blog_admin());

create policy "public reads blog tags"
  on public.blog_tags for select to anon, authenticated using (true);
create policy "blog admins manage tags"
  on public.blog_tags for all to authenticated
  using (public.is_blog_admin()) with check (public.is_blog_admin());

-- Public post visibility is limited to published rows.
create policy "public reads published blog posts"
  on public.blog_posts for select to anon, authenticated
  using (status = 'published');
create policy "blog admins read all posts"
  on public.blog_posts for select to authenticated
  using (public.is_blog_admin());
create policy "blog admins insert posts"
  on public.blog_posts for insert to authenticated
  with check (public.is_blog_admin());
create policy "blog admins update posts"
  on public.blog_posts for update to authenticated
  using (public.is_blog_admin()) with check (public.is_blog_admin());
create policy "blog admins delete posts"
  on public.blog_posts for delete to authenticated
  using (public.is_blog_admin());

create policy "public reads tags on published posts"
  on public.blog_post_tags for select to anon, authenticated
  using (exists (
    select 1 from public.blog_posts p
    where p.id = post_id and p.status = 'published'
  ));
create policy "blog admins manage post tags"
  on public.blog_post_tags for all to authenticated
  using (public.is_blog_admin()) with check (public.is_blog_admin());

-- News
create policy "public reads published blog news"
  on public.blog_news_articles for select to anon, authenticated
  using (status = 'published');
create policy "blog admins read all blog news"
  on public.blog_news_articles for select to authenticated
  using (public.is_blog_admin());
create policy "blog admins manage blog news"
  on public.blog_news_articles for all to authenticated
  using (public.is_blog_admin()) with check (public.is_blog_admin());

create policy "blog admins read import batches"
  on public.blog_news_import_batches for select to authenticated
  using (public.is_blog_admin());
create policy "blog admins create import batches"
  on public.blog_news_import_batches for insert to authenticated
  with check (public.is_blog_admin() and imported_by = (select auth.uid()));
create policy "blog admins update import batches"
  on public.blog_news_import_batches for update to authenticated
  using (public.is_blog_admin()) with check (public.is_blog_admin());

-- Site settings: public subset only; private settings are never exposed.
create policy "public reads public site settings"
  on public.blog_site_settings for select to anon, authenticated
  using (is_public);
create policy "blog admins read all site settings"
  on public.blog_site_settings for select to authenticated
  using (public.is_blog_admin());
create policy "blog admins manage site settings"
  on public.blog_site_settings for all to authenticated
  using (public.is_blog_admin()) with check (public.is_blog_admin());

-- Media metadata
create policy "public reads active blog media metadata"
  on public.blog_media for select to anon, authenticated
  using (status = 'active');
create policy "blog admins manage media metadata"
  on public.blog_media for all to authenticated
  using (public.is_blog_admin()) with check (public.is_blog_admin());

-- Audit logs: admin read/append only. Updates/deletes are blocked by grants and trigger.
create policy "blog admins read audit logs"
  on public.blog_audit_logs for select to authenticated
  using (public.is_blog_admin());
create policy "blog admins append audit logs"
  on public.blog_audit_logs for insert to authenticated
  with check (public.is_blog_admin() and actor_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- Supabase Storage bucket and object policies
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'blog-media', 'blog-media', true, 10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/avif']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "public reads blog media objects" on storage.objects;
create policy "public reads blog media objects"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'blog-media');

drop policy if exists "blog admins upload media objects" on storage.objects;
create policy "blog admins upload media objects"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'blog-media' and public.is_blog_admin());

drop policy if exists "blog admins update media objects" on storage.objects;
create policy "blog admins update media objects"
  on storage.objects for update to authenticated
  using (bucket_id = 'blog-media' and public.is_blog_admin())
  with check (bucket_id = 'blog-media' and public.is_blog_admin());

drop policy if exists "blog admins delete media objects" on storage.objects;
create policy "blog admins delete media objects"
  on storage.objects for delete to authenticated
  using (bucket_id = 'blog-media' and public.is_blog_admin());

-- Bootstrap the first administrator after creating the Auth user:
-- insert into public.blog_admins (user_id, display_name)
-- values ('YOUR_AUTH_USER_UUID', 'Site Administrator');
--
-- Audit note: the application must append a blog_audit_logs row for each
-- successful mutation. For stronger guarantees, route mutations through
-- trusted server-side functions and write the audit row in the same transaction.
