# Database Optimization - Qadamma-Qadam Yo'riqnoma

## 1️⃣ Hozirgi Holatni Tekshirish

### Supabase SQL Editor'da ishga tushiring:

```sql
-- File: supabase/migrations/00_database_analysis.sql
-- Bu script hozirgi database holatini ko'rsatadi
```

**Nima ko'rasiz:**
- ✅ Mavjud jadvallar va ularning hajmi
- ✅ Mavjud index'lar va ularning ishlatilishi
- ❌ Yangi index'lar mavjud yoki yo'qligi
- ❌ Monitoring function'lar mavjud yoki yo'qligi
- 📊 Database hajmi va connection'lar
- 📈 Query performance baseline

---

## 2️⃣ Optimization Migration'ni Ishga Tushirish

### Agar yangi index'lar Yo'Q bo'lsa:

```sql
-- File: supabase/migrations/20251213_database_optimization.sql
-- Bu script 10 ta yangi index va 5 ta monitoring function qo'shadi
```

**Nima qiladi:**
1. **10 ta yangi index** yaratadi:
   - `idx_books_online_only` - Library page tezlashtirish
   - `idx_book_checkouts_checked_out_at` - Today stats
   - `idx_book_checkouts_returned_at` - Return stats
   - `idx_daily_progress_schedule_date` - Weekly progress
   - `idx_user_progress_active` - Active reading
   - `idx_books_category_rating` - Filtered queries
   - `idx_books_search_gin` - Full-text search
   - Va boshqalar...

2. **5 ta monitoring function** yaratadi:
   - `get_table_stats()` - Table hajmi va row count
   - `get_index_usage()` - Index usage statistics
   - `get_unused_indexes()` - Keraksiz index'lar
   - `get_slow_queries()` - Sekin query'lar
   - `database_health_check()` - Health check

3. **VACUUM va ANALYZE** - Database'ni tozalaydi

---

## 3️⃣ Migration'dan Keyin Tekshirish

### Health Check:

```sql
SELECT * FROM database_health_check();
```

**Kutilayotgan natija:**
```
metric                | value  | status
---------------------|--------|------------
Total Connections    | 15     | ✅ Good
Active Connections   | 3      | ✅ Good
Total Tables         | 9      | ✅ Info
Total Indexes        | 50+    | ✅ Info
Database Size        | 45 MB  | ✅ Good
```

### Index Usage:

```sql
SELECT * FROM get_index_usage() LIMIT 10;
```

**Yangi index'lar ko'rinishi kerak:**
- `idx_books_online_only` - 0 scans (yangi, hali ishlatilmagan)
- `idx_book_checkouts_checked_out_at` - 0 scans
- Va boshqalar...

### Table Stats:

```sql
SELECT * FROM get_table_stats();
```

**Har bir jadval uchun:**
- Row count
- Total size
- Index size
- Toast size

---

## 4️⃣ Performance Comparison

### BEFORE (Hozir):

```sql
-- Test query: Library page
EXPLAIN ANALYZE
SELECT id, title, author, rating, cover_url
FROM books
WHERE cover_url IS NOT NULL
ORDER BY created_at DESC
LIMIT 12;
```

**Kutilayotgan natija:**
- Execution time: ~50-100ms
- Seq Scan yoki Index Scan

### AFTER (Migration'dan keyin):

```sql
-- Xuddi shu query
EXPLAIN ANALYZE
SELECT id, title, author, rating, cover_url
FROM books
WHERE cover_url IS NOT NULL
ORDER BY created_at DESC
LIMIT 12;
```

**Kutilayotgan yaxshilanish:**
- Execution time: ~10-30ms (3-5x tezroq)
- Index Scan using `idx_books_online_only`

---

## 5️⃣ Slow Queries Monitoring

### Sekin query'larni topish:

```sql
-- 100ms dan sekin query'lar
SELECT * FROM get_slow_queries(100);
```

**Agar sekin query'lar bo'lsa:**
1. Query text'ni ko'ring
2. EXPLAIN ANALYZE qiling
3. Index qo'shish kerakmi tekshiring

---

## 6️⃣ Frontend Optimization (Keyingi Qadam)

Migration muvaffaqiyatli bo'lgandan keyin:

### 1. React Query Setup (15 daqiqa)
```bash
# lib/react-query/client.ts ni optimallashtiramiz
```

### 2. AuthContext Optimization (20 daqiqa)
```bash
# contexts/AuthContext.tsx ni optimallashtiramiz
```

### 3. Page Query Optimization (20 daqiqa)
```bash
# app/library/page.tsx
# app/admin/checker/page.tsx
```

---

## 📊 Expected Results

### Database Performance:
- ✅ 3-5x tezroq query'lar
- ✅ Index scan instead of seq scan
- ✅ Kam CPU usage
- ✅ Kam memory usage

### Application Performance:
- ✅ Library page: 800ms → 300ms
- ✅ Checker page: 500ms → 100ms
- ✅ Dashboard: 1200ms → 500ms

### Scalability:
- ✅ 10 concurrent users → 100+ concurrent users
- ✅ No performance degradation
- ✅ Smooth experience

---

## 🚀 Ready to Deploy?

### Pre-deployment Checklist:
- [ ] Run `00_database_analysis.sql` - Check current state
- [ ] Run `20251213_database_optimization.sql` - Apply optimization
- [ ] Run `database_health_check()` - Verify health
- [ ] Run `get_index_usage()` - Verify indexes created
- [ ] Test critical queries - Verify performance improvement
- [ ] Monitor for 5-10 minutes - Check for errors

### Deployment:
```bash
# 1. Commit changes
git add .
git commit -m "feat: database optimization with 10 new indexes"

# 2. Push to production
git push origin main

# 3. Vercel will auto-deploy
# 4. Monitor performance in production
```

---

## 🔍 Monitoring (Production)

### Daily:
```sql
SELECT * FROM database_health_check();
```

### Weekly:
```sql
SELECT * FROM get_slow_queries(100);
SELECT * FROM get_unused_indexes();
```

### Monthly:
```sql
VACUUM ANALYZE;
SELECT * FROM get_table_stats();
```

---

## ❓ Troubleshooting

### Agar index yaratilmasa:
```sql
-- Check errors
SELECT * FROM pg_stat_activity WHERE state = 'active';

-- Drop and recreate
DROP INDEX IF EXISTS idx_books_online_only;
CREATE INDEX idx_books_online_only ON books(id, created_at DESC) WHERE cover_url IS NOT NULL;
```

### Agar query hali ham sekin bo'lsa:
```sql
-- Check if index is being used
EXPLAIN ANALYZE <your_query>;

-- If not using index, check statistics
ANALYZE books;
```

### Agar connection error bo'lsa:
```sql
-- Check connections
SELECT count(*) FROM pg_stat_activity;

-- Kill idle connections
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'idle' 
AND state_change < NOW() - INTERVAL '10 minutes';
```
