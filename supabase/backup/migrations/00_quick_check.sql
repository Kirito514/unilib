-- QUICK DATABASE CHECK
-- Run each section separately in Supabase SQL Editor
-- Date: 2025-12-13

-- ============================================
-- SECTION 1: Tables Overview
-- ============================================
SELECT 
    t.schemaname,
    t.tablename,
    pg_size_pretty(pg_total_relation_size(t.schemaname||'.'||t.tablename)) AS total_size
FROM pg_tables t
WHERE t.schemaname = 'public'
ORDER BY pg_total_relation_size(t.schemaname||'.'||t.tablename) DESC;

-- ============================================
-- SECTION 2: Existing Indexes
-- ============================================
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    idx_scan AS times_used
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC
LIMIT 20;

-- ============================================
-- SECTION 3: Check New Indexes (Should be empty)
-- ============================================
SELECT indexname
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
-- If empty = Good! We need to create them

-- ============================================
-- SECTION 4: Database Size & Connections
-- ============================================
SELECT 
    pg_size_pretty(pg_database_size(current_database())) AS database_size,
    (SELECT count(*) FROM pg_stat_activity) AS total_connections,
    (SELECT count(*) FROM pg_stat_activity WHERE state = 'active') AS active_connections;

-- ============================================
-- SECTION 5: Table Row Counts
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
ORDER BY row_count DESC;

-- ============================================
-- SECTION 6: Performance Test - Library Query
-- ============================================
EXPLAIN ANALYZE
SELECT id, title, author, rating, cover_url
FROM books
WHERE cover_url IS NOT NULL
ORDER BY created_at DESC
LIMIT 12;
-- Look for: Execution Time (should be ~50-100ms before optimization)

-- ============================================
-- SECTION 7: Performance Test - Student Search
-- ============================================
EXPLAIN ANALYZE
SELECT id, name, email, student_id, student_number
FROM profiles
WHERE student_number = '25001' OR student_id = '25001'
LIMIT 1;
-- Look for: Index Scan (should use idx_profiles_student_number or idx_profiles_student_id)

-- ============================================
-- NEXT: Run 20251213_database_optimization.sql
-- ============================================
