export type NewsArticle = {
  slug: string;
  title: string;
  newsDate: string;
  category: string;
  sourceName: string;
  sourceUrl: string;
  summary: string;
  content: string[];
  keywords: string[];
  publishedAt: string;
};

 // UI demonstration data only. Replace with reviewed Meta AI imports after database integration.
export const newsArticles: NewsArticle[] = [
  {
    slug: 'sample-ai-news-workflow',
    title: '每日新聞中心即將啟用：示範新聞資料',
    newsDate: '2026-11-27',
    category: '科技',
    sourceName: '示範資料，非真實新聞',
    sourceUrl: 'https://example.com/',
    summary: '這是一筆用來展示新聞列表、分類與詳細閱讀頁面的示範資料，並非真實新聞報導。',
    content: [
      '目前拾光誌正在建置每日新聞中心。正式上線後，管理者可以將 Meta AI 每日整理的新聞貼入後台，系統會協助拆分欄位並檢查資料。',
      '新聞發布前仍會經過人工預覽與確認。每則新聞會保留原始媒體名稱及來源網址，讀者可前往原始報導查閱。',
      '本頁文字僅供介面展示，不代表任何實際新聞事件。'
    ],
    keywords: ['每日新聞', '網站功能', '示範資料'],
    publishedAt: '2026-11-27'
  }
];
