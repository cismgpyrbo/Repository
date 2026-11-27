export type Post = {
  slug: string;
  title: string;
  excerpt: string;
  category: string;
  date: string;
  readTime: string;
  cover: string;
  featured?: boolean;
  content: string[];
};

export const posts: Post[] = [
  {
    slug: 'slow-living-in-the-city',
    title: '在城市裡，練習把生活過慢一點',
    excerpt: '留一點空白給自己，讓日常不只是待辦清單，也能重新感受到季節與生活的細節。',
    category: '生活隨筆',
    date: '2026-11-20',
    readTime: '5 分鐘閱讀',
    cover: 'https://images.unsplash.com/photo-1449247709967-d4461a6a6103?auto=format&fit=crop&w=1400&q=85',
    featured: true,
    content: [
      '生活的速度，常常不是由我們真正想做的事情決定，而是被訊息、行程與各種提醒推著向前。',
      '我開始嘗試在一天裡留下一小段沒有安排的時間。散步時不急著抵達目的地，喝咖啡時不急著拿起手機，讓注意力回到眼前。',
      '慢下來並不代表停滯，而是重新選擇什麼值得花時間。'
    ]
  },
  {
    slug: 'notes-from-a-small-desk',
    title: '一張小書桌，和重新開始的勇氣',
    excerpt: '整理桌面，也整理思緒。從一個小小的角落開始，建立可以持續的工作節奏。',
    category: '工作與創作',
    date: '2026-11-16',
    readTime: '4 分鐘閱讀',
    cover: 'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=1200&q=85',
    content: [
      '桌面不需要很大，但需要讓人願意坐下來。把不常用的物品收起來，只留下正在進行的事情。',
      '新的開始不一定要有盛大的儀式。有時候，整理好桌面、打開文件，寫下第一行字，就已經足夠。'
    ]
  },
  {
    slug: 'reading-and-remembering',
    title: '閱讀之後，如何留下真正重要的東西',
    excerpt: '筆記不是把每一句話都抄下來，而是找出那些能與自己經驗連結的想法。',
    category: '閱讀札記',
    date: '2026-11-10',
    readTime: '6 分鐘閱讀',
    cover: 'https://images.unsplash.com/photo-1507842217343-583bb7270b66?auto=format&fit=crop&w=1200&q=85',
    content: [
      '讀完一本書後，我不再要求自己記住所有內容，而是試著回答三個問題：哪個觀點讓我停下來？它和我的生活有什麼關係？我接下來想做什麼？',
      '能夠改變一個小習慣的想法，往往比記住一整本書更有價值。'
    ]
  },
  {
    slug: 'digital-tools-and-focus',
    title: '工具愈多，愈需要知道自己要去哪裡',
    excerpt: '數位工具可以節省時間，但真正重要的仍然是清楚的目標與穩定的習慣。',
    category: '數位生活',
    date: '2026-11-02',
    readTime: '7 分鐘閱讀',
    cover: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=1200&q=85',
    content: [
      '工具能降低執行成本，卻無法替我們決定方向。當工具愈來愈多，管理工具本身也可能變成新的工作。',
      '選擇少數真正符合流程的工具，並定期檢查它們是否仍然有幫助，比追逐每一個新功能更重要。'
    ]
  }
];

export const categories = ['生活隨筆', '工作與創作', '閱讀札記', '數位生活'];