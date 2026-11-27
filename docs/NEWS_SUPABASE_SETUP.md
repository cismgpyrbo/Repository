# News Center Database Setup

1. Confirm this is the intended Supabase project and create a database backup.
2. Create the administrator account in Supabase Auth.
3. Open Supabase SQL Editor and apply `supabase/migrations/202611270001_create_news_tables.sql`.
4. Copy the administrator's Auth user UUID and run the bootstrap INSERT at the bottom of the migration.
5. Test with anon and authenticated sessions before connecting the website.

Important: this repository change only adds SQL and documentation. It does not connect to or modify your live Supabase project.
