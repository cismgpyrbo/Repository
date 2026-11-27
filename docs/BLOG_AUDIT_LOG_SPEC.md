# 拾光誌操作紀錄系統

## 範圍
本功能只使用既有的 `public.blog_audit_logs`，不修改會計系統或其他共用 Supabase 專案資料表。

## 記錄來源
以 PostgreSQL AFTER INSERT / UPDATE / DELETE triggers 自動記錄，不依賴前端是否有呼叫 audit API。涵蓋：
- `blog_posts`：文章建立、修改、刪除、發布、取消發布、封存、還原。
- `blog_media`：圖片上傳、檔案更名、資料夾與 Alt/caption 修改、刪除、封存、還原。
- `blog_news_articles`：新聞建立、修改、刪除、發布、取消發布、封存、還原。
- `blog_news_import_batches`：新聞匯入批次建立、修改、刪除。
- `blog_categories`、`blog_tags`、`blog_post_tags`：分類、標籤及文章標籤關聯異動。

## 欄位
- `actor_id`：Supabase Auth UID；排程/service-role 沒有使用者 JWT 時為 NULL。
- `actor_label`：管理者顯示名稱；無登入使用者的系統工作標記為「系統／排程」。
- `action`：動作代碼。
- `entity_type`、`entity_id`：項目類型及資料列識別碼。
- `summary`：易讀摘要。
- `before_data`、`after_data`：重要欄位異動前後快照。避免保存文章全文、圖片二進位資料或新聞原始匯入全文。
- `request_id`：可取得時記錄 API request id。
- `created_at`：資料庫時間。

## 安全性
- audit table RLS 保持啟用；只有 blog admin 可查詢及新增。
- audit table 原有 append-only trigger 保留，阻止一般 UPDATE / DELETE。
- 自動寫入由固定 search_path、限定用途的 SECURITY DEFINER trigger function 執行；函式不授權給 anon/authenticated 直接呼叫。
- 不將 service-role key 放入前端。
- 刪除資料列也會保留 audit row，entity_id 以文字儲存，不設為目標資料列外鍵。

## 查詢介面
管理後台 `/admin/audit/`，可依項目類型、動作、文字搜尋，查看前後快照。列表讀取最新 1,000 筆並提供頁內分頁。

## 驗收
已對 blog_tags 建立暫存資料列，確認 trigger 自動產生 create audit row，並在同一測試區塊清除測試資料與測試紀錄。已確認 7 組 audit triggers、RLS 及原有 2 條 audit policies。

## 限制
操作紀錄反映資料庫實際完成的異動，不記錄失敗的操作嘗試。Supabase Storage 的物件操作若沒有同步完成 blog_media 中繼資料變更，不會單獨出現 Storage API 事件。新聞管理匯入頁目前仍是解析示範，尚未實際寫入新聞資料庫；在該匯入流程完成資料庫寫入前，不能產生對應的新聞匯入操作紀錄。
