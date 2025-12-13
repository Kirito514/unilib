-- Database Performance Optimization - SIMPLIFIED VERSION
-- Date: 2025-12-13
-- Purpose: Add indexes only, skip complex monitoring functions

-- ============================================
-- 1. Additional Indexes for Better Performance
-- ============================================

-- Books: Optimize online books filter (WHERE cover_url IS NOT NULL)
CREATE INDEX IF NOT EXISTS idx_books_online_only 
ON books(id, created_at DESC) 
WHERE cover_url IS NOT NULL;

-- Book Checkouts: Optimize today stats queries
CREATE INDEX IF NOT EXISTS idx_book_checkouts_checked_out_at 
ON book_checkouts(checked_out_at DESC) 
WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_book_checkouts_returned_at 
ON book_checkouts(returned_at DESC) 
WHERE status = 'returned';

-- Daily Progress: Optimize schedule-based queries
CREATE INDEX IF NOT EXISTS idx_daily_progress_schedule_date 
ON daily_progress(schedule_id, date DESC);

-- User Progress: Optimize active reading queries
CREATE INDEX IF NOT EXISTS idx_user_progress_active 
ON user_progress(user_id, last_read_at DESC) 
WHERE progress_percentage > 0 AND progress_percentage < 100;

-- Profiles: Optimize leaderboard with active filter
DROP INDEX IF EXISTS idx_profiles_leaderboard;
CREATE INDEX idx_profiles_leaderboard 
ON profiles(xp DESC, streak_days DESC) 
WHERE is_active = true;

-- Books: Optimize category + rating filter
CREATE INDEX IF NOT EXISTS idx_books_category_rating 
ON books(category, rating DESC) 
WHERE cover_url IS NOT NULL;

-- Books: Full-text search index
DROP INDEX IF EXISTS idx_books_title_search;
DROP INDEX IF EXISTS idx_books_author_search;
CREATE INDEX idx_books_search_gin 
ON books USING gin(to_tsvector('english', title || ' ' || author));

-- ============================================
-- 2. Analyze Tables
-- ============================================

ANALYZE profiles;
ANALYZE books;
ANALYZE physical_book_copies;
ANALYZE book_checkouts;
ANALYZE user_progress;
ANALYZE reading_schedule;
ANALYZE daily_progress;

-- ============================================
-- 3. Simple Health Check Function
-- ============================================

CREATE OR REPLACE FUNCTION simple_health_check()
RETURNS TABLE (
    metric TEXT,
    value TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 'Total Tables'::TEXT, 
           (SELECT count(*)::TEXT FROM pg_tables WHERE schemaname = 'public');
    
    RETURN QUERY
    SELECT 'Total Indexes'::TEXT,
           (SELECT count(*)::TEXT FROM pg_indexes WHERE schemaname = 'public');
    
    RETURN QUERY
    SELECT 'Database Size'::TEXT,
           pg_size_pretty(pg_database_size(current_database()));
    
    RETURN QUERY
    SELECT 'Active Connections'::TEXT,
           (SELECT count(*)::TEXT FROM pg_stat_activity WHERE state = 'active');
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- DONE! Test the results
-- ============================================

-- Show health check
SELECT * FROM simple_health_check();

-- Show new indexes
SELECT indexname, tablename 
FROM pg_indexes 
WHERE schemaname = 'public' 
AND indexname LIKE 'idx_books_online%'
   OR indexname LIKE 'idx_book_checkouts_%'
   OR indexname LIKE 'idx_daily_progress_%'
   OR indexname LIKE 'idx_user_progress_active%'
   OR indexname LIKE 'idx_books_category%'
   OR indexname LIKE 'idx_books_search%'
   OR indexname LIKE 'idx_profiles_leaderboard%';

-- Test library query performance
EXPLAIN ANALYZE
SELECT id, title, author, rating
FROM books
WHERE cover_url IS NOT NULL
ORDER BY created_at DESC
LIMIT 12;
