-- Database Tables Analysis
-- Check which tables exist and how they are used
-- Date: 2025-12-13

-- ============================================
-- 1. ALL TABLES WITH ROW COUNTS AND SIZES
-- ============================================
SELECT 
    tablename AS table_name,
    (SELECT count(*) FROM information_schema.columns WHERE table_name = t.tablename) AS column_count,
    pg_size_pretty(pg_total_relation_size('public.'||tablename)) AS total_size
FROM pg_tables t
WHERE schemaname = 'public'
ORDER BY tablename;

-- ============================================
-- 2. TABLES WITH DATA (Row counts)
-- ============================================
SELECT 'profiles' AS table_name, count(*) AS rows FROM profiles
UNION ALL SELECT 'books', count(*) FROM books
UNION ALL SELECT 'physical_book_copies', count(*) FROM physical_book_copies
UNION ALL SELECT 'book_checkouts', count(*) FROM book_checkouts
UNION ALL SELECT 'user_progress', count(*) FROM user_progress
UNION ALL SELECT 'achievements', count(*) FROM achievements
UNION ALL SELECT 'user_achievements', count(*) FROM user_achievements
UNION ALL SELECT 'reading_schedule', count(*) FROM reading_schedule
UNION ALL SELECT 'daily_progress', count(*) FROM daily_progress
UNION ALL SELECT 'notifications', count(*) FROM notifications
UNION ALL SELECT 'groups', count(*) FROM groups
UNION ALL SELECT 'admin_activity_log', count(*) FROM admin_activity_log
UNION ALL SELECT 'library_views', count(*) FROM library_views
UNION ALL SELECT 'book_reviews', count(*) FROM book_reviews
ORDER BY rows DESC;

-- ============================================
-- 3. TABLES USED IN APPLICATION (Check queries)
-- ============================================
-- This shows which tables are actively queried
SELECT 
    relname AS table_name,
    seq_scan AS sequential_scans,
    seq_tup_read AS rows_read_seq,
    idx_scan AS index_scans,
    idx_tup_fetch AS rows_read_idx,
    n_tup_ins AS inserts,
    n_tup_upd AS updates,
    n_tup_del AS deletes,
    CASE 
        WHEN seq_scan = 0 AND idx_scan = 0 THEN '❌ NEVER USED'
        WHEN seq_scan + idx_scan < 10 THEN '⚠️ RARELY USED'
        WHEN seq_scan + idx_scan < 100 THEN '✅ SOMETIMES USED'
        ELSE '🔥 FREQUENTLY USED'
    END AS usage_status
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY (seq_scan + idx_scan) DESC;

-- ============================================
-- 4. FOREIGN KEY RELATIONSHIPS
-- ============================================
-- Shows which tables are connected
SELECT
    tc.table_name AS from_table,
    kcu.column_name AS from_column,
    ccu.table_name AS to_table,
    ccu.column_name AS to_column
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- ============================================
-- 5. SUMMARY: CORE vs OPTIONAL TABLES
-- ============================================

-- CORE TABLES (Must have):
-- profiles - User accounts
-- books - Book catalog
-- physical_book_copies - Physical book inventory
-- book_checkouts - Borrowing system
-- user_progress - Reading progress

-- GAMIFICATION TABLES (Optional but used):
-- achievements - Achievement definitions
-- user_achievements - User unlocked achievements
-- reading_schedule - Reading goals
-- daily_progress - Daily reading tracking

-- OPTIONAL TABLES (May not be used):
-- notifications - Notification system
-- groups - Study groups
-- admin_activity_log - Admin actions log
-- library_views - Book view tracking
-- book_reviews - Book reviews

-- ============================================
-- 6. RECOMMENDATION: Tables to Keep/Remove
-- ============================================
-- Run this to see which tables have NO data and NO usage:
SELECT 
    t.tablename,
    COALESCE(s.seq_scan, 0) + COALESCE(s.idx_scan, 0) AS total_scans,
    CASE 
        WHEN COALESCE(s.seq_scan, 0) + COALESCE(s.idx_scan, 0) = 0 THEN '❌ Consider removing'
        ELSE '✅ Keep'
    END AS recommendation
FROM pg_tables t
LEFT JOIN pg_stat_user_tables s ON t.tablename = s.relname AND s.schemaname = 'public'
WHERE t.schemaname = 'public'
ORDER BY total_scans DESC;
