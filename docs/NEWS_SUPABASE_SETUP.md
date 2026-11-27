# 拾光誌 Supabase 設定與部署

## 目標專案
沿用既有 Supabase 專案（Project Ref: `aaynitbvfhxttrmlmvlf`）。此專案同時承載其他系統；本次 Migration 僅建立 `blog_*` 資料表、函式、政策及 `blog-media` Storage bucket，不應更動既有 `acc_*`、`checkin_*`、`maocheng_*` 或 `shareholders` 物件。

## 執行前
1. 在 Supabase Dashboard 確認專案參照碼為 `aaynitbvfhxttrmlmvlf`。
2. 建立資料庫備份。
3. 在 Authentication > Users 建立網站管理者帳號。
4. 不要將資料庫密碼、service-role/secret key 貼到聊天或放入 GitHub。

## 執行 Migration
1. 開啟 SQL Editor > New query。
2. 開啟 GitHub 專案中的 `supabase/migrations/202611270001_create_blog_platform.sql`。
3. 複製完整 SQL，貼入 SQL Editor。
4. 執行後確認所有 `blog_*` 資料表與 `blog-media` Storage bucket 已建立。
5. 取得剛建立的 Auth 使用者 UUID，在 SQL Editor 執行 Migration 最後的 bootstrap INSERT 範例（填入自己的 UUID）。

## 權限驗證
- 未登入訪客只能讀取已發布文章/新聞、公開網站設定及啟用中的圖片資料。
- 未列入 `blog_admins` 的登入使用者不得管理內容。
- 管理者可管理文章、新聞、分類、標籤、設定及圖片。
- 操作紀錄只允許管理者讀取及新增；一般瀏覽器角色不可更新或刪除。
- Storage 的 `blog-media` 可公開讀取；只有管理者可上傳、更新、刪除。
- 測試期間不得修改其他專案資料表或政策。

## 重要限制
此 GitHub Migration 是 SQL 原始檔，提交到 GitHub 不會自動執行到 Supabase。執行前請先備份並檢查 SQL；本次建立檔案不會連線或修改線上資料庫。

## 部署前物件衝突檢查

在執行 Migration 前，先於 SQL Editor 執行以下唯讀查詢，確認沒有同名資料表或函式：

```sql
select 'table' as object_type, table_name as object_name
from information_schema.tables
where table_schema = 'public'
  and table_name like 'blog_%'
union all
select 'function' as object_type, routine_name as object_name
from information_schema.routines
where routine_schema = 'public'
  and routine_name in ('is_blog_admin', 'blog_set_updated_at', 'blog_reject_audit_mutation')
order by object_type, object_name;
```

若查詢有結果，先不要執行 Migration，應先確認這些物件是否屬於本專案及是否已有資料。此查詢不會修改資料庫。

## Migration 執行注意事項（重要）

此版本 Migration 請視為**首次部署的一次性腳本**，不要在成功執行後再次整份執行。雖然部分物件使用 `IF NOT EXISTS`，但資料表約束與 RLS policies 並非全部可安全重複建立；中途失敗後直接重跑可能遇到「policy already exists」或「constraint already exists」等錯誤。

若第一次執行發生錯誤：
1. 不要立即重新執行整份 SQL。
2. 保留 SQL Editor 的完整錯誤訊息與執行結果。
3. 先查明哪些資料表、函式、trigger、policy、Storage bucket 已建立。
4. 依實際狀態製作修復 SQL；不要直接刪除整個 `blog_*` 命名空間，除非已確認沒有需要保留的資料。

本次部署前已確認：
- `public` schema 沒有 `blog_*` 資料表或本 Migration 的三個函式。
- `storage.buckets` 沒有 `blog-media` bucket。

執行前仍須完成備份，並確認 Dashboard 的 Project Ref 為 `aaynitbvfhxttrmlmvlf`。Migration 執行成功後，才使用 Auth 使用者 UUID 執行第一位管理者 bootstrap INSERT。


## 手動新聞匯入（2026-11-27）

- 管理者由 `/admin/news/import/` 貼上 Meta AI 原始輸出，支援英文/中文欄位與 `---` 多則分隔。
- 解析器檢查必要欄位、日期、HTTP(S) 來源網址、疑似範例網址及本批次 slug 重複。
- 每日新聞總覽會以 `content_type='daily_briefing'` 匯入；其他內容為 `article`。
- 按下匯入後，前端先用 Supabase Auth 驗證使用者並查詢 `blog_admins`；資料庫 RPC `blog_import_news_batch` 會再次驗證管理者權限。
- RPC 使用 SECURITY INVOKER，在單一交易中建立 `blog_news_import_batches` 批次並新增 `blog_news_articles`。slug 重複會略過；任何資料庫錯誤會使整批交易回滾。
- 手動匯入文章一律先存為 `draft`，不會直接公開。管理者在 `/admin/news/` 檢查後可逐篇發布或撤回為草稿。
- 匯入批次紀錄顯示總數、新增、重複、未匯入數量；資料庫 audit triggers 自動追蹤批次與新聞資料列異動。
- Migration：`supabase/migrations/202611270004_blog_manual_news_import.sql`。此 Migration 已在目前 Supabase 專案以 SQL 執行，GitHub 檔案用於版本控管。
