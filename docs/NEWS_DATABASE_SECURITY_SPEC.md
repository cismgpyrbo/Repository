# Daily News Center — Supabase Database & Security Specification

## Scope
This specification supports the Meta AI manual-copy workflow. It stores the original pasted batch and parsed news as drafts. No news is public until an administrator explicitly publishes it.

## Tables
- `news_admins`: explicit allowlist of Supabase Auth users permitted to manage news.
- `news_import_batches`: one pasted Meta AI output per import session, including private raw source text and processing counters.
- `news_articles`: one daily briefing or individual news item per row.

## Import mapping
Meta AI fields map as follows:
- `title` → `title`
- `date` → `news_date`
- `category` → `category`
- `source` → `source_name`
- `url` → `source_url`
- `summary` → `summary`
- `detail` → `content`
- optional `keywords` → `keywords`

The first block with category `總覽` or title containing `新聞摘要` should be stored as `content_type = daily_briefing`. Other blocks are `content_type = article`.

## Security
- Anonymous users can only SELECT rows where `status = published`.
- Authenticated users do not automatically become administrators. They must have a row in `news_admins`.
- All insert/update/delete operations require `public.is_news_admin()`.
- The `news_admins` table is not writable by browser roles. Bootstrap the first administrator using the SQL Editor.
- Never expose the Supabase service-role/secret key in the browser or GitHub Pages output.
- Do not store GitHub tokens or deployment secrets in database rows.

## Duplicate handling
Do not hard-reject duplicate source URLs at the database level because syndicated stories may legitimately share URLs or URL parameters may differ. Before saving a batch, compare normalized URLs and titles against existing records and flag possible duplicates for administrator review. The `duplicate_of` field records an administrator-confirmed duplicate relationship.

## Publishing
Draft save and publish are separate actions. Publishing requires an administrator, sets `status = published` and `published_at = now()`, then requests a site rebuild through a protected server-side function. A failed rebuild must be visible to the administrator and must not silently claim success.

## Deployment note
The public website is currently GitHub Pages + Astro static output. Once the database is connected, the GitHub Actions build must fetch only published rows using repository secrets for the Supabase URL and publishable/anon key. The build key is public-read only due to RLS; never use a service-role key in the build. A protected Supabase Edge Function can trigger the GitHub Actions workflow using a narrowly scoped GitHub token stored as an Edge Function secret.

## Apply order
1. Create the Supabase Auth administrator account.
2. Back up the Supabase project and verify the target project.
3. Apply the SQL migration in Supabase SQL Editor.
4. Insert the Auth user UUID into `news_admins` using the bootstrap SQL comment.
5. Test anonymous SELECT (published rows only) and authenticated admin/non-admin access.
6. Only then connect the import UI and publishing workflow.
