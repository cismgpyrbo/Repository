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
