-- ============================================
-- SIMPLE DATABASE CHECK - RUN THIS INSTEAD
-- Copy-paste each section separately
-- ============================================

-- SECTION 1: Tables
SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size('public.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size('public.'||tablename) DESC;

-- SECTION 2: Indexes (Top 20)
SELECT 
    indexrelname AS index_name,
    relname AS table_name,
    idx_scan AS times_used
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC
LIMIT 20;

-- SECTION 3: Check if new indexes exist (should be empty)
SELECT indexname AS index_name
FROM pg_indexes
WHERE schemaname = 'public'
AND (
   indexname LIKE 'idx_books_online%'
   OR indexname LIKE 'idx_book_checkouts_checked%'
   OR indexname LIKE 'idx_book_checkouts_returned%'
   OR indexname LIKE 'idx_daily_progress_schedule%'
   OR indexname LIKE 'idx_user_progress_active%'
   OR indexname LIKE 'idx_books_category_rating%'
   OR indexname LIKE 'idx_books_search_gin%'
);

-- SECTION 4: Database size
SELECT pg_size_pretty(pg_database_size(current_database())) AS db_size;

-- SECTION 5: Row counts
SELECT 'profiles' AS tbl, count(*) AS rows FROM profiles
UNION ALL SELECT 'books', count(*) FROM books
UNION ALL SELECT 'book_checkouts', count(*) FROM book_checkouts
UNION ALL SELECT 'user_progress', count(*) FROM user_progress
ORDER BY rows DESC;

-- SECTION 6: Test library query performance
EXPLAIN ANALYZE
SELECT id, title, author, rating
FROM books
WHERE cover_url IS NOT NULL
ORDER BY created_at DESC
LIMIT 12;

-- ============================================
-- IF ALL LOOKS GOOD, RUN THE OPTIMIZATION:
-- File: 20251213_database_optimization.sql
-- ============================================
