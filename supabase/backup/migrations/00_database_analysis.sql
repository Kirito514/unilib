-- Database Analysis Script
-- Run this in Supabase SQL Editor to check current state
-- Date: 2025-12-13

-- ============================================
-- 1. CHECK EXISTING TABLES
-- ============================================
SELECT 
    t.schemaname,
    t.tablename,
    pg_size_pretty(pg_total_relation_size(t.schemaname||'.'||t.tablename)) AS total_size,
    (SELECT count(*) FROM information_schema.columns WHERE table_name = t.tablename AND table_schema = 'public') AS column_count
FROM pg_tables t
WHERE t.schemaname = 'public'
ORDER BY pg_total_relation_size(t.schemaname||'.'||t.tablename) DESC;

-- ============================================
-- 2. CHECK EXISTING INDEXES
-- ============================================
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    idx_scan AS times_used,
    CASE 
        WHEN idx_scan = 0 THEN '❌ Never used'
        WHEN idx_scan < 100 THEN '⚠️ Rarely used'
        WHEN idx_scan < 1000 THEN '✅ Sometimes used'
        ELSE '🔥 Frequently used'
    END AS usage_status
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- ============================================
-- 3. CHECK IF NEW INDEXES ALREADY EXIST
-- ============================================
SELECT 
    indexname,
    CASE 
        WHEN indexname = 'idx_books_online_only' THEN '✅ EXISTS'
        WHEN indexname = 'idx_book_checkouts_checked_out_at' THEN '✅ EXISTS'
        WHEN indexname = 'idx_book_checkouts_returned_at' THEN '✅ EXISTS'
        WHEN indexname = 'idx_daily_progress_schedule_date' THEN '✅ EXISTS'
        WHEN indexname = 'idx_user_progress_active' THEN '✅ EXISTS'
        WHEN indexname = 'idx_books_category_rating' THEN '✅ EXISTS'
        WHEN indexname = 'idx_books_search_gin' THEN '✅ EXISTS'
        ELSE 'Other index'
    END AS status
FROM pg_indexes
WHERE schemaname = 'public'
AND indexname IN (
    'idx_books_online_only',
    'idx_book_checkouts_checked_out_at',
    'idx_book_checkouts_returned_at',
    'idx_daily_progress_schedule_date',
    'idx_user_progress_active',
    'idx_books_category_rating',
    'idx_books_search_gin'
);

-- If empty result, indexes don't exist yet (GOOD - we need to create them)

-- ============================================
-- 4. CHECK IF MONITORING FUNCTIONS EXIST
-- ============================================
SELECT 
    routine_name,
    routine_type,
    CASE 
        WHEN routine_name = 'get_table_stats' THEN '✅ EXISTS'
        WHEN routine_name = 'get_index_usage' THEN '✅ EXISTS'
        WHEN routine_name = 'get_unused_indexes' THEN '✅ EXISTS'
        WHEN routine_name = 'get_slow_queries' THEN '✅ EXISTS'
        WHEN routine_name = 'database_health_check' THEN '✅ EXISTS'
        ELSE 'Other function'
    END AS status
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
    'get_table_stats',
    'get_index_usage',
    'get_unused_indexes',
    'get_slow_queries',
    'database_health_check'
);

-- If empty result, functions don't exist yet (GOOD - we need to create them)

-- ============================================
-- 5. CHECK CURRENT DATABASE SIZE
-- ============================================
SELECT 
    pg_size_pretty(pg_database_size(current_database())) AS database_size,
    (SELECT count(*) FROM pg_stat_activity) AS total_connections,
    (SELECT count(*) FROM pg_stat_activity WHERE state = 'active') AS active_connections;

-- ============================================
-- 6. CHECK TABLE ROW COUNTS
-- ============================================
SELECT 
    'profiles' AS table_name,
    count(*) AS row_count
FROM profiles
UNION ALL
SELECT 'books', count(*) FROM books
UNION ALL
SELECT 'physical_book_copies', count(*) FROM physical_book_copies
UNION ALL
SELECT 'book_checkouts', count(*) FROM book_checkouts
UNION ALL
SELECT 'user_progress', count(*) FROM user_progress
UNION ALL
SELECT 'achievements', count(*) FROM achievements
UNION ALL
SELECT 'user_achievements', count(*) FROM user_achievements
UNION ALL
SELECT 'reading_schedule', count(*) FROM reading_schedule
UNION ALL
SELECT 'daily_progress', count(*) FROM daily_progress
ORDER BY row_count DESC;

-- ============================================
-- 7. TEST CRITICAL QUERIES (Performance Baseline)
-- ============================================

-- Test 1: Student search (Checker page)
EXPLAIN ANALYZE
SELECT id, name, email, student_id, student_number, avatar_url, xp
FROM profiles
WHERE student_number = '25001' OR student_id = '25001'
LIMIT 1;

-- Test 2: Active loans query
EXPLAIN ANALYZE
SELECT 
    bc.id,
    bc.due_date,
    bc.checked_out_at
FROM book_checkouts bc
WHERE bc.user_id = (SELECT id FROM profiles LIMIT 1)
  AND bc.status = 'active'
ORDER BY bc.due_date ASC;

-- Test 3: Library books query
EXPLAIN ANALYZE
SELECT id, title, author, rating, cover_color, category, cover_url, views_count
FROM books
WHERE cover_url IS NOT NULL
ORDER BY created_at DESC
LIMIT 12;

-- ============================================
-- 8. SUMMARY REPORT
-- ============================================
SELECT 
    '📊 Database Analysis Summary' AS report_section,
    '' AS details
UNION ALL
SELECT 
    '✅ Tables',
    (SELECT count(*)::text FROM pg_tables WHERE schemaname = 'public') || ' tables'
UNION ALL
SELECT 
    '✅ Indexes',
    (SELECT count(*)::text FROM pg_indexes WHERE schemaname = 'public') || ' indexes'
UNION ALL
SELECT 
    '✅ Functions',
    (SELECT count(*)::text FROM information_schema.routines WHERE routine_schema = 'public') || ' functions'
UNION ALL
SELECT 
    '📦 Database Size',
    pg_size_pretty(pg_database_size(current_database()))
UNION ALL
SELECT 
    '👥 Total Users',
    (SELECT count(*)::text FROM profiles)
UNION ALL
SELECT 
    '📚 Total Books',
    (SELECT count(*)::text FROM books)
UNION ALL
SELECT 
    '🔄 Active Checkouts',
    (SELECT count(*)::text FROM book_checkouts WHERE status = 'active');

-- ============================================
-- NEXT STEPS:
-- ============================================
-- 1. Review the results above
-- 2. If new indexes don't exist, run: 20251213_database_optimization.sql
-- 3. After migration, run this script again to verify
-- 4. Compare performance before/after
