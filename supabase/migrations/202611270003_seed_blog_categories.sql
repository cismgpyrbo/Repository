-- Seed initial categories for 拾光誌.
-- Safe to run more than once; existing category rows are preserved.
BEGIN;
INSERT INTO public.blog_categories (name, slug, description, sort_order, is_active)
VALUES
 ('生活隨筆', 'life-notes', '生活觀察與日常紀錄', 10, true),
 ('工作與創作', 'work-and-creation', '工作方法、創作過程與專案紀錄', 20, true),
 ('閱讀札記', 'reading-notes', '書籍閱讀與觀點整理', 30, true),
 ('數位生活', 'digital-life', '數位工具、科技與生活應用', 40, true)
ON CONFLICT (slug) DO NOTHING;
COMMIT;
