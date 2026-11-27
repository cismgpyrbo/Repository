# 拾光誌 — Supabase Database & Security Specification

## Scope
This schema coexists with other applications in the same Supabase project. It creates only `blog_*` objects and does not alter existing `acc_*`, `checkin_*`, `maocheng_*`, or `shareholders` objects.

## Tables
| Table | Purpose |
|---|---|
| `blog_admins` | Site administrator allowlist and role |
| `blog_posts` | Blog articles, drafts and published posts |
| `blog_categories` | Post categories |
| `blog_tags` | Tags |
| `blog_post_tags` | Post/tag relation |
| `blog_news_import_batches` | Raw Meta AI paste batches and import counts |
| `blog_news_articles` | Daily briefings and individual news items |
| `blog_site_settings` | Public/private website configuration |
| `blog_media` | Media metadata; binary files are stored in Supabase Storage |
| `blog_audit_logs` | Append-only administrative activity log |

## Website settings
Use `is_public = true` only for non-sensitive settings needed by the public site (site title, description, public social links, theme values). Private settings remain administrator-only. Never store Supabase service-role/secret keys, GitHub tokens, passwords, or deployment secrets in this table.

## Media library
Binary files use the public Supabase Storage bucket `blog-media`; the `blog_media` table stores metadata, alt text, caption, folder, dimensions and storage path. The bucket allows common web image formats and limits each file to 10 MiB. Public read is intentional for published website imagery; upload, update and delete require a user in `blog_admins`.

## Audit log
Browser roles can read and append audit rows only when authenticated as an administrator. Update/delete privileges are not granted, and a trigger rejects updates/deletes. The application must create an audit row for every successful mutation. For stronger integrity, perform sensitive writes through trusted server-side functions and write the data change and audit row in the same transaction; client-generated audit rows alone are not tamper-proof against a compromised administrator session.

## Security model
- Anonymous visitors can read published posts/news, active categories/media metadata, tags used by published posts, public settings, and public media objects.
- Only users listed in `blog_admins` can manage site content and settings.
- The first administrator must be inserted manually through Supabase SQL Editor after creating an Auth user.
- Never expose a service-role/secret key in browser code, GitHub Pages output, or public repository files.
- This is a new namespace. Do not change existing project-wide RLS policies as part of this migration.

## Publishing
Draft save and publish are separate actions. Published rows must have `published_at`. After a successful publish/update, request a static-site rebuild through a protected server-side workflow. A failed rebuild must be visible to the administrator.

## Apply order
1. Back up the existing Supabase project and verify the project reference.
2. Create the administrator in Supabase Auth.
3. Apply `supabase/migrations/202611270001_create_blog_platform.sql` in SQL Editor.
4. Insert the first administrator UUID into `blog_admins` using the bootstrap SQL comment.
5. Test anon, authenticated non-admin and authenticated admin permissions.
6. Connect the Astro site only after the access tests pass.
