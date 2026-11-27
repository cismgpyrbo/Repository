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
