# Database Optimization va Tartibga Keltirish

## Hozirgi Database Holati

### Asosiy Jadvallar

1. **profiles** - Foydalanuvchilar ma'lumotlari
   - `id`, `email`, `name`, `role`, `xp`, `level`, `streak_days`
   - `student_id` (5 raqamli: 25001)
   - `student_number` (13 raqamli HEMIS ID)
   - `phone`, `faculty`, `student_group`, `course`, `education_form`, `specialty`, `gpa`
   - `hemis_id`, `hemis_login`, `last_synced_at`

2. **books** - Kitoblar
   - `id`, `title`, `author`, `isbn`, `category`, `description`
   - `cover_url`, `cover_color`, `file_url`, `pdf_url`
   - `rating`, `pages`, `total_pages`, `year`, `language`
   - `views_count`, `book_type` (online/offline/both)

3. **physical_book_copies** - Fizik kitob nusxalari
   - `id`, `book_id`, `barcode`, `copy_number`, `status`
   - `location`, `notes`

4. **book_checkouts** - Kitob qarz olish/qaytarish
   - `id`, `physical_copy_id`, `user_id`, `librarian_id`
   - `checked_out_at`, `due_date`, `returned_at`, `status`

5. **user_progress** - o'qish jarayoni
   - `id`, `user_id`, `book_id`, `progress_percentage`
   - `last_read_at`, `current_page`

6. **achievements** - Yutuqlar
   - `id`, `key`, `title`, `description`, `icon`, `xp_reward`, `tier`

7. **reading_schedule** - o'qish jadvali
   - `id`, `user_id`, `book_id`, `start_date`, `end_date`, `daily_pages_goal`

8. **daily_progress** - Kunlik progress
   - `id`, `schedule_id`, `date`, `pages_read`, `completed`

### Mavjud Index'lar

✅ **Profiles:**
- `idx_profiles_role`
- `idx_profiles_email`
- `idx_profiles_student_number`
- `idx_profiles_student_id`
- `idx_profiles_hemis_id`
- `idx_profiles_hemis_login`
- `idx_profiles_xp`
- `idx_profiles_streak`
- `idx_profiles_leaderboard` (composite: xp DESC, streak_days DESC)

✅ **Book Checkouts:**
- `idx_book_checkouts_status`
- `idx_book_checkouts_user_id`
- `idx_book_checkouts_due_date`
- `idx_book_checkouts_physical_copy_id`
- `idx_checkouts_user_status` (composite)

✅ **Books:**
- `idx_books_category`
- `idx_books_book_type`
- `idx_books_title`
- `idx_books_author`
- `idx_books_rating`
- `idx_books_created`
- `idx_books_title_search` (text search)
- `idx_books_author_search` (text search)

✅ **Physical Book Copies:**
- `idx_physical_copies_book_id`
- `idx_physical_copies_status`
- `idx_physical_copies_barcode`

✅ **User Progress:**
- `idx_user_progress_user_id`
- `idx_user_progress_book_id`
- `idx_user_progress_user_book` (composite)
- `idx_user_progress_last_read`

## Qo'shimcha Optimizatsiyalar

### 1. Keraksiz Index'larni Olib Tashlash

```sql
-- Duplicate index'lar (composite index mavjud bo'lsa, single index kerak emas)
-- Lekin bizda duplicate'lar yo'q, hammasi kerakli
```

### 2. Qo'shimcha Kerakli Index'lar

```sql
-- Checker page uchun (student_number yoki student_id bilan qidirish)
-- ✅ Allaqachon mavjud

-- Library page uchun (cover_url NULL emas filter)
CREATE INDEX IF NOT EXISTS idx_books_cover_url_not_null 
ON books(id) WHERE cover_url IS NOT NULL;

-- Book checkouts uchun (checked_out_at bilan filter)
CREATE INDEX IF NOT EXISTS idx_book_checkouts_checked_out_at 
ON book_checkouts(checked_out_at DESC);

-- Daily progress uchun (date range queries)
CREATE INDEX IF NOT EXISTS idx_daily_progress_user_date 
ON daily_progress(schedule_id, date DESC);
```

### 3. Query Optimizatsiyalari

#### Checker Page - Student Search
```sql
-- Hozirgi query (YAXSHI ✅)
SELECT id, name, email, student_id, student_number, avatar_url, xp, 
       phone, faculty, student_group, course, education_form, specialty, gpa
FROM profiles
WHERE student_number = '25001' OR student_id = '25001'
LIMIT 1;

-- Index ishlatadi: idx_profiles_student_number, idx_profiles_student_id
```

#### Checker Page - Active Loans
```sql
-- Hozirgi query (OPTIMALLASHTIRILGAN ✅)
SELECT 
    bc.id,
    bc.due_date,
    bc.checked_out_at,
    pbc.barcode,
    pbc.copy_number,
    b.title,
    b.author,
    b.cover_color
FROM book_checkouts bc
INNER JOIN physical_book_copies pbc ON bc.physical_copy_id = pbc.id
INNER JOIN books b ON pbc.book_id = b.id
WHERE bc.user_id = $1
  AND bc.status = 'active'
ORDER BY bc.due_date ASC;

-- Index ishlatadi: idx_checkouts_user_status (composite)
```

#### Library Page - Books List
```sql
-- Hozirgi query (YAXSHI ✅)
SELECT id, title, author, rating, cover_color, category, cover_url, views_count
FROM books
WHERE cover_url IS NOT NULL  -- Online books only
  AND category = $1  -- Optional filter
ORDER BY created_at DESC
LIMIT 12 OFFSET 0;

-- Yangi index kerak: idx_books_cover_url_not_null
```

### 4. Database Connection Pooling

Supabase automatic connection pooling ishlatadi, lekin biz qo'shimcha optimizatsiya qilishimiz mumkin:

```typescript
// lib/supabase/client.ts
import { createClient } from '@supabase/supabase-js'

export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
    },
    db: {
      schema: 'public',
    },
    global: {
      headers: {
        'x-client-info': 'unilib-web',
      },
    },
  }
)
```

### 5. Query Result Caching

React Query bilan caching:

```typescript
// lib/react-query/client.ts
import { QueryClient } from '@tanstack/react-query'

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000, // 1 minute
      cacheTime: 5 * 60 * 1000, // 5 minutes
      refetchOnWindowFocus: false,
      refetchOnReconnect: false,
      retry: 2,
    },
  },
})
```

### 6. Materialized Views (Agar kerak bo'lsa)

Ko'p ishlatiladigan complex query'lar uchun:

```sql
-- Leaderboard uchun materialized view
CREATE MATERIALIZED VIEW IF NOT EXISTS leaderboard_cache AS
SELECT 
    id,
    name,
    avatar_url,
    xp,
    level,
    streak_days,
    total_books_completed
FROM profiles
WHERE is_active = true
ORDER BY xp DESC, streak_days DESC
LIMIT 100;

-- Index
CREATE INDEX ON leaderboard_cache(xp DESC, streak_days DESC);

-- Refresh function (har 5 daqiqada)
CREATE OR REPLACE FUNCTION refresh_leaderboard_cache()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard_cache;
END;
$$ LANGUAGE plpgsql;
```

### 7. Vacuum va Analyze

Database'ni muntazam tozalash:

```sql
-- Supabase automatic vacuum qiladi, lekin manual ham qilish mumkin
VACUUM ANALYZE profiles;
VACUUM ANALYZE books;
VACUUM ANALYZE book_checkouts;
VACUUM ANALYZE user_progress;
```

## Migration Plan

### Phase 1: Index Optimizatsiyasi (5 daqiqa)

```bash
# Yangi migration yaratish
cd supabase/migrations
```

```sql
-- 20251213_database_optimization.sql
-- Qo'shimcha index'lar
CREATE INDEX IF NOT EXISTS idx_books_cover_url_not_null 
ON books(id) WHERE cover_url IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_book_checkouts_checked_out_at 
ON book_checkouts(checked_out_at DESC);

CREATE INDEX IF NOT EXISTS idx_daily_progress_user_date 
ON daily_progress(schedule_id, date DESC);

-- Analyze tables
ANALYZE profiles;
ANALYZE books;
ANALYZE book_checkouts;
ANALYZE physical_book_copies;
ANALYZE user_progress;
```

### Phase 2: Query Optimizatsiyasi (Frontend) (10 daqiqa)

1. AuthContext - faqat kerakli ustunlarni select qilish ✅
2. Checker page - optimized queries ✅
3. Library page - cover_url filter index ishlatish
4. Dashboard - React Query caching

### Phase 3: Monitoring (5 daqiqa)

```sql
-- Slow query'larni aniqlash
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    max_time
FROM pg_stat_statements
WHERE mean_time > 100  -- 100ms dan ko'proq
ORDER BY mean_time DESC
LIMIT 20;
```

## Performance Metrics

### Before Optimization
- [ ] Checker page student search: ~500ms
- [ ] Library page load: ~800ms
- [ ] Dashboard load: ~1200ms
- [ ] Concurrent users: 10-20

### After Optimization (Target)
- [ ] Checker page student search: <100ms
- [ ] Library page load: <300ms
- [ ] Dashboard load: <500ms
- [ ] Concurrent users: 100+

## Monitoring Commands

```sql
-- Active connections
SELECT count(*) FROM pg_stat_activity;

-- Table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- Unused indexes
SELECT 
    schemaname,
    tablename,
    indexname
FROM pg_stat_user_indexes
WHERE idx_scan = 0
AND schemaname = 'public';
```

## Xulosa

1. ✅ **Index'lar yaxshi** - Barcha kerakli index'lar mavjud
2. ✅ **Query'lar optimallashtirilgan** - Composite index'lar ishlatilmoqda
3. 🔄 **Qo'shimcha optimizatsiya** - 3 ta yangi index qo'shish kerak
4. 🔄 **Caching** - React Query setup qilish kerak
5. 🔄 **Monitoring** - Performance tracking qo'shish kerak

**Keyingi qadam:** Yangi migration yaratish va frontend optimizatsiyasini boshlash.
