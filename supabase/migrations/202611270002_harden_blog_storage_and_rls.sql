-- Follow-up hardening for the 拾光誌 blog platform.
-- Apply after 202611270001_create_blog_platform.sql.
-- This migration is scoped only to blog_* objects and the blog-media bucket.

BEGIN;

-- The admin check is used by RLS policies, but must not be callable by anon/PUBLIC.
REVOKE EXECUTE ON FUNCTION public.is_blog_admin() FROM PUBLIC, anon;

-- Public website reads published content without creating overlapping
-- authenticated policies. Authenticated admins use the admin policies.
ALTER POLICY "public reads active blog categories" ON public.blog_categories TO anon;
ALTER POLICY "public reads active blog media metadata" ON public.blog_media TO anon;
ALTER POLICY "public reads published blog news" ON public.blog_news_articles TO anon;
ALTER POLICY "public reads tags on published posts" ON public.blog_post_tags TO anon;
ALTER POLICY "public reads published blog posts" ON public.blog_posts TO anon;
ALTER POLICY "public reads public site settings" ON public.blog_site_settings TO anon;
ALTER POLICY "public reads blog tags" ON public.blog_tags TO anon;

-- Redundant SELECT policies; admin ALL policies already cover admin reads.
DROP POLICY IF EXISTS "blog admins read all categories" ON public.blog_categories;
DROP POLICY IF EXISTS "blog admins read all blog news" ON public.blog_news_articles;
DROP POLICY IF EXISTS "blog admins read all site settings" ON public.blog_site_settings;

-- Public bucket: direct image URLs remain public, but object listing and
-- all object mutations are restricted to authenticated blog administrators.
DROP POLICY IF EXISTS "public reads blog media objects" ON storage.objects;
DROP POLICY IF EXISTS "blog admins list media objects" ON storage.objects;
DROP POLICY IF EXISTS "blog admins upload media objects" ON storage.objects;
DROP POLICY IF EXISTS "blog admins update media objects" ON storage.objects;
DROP POLICY IF EXISTS "blog admins delete media objects" ON storage.objects;

CREATE POLICY "blog admins list media objects"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'blog-media' AND public.is_blog_admin());

CREATE POLICY "blog admins upload media objects"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'blog-media' AND public.is_blog_admin());

CREATE POLICY "blog admins update media objects"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'blog-media' AND public.is_blog_admin())
WITH CHECK (bucket_id = 'blog-media' AND public.is_blog_admin());

CREATE POLICY "blog admins delete media objects"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'blog-media' AND public.is_blog_admin());

-- Covering indexes for blog foreign keys.
CREATE INDEX IF NOT EXISTS idx_blog_audit_logs_actor_id ON public.blog_audit_logs (actor_id);
CREATE INDEX IF NOT EXISTS idx_blog_media_uploaded_by ON public.blog_media (uploaded_by);
CREATE INDEX IF NOT EXISTS idx_blog_news_articles_author_id ON public.blog_news_articles (author_id);
CREATE INDEX IF NOT EXISTS idx_blog_news_articles_batch_id ON public.blog_news_articles (batch_id);
CREATE INDEX IF NOT EXISTS idx_blog_news_articles_duplicate_of ON public.blog_news_articles (duplicate_of);
CREATE INDEX IF NOT EXISTS idx_blog_news_import_batches_imported_by ON public.blog_news_import_batches (imported_by);
CREATE INDEX IF NOT EXISTS idx_blog_post_tags_tag_id ON public.blog_post_tags (tag_id);
CREATE INDEX IF NOT EXISTS idx_blog_posts_author_id ON public.blog_posts (author_id);
CREATE INDEX IF NOT EXISTS idx_blog_posts_cover_image_id ON public.blog_posts (cover_image_id);
CREATE INDEX IF NOT EXISTS idx_blog_site_settings_updated_by ON public.blog_site_settings (updated_by);

COMMIT;
