# 拾光誌｜個人部落格

個人部落格與每日新聞中心 UI Prototype，使用 Astro 建置，部署目標為 GitHub Pages，網站完成後再轉移至 Netlify。

## 技術
- Astro 5 + TypeScript
- 響應式 CSS
- React integration（預留互動元件）
- GitHub Pages（目前預覽）
- Supabase（下一階段整合，尚未連線）

## 本機啟動

```bash
npm install
npm run dev
```

## 網站頁面
- `/`：首頁
- `/blog/`：文章列表
- `/blog/[slug]/`：文章詳情
- `/news/`：每日新聞列表
- `/news/[slug]/`：新聞整理詳情與原始來源連結
- `/admin/`：管理儀表板
- `/admin/posts/`：文章管理 UI
- `/admin/news/`：新聞管理 UI
- `/admin/news/import/`：貼上及解析 Meta AI 新聞

## 每日新聞匯入格式

Meta AI 每則新聞建議使用以下固定欄位：

```text
## 新聞 1
- 新聞標題：
- 新聞日期：
- 新聞分類：
- 新聞來源：
- 原始新聞網址：
- 新聞摘要：
- 詳細新聞整理：
- 重要關鍵字：
```

可一次貼上多則新聞。管理者應先檢查內容及來源，再決定發布。

## 目前原型限制
- 所有新聞及文章均為示範資料。
- 新聞匯入解析目前只在瀏覽器端示範，不會寫入資料庫。
- 新聞發布按鈕不會真的發布或觸發部署。
- 後台尚未接 Supabase Auth、RLS 或 Storage。
- 正式版將以 Supabase 儲存新聞，透過受保護的發布流程觸發 GitHub Actions 重新建置。
- 不應將新聞媒體的整篇原文直接複製發布；應使用自行整理的摘要與內容，並清楚標示來源及原文連結。


## Supabase 資料庫規劃

本專案沿用既有 Supabase 專案，所有本專案資料庫物件統一使用 `blog_*` 前綴，與同一 Supabase 專案中的其他系統隔離。

Migration：
- `supabase/migrations/202611270001_create_blog_platform.sql`

預計建立：
- `blog_admins`、`blog_posts`、`blog_categories`、`blog_tags`、`blog_post_tags`
- `blog_news_import_batches`、`blog_news_articles`
- `blog_site_settings`：網站公開/私有設定
- `blog_media`：圖片中繼資料；實際圖片存放於 Supabase Storage 的 `blog-media` bucket
- `blog_audit_logs`：管理者操作紀錄

**注意：** Migration 已提交至 GitHub，但尚未在 Supabase SQL Editor 執行；網站目前也尚未連接 Supabase。執行前請先備份資料庫並確認專案參照碼。
