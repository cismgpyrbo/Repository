-- Daily News Center schema v1
-- Apply in Supabase SQL Editor after reviewing the project ref and backup.
-- This migration creates tables and RLS policies only; it does not publish or import news.

create extension if not exists pgcrypto;

create table if not exists public.news_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now()
);

create table if not exists public.news_import_batches (
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

create table if not exists public.news_articles (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid references public.news_import_batches(id) on delete set null,
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
  duplicate_of uuid references public.news_articles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint news_published_at_required
    check (status <> 'published' or published_at is not null)
);

create index if not exists idx_news_articles_status_date
  on public.news_articles(status, news_date desc, published_at desc);
create index if not exists idx_news_articles_category_date
  on public.news_articles(category, news_date desc);
create index if not exists idx_news_articles_batch_id
  on public.news_articles(batch_id);
create index if not exists idx_news_articles_source_url
  on public.news_articles(lower(source_url));
create index if not exists idx_news_import_batches_date
  on public.news_import_batches(batch_date desc, created_at desc);

create or replace function public.is_news_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.news_admins
    where user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_news_admin() from public;
grant execute on function public.is_news_admin() to authenticated;

alter table public.news_admins enable row level security;
alter table public.news_import_batches enable row level security;
alter table public.news_articles enable row level security;

revoke all on public.news_admins from anon, authenticated;
revoke all on public.news_import_batches from anon, authenticated;
revoke all on public.news_articles from anon, authenticated;

grant select on public.news_articles to anon, authenticated;
grant select, insert, update, delete on public.news_articles to authenticated;
grant select, insert, update on public.news_import_batches to authenticated;
grant select on public.news_admins to authenticated;

drop policy if exists "news public reads published articles" on public.news_articles;
create policy "news public reads published articles"
  on public.news_articles for select
  to anon, authenticated
  using (status = 'published');

drop policy if exists "news admins read all articles" on public.news_articles;
create policy "news admins read all articles"
  on public.news_articles for select
  to authenticated
  using (public.is_news_admin());

drop policy if exists "news admins insert articles" on public.news_articles;
create policy "news admins insert articles"
  on public.news_articles for insert
  to authenticated
  with check (public.is_news_admin());

drop policy if exists "news admins update articles" on public.news_articles;
create policy "news admins update articles"
  on public.news_articles for update
  to authenticated
  using (public.is_news_admin())
  with check (public.is_news_admin());

drop policy if exists "news admins delete articles" on public.news_articles;
create policy "news admins delete articles"
  on public.news_articles for delete
  to authenticated
  using (public.is_news_admin());

drop policy if exists "news admins read import batches" on public.news_import_batches;
create policy "news admins read import batches"
  on public.news_import_batches for select
  to authenticated
  using (public.is_news_admin());

drop policy if exists "news admins create import batches" on public.news_import_batches;
create policy "news admins create import batches"
  on public.news_import_batches for insert
  to authenticated
  with check (public.is_news_admin() and imported_by = (select auth.uid()));

drop policy if exists "news admins update import batches" on public.news_import_batches;
create policy "news admins update import batches"
  on public.news_import_batches for update
  to authenticated
  using (public.is_news_admin())
  with check (public.is_news_admin());

drop policy if exists "news admins read admin allowlist" on public.news_admins;
create policy "news admins read admin allowlist"
  on public.news_admins for select
  to authenticated
  using (public.is_news_admin());

-- Bootstrap the first administrator manually after creating the Auth user:
-- insert into public.news_admins (user_id, display_name)
-- values ('YOUR_AUTH_USER_UUID', 'Site Administrator');
