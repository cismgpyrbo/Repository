# 拾光誌｜個人部落格

個人部落格與每日新聞中心，使用 Astro 建置，部署於 GitHub Pages，後續可再轉移至 Netlify。

## 技術

- Astro 5 + TypeScript
- 響應式 CSS
- React integration（互動元件預留）
- GitHub Pages（目前網站）
- Supabase Auth、Postgres、Storage（內容與管理資料）

## 本機啟動

```bash
npm install
npm run dev
```

## 網站頁面

- `/`：首頁
- `/blog/`：文章列表
- `/blog/[slug]/`：文章詳情
- `/news/`：每日新聞列表（即時讀取 Supabase 已發布內容）
- `/news/?slug=文章slug`：每日新聞摘要詳情
- `/admin/`：管理儀表板
- `/admin/posts/`：文章管理 UI
- `/admin/news/`：新聞管理（讀取 Supabase 新聞資料）
- `/admin/news/import/`：Meta AI 新聞格式解析原型

## 每日新聞資料流程

每日新聞摘要由排程產生，完成來源核實與發布前檢查後，寫入 Supabase：

- 專案：`aaynitbvfhxttrmlmvlf`
- 資料表：`public.blog_news_articles`
- 每日總覽使用 `content_type = 'daily_briefing'`
- `status = 'published'` 的內容會顯示於公開的 `/news/` 頁面
- 同一天使用 `YYYY-MM-DD-daily-briefing` 作為 slug，避免重複建立
- 公開訪客僅能讀取已發布新聞；管理者權限由 Supabase Auth、`blog_admins` 與 RLS 控制
- 每次自動發布會寫入 `blog_audit_logs`

網站每日新聞頁面在瀏覽器端使用 Supabase publishable key 讀取資料，資料讀取權限由 RLS 限制為已發布內容。publishable key 可用於前端；禁止將 Supabase secret 或 service_role key 放入前端或 GitHub。

**每日新聞內容寫入資料庫後，不需要為每篇新聞重新部署 GitHub Pages。** GitHub Pages 部署只在網站程式碼更新時執行。

## 新聞來源與內容原則

- 新聞內容使用自行整理的摘要與分析，不複製新聞媒體整篇原文。
- 保留來源名稱與原始新聞 HTTPS 連結。
- 已發布內容才會公開顯示；草稿與封存內容不會出現在訪客頁面。
- 每日新聞匯入頁目前仍是格式解析原型，尚未完成手動匯入資料庫的 CRUD 流程。

## Supabase 資料庫

本專案沿用既有 Supabase 專案，網站資料表統一使用 `blog_*` 前綴，與同一專案中的其他系統隔離。不得在本專案功能中修改非 `blog_*` 資料表。

Migration：

- `supabase/migrations/202611270001_create_blog_platform.sql`

主要資料表：

- `blog_admins`：管理者白名單
- `blog_posts`、`blog_categories`、`blog_tags`、`blog_post_tags)：一般部落格文章
- `blog_news_import_batches)、`blog_news_articles)：每日新聞與匯入批次
- `blog_site_settings)：網站設定
- `blog_media)：圖片中繼資料；實際圖片存放於 Supabase Storage 的 `blog-media` bucket
- `blog_audit_logs)：管理操作紀錄
