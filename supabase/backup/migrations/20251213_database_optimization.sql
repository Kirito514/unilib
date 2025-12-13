-- Database Performance Optimization
-- Date: 2025-12-13
-- Purpose: Add additional indexes and optimize query performance

-- ============================================
-- 1. Additional Indexes for Better Performance
-- ============================================

-- Books: Optimize online books filter (WHERE cover_url IS NOT NULL)
CREATE INDEX IF NOT EXISTS idx_books_online_only 
ON books(id, created_at DESC) 
WHERE cover_url IS NOT NULL;

COMMENT ON INDEX idx_books_online_only IS 'Optimize library page online books query';

-- Book Checkouts: Optimize today stats queries
CREATE INDEX IF NOT EXISTS idx_book_checkouts_checked_out_at 
ON book_checkouts(checked_out_at DESC) 
WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_book_checkouts_returned_at 
ON book_checkouts(returned_at DESC) 
WHERE status = 'returned';

COMMENT ON INDEX idx_book_checkouts_checked_out_at IS 'Optimize today checkout stats';
COMMENT ON INDEX idx_book_checkouts_returned_at IS 'Optimize today return stats';

-- Daily Progress: Optimize schedule-based queries
CREATE INDEX IF NOT EXISTS idx_daily_progress_schedule_date 
ON daily_progress(schedule_id, date DESC);

COMMENT ON INDEX idx_daily_progress_schedule_date IS 'Optimize weekly progress queries';

-- User Progress: Optimize active reading queries
CREATE INDEX IF NOT EXISTS idx_user_progress_active 
ON user_progress(user_id, last_read_at DESC) 
WHERE progress_percentage > 0 AND progress_percentage < 100;

COMMENT ON INDEX idx_user_progress_active IS 'Optimize active reading books query';

-- ============================================
-- 2. Composite Indexes for Common Query Patterns
-- ============================================

-- Profiles: Optimize leaderboard with active filter
DROP INDEX IF EXISTS idx_profiles_leaderboard;
CREATE INDEX idx_profiles_leaderboard 
ON profiles(xp DESC, streak_days DESC) 
WHERE is_active = true;

-- Books: Optimize category + rating filter
CREATE INDEX IF NOT EXISTS idx_books_category_rating 
ON books(category, rating DESC) 
WHERE cover_url IS NOT NULL;

COMMENT ON INDEX idx_books_category_rating IS 'Optimize filtered library queries';

-- ============================================
-- 3. Text Search Optimization
-- ============================================

-- Books: Full-text search index for title and author
DROP INDEX IF EXISTS idx_books_title_search;
DROP INDEX IF EXISTS idx_books_author_search;

CREATE INDEX idx_books_search_gin 
ON books USING gin(to_tsvector('english', title || ' ' || author));

COMMENT ON INDEX idx_books_search_gin IS 'Full-text search for books';

-- ============================================
-- 4. Analyze Tables for Query Planner
-- ============================================

ANALYZE profiles;
ANALYZE books;
ANALYZE physical_book_copies;
ANALYZE book_checkouts;
ANALYZE user_progress;
ANALYZE reading_schedule;
ANALYZE daily_progress;
ANALYZE achievements;
ANALYZE user_achievements;

-- ============================================
-- 5. Performance Monitoring Functions
-- ============================================
-- Note: VACUUM commands removed (cannot run in transaction)
-- Run VACUUM manually if needed: VACUUM ANALYZE table_name;

-- ============================================
-- 6. Performance Monitoring Function
-- ============================================

CREATE OR REPLACE FUNCTION get_table_stats()
RETURNS TABLE (
    table_name TEXT,
    row_count BIGINT,
    total_size TEXT,
    index_size TEXT,
    toast_size TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        schemaname || '.' || relname AS table_name,
        n_live_tup AS row_count,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||relname)) AS total_size,
        pg_size_pretty(pg_indexes_size(schemaname||'.'||relname)) AS index_size,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||relname) - 
                      pg_relation_size(schemaname||'.'||relname) - 
                      pg_indexes_size(schemaname||'.'||relname)) AS toast_size
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'
    ORDER BY pg_total_relation_size(schemaname||'.'||relname) DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_table_stats IS 'Get table size and row count statistics';

-- ============================================
-- 7. Index Usage Monitoring Function
-- ============================================

CREATE OR REPLACE FUNCTION get_index_usage()
RETURNS TABLE (
    schema_name TEXT,
    table_name TEXT,
    index_name TEXT,
    index_scans BIGINT,
    rows_read BIGINT,
    rows_fetched BIGINT,
    index_size TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        schemaname AS schema_name,
        relname AS table_name,
        indexrelname AS index_name,
        idx_scan AS index_scans,
        idx_tup_read AS rows_read,
        idx_tup_fetch AS rows_fetched,
        pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
    FROM pg_stat_user_indexes
    WHERE schemaname = 'public'
    ORDER BY idx_scan DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_index_usage IS 'Monitor index usage statistics';

-- ============================================
-- 8. Unused Indexes Detection
-- ============================================

CREATE OR REPLACE FUNCTION get_unused_indexes()
RETURNS TABLE (
    schema_name TEXT,
    table_name TEXT,
    index_name TEXT,
    index_size TEXT,
    reason TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        schemaname AS schema_name,
        relname AS table_name,
        indexrelname AS index_name,
        pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
        'Never used (0 scans)' AS reason
    FROM pg_stat_user_indexes
    WHERE schemaname = 'public'
    AND idx_scan = 0
    AND indexrelid NOT IN (
        -- Exclude primary keys and unique constraints
        SELECT indexrelid 
        FROM pg_index 
        WHERE indisprimary OR indisunique
    )
    ORDER BY pg_relation_size(indexrelid) DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_unused_indexes IS 'Find unused indexes that can be removed';

-- ============================================
-- 9. Query Performance Helper
-- ============================================

-- Enable pg_stat_statements if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Function to get slow queries
CREATE OR REPLACE FUNCTION get_slow_queries(min_duration_ms INTEGER DEFAULT 100)
RETURNS TABLE (
    query_text TEXT,
    calls BIGINT,
    total_time_ms NUMERIC,
    mean_time_ms NUMERIC,
    max_time_ms NUMERIC,
    stddev_time_ms NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        query AS query_text,
        calls,
        ROUND(total_exec_time::NUMERIC, 2) AS total_time_ms,
        ROUND(mean_exec_time::NUMERIC, 2) AS mean_time_ms,
        ROUND(max_exec_time::NUMERIC, 2) AS max_time_ms,
        ROUND(stddev_exec_time::NUMERIC, 2) AS stddev_time_ms
    FROM pg_stat_statements
    WHERE mean_exec_time > min_duration_ms
    ORDER BY mean_exec_time DESC
    LIMIT 20;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_slow_queries IS 'Find slow queries (default: >100ms mean time)';

-- ============================================
-- 10. Database Health Check
-- ============================================

CREATE OR REPLACE FUNCTION database_health_check()
RETURNS TABLE (
    metric TEXT,
    value TEXT,
    status TEXT
) AS $$
DECLARE
    total_connections INTEGER;
    active_connections INTEGER;
    table_count INTEGER;
    index_count INTEGER;
    total_db_size BIGINT;
BEGIN
    -- Get connection stats
    SELECT count(*) INTO total_connections FROM pg_stat_activity;
    SELECT count(*) INTO active_connections FROM pg_stat_activity WHERE state = 'active';
    
    -- Get table and index counts
    SELECT count(*) INTO table_count FROM pg_tables WHERE schemaname = 'public';
    SELECT count(*) INTO index_count FROM pg_indexes WHERE schemaname = 'public';
    
    -- Get database size
    SELECT pg_database_size(current_database()) INTO total_db_size;
    
    -- Return metrics
    RETURN QUERY
    SELECT 'Total Connections'::TEXT, total_connections::TEXT, 
           CASE WHEN total_connections < 50 THEN '✅ Good' 
                WHEN total_connections < 100 THEN '⚠️ Warning' 
                ELSE '❌ Critical' END;
    
    RETURN QUERY
    SELECT 'Active Connections'::TEXT, active_connections::TEXT,
           CASE WHEN active_connections < 20 THEN '✅ Good' 
                WHEN active_connections < 50 THEN '⚠️ Warning' 
                ELSE '❌ Critical' END;
    
    RETURN QUERY
    SELECT 'Total Tables'::TEXT, table_count::TEXT, '✅ Info';
    
    RETURN QUERY
    SELECT 'Total Indexes'::TEXT, index_count::TEXT, '✅ Info';
    
    RETURN QUERY
    SELECT 'Database Size'::TEXT, pg_size_pretty(total_db_size), 
           CASE WHEN total_db_size < 1073741824 THEN '✅ Good'  -- < 1GB
                WHEN total_db_size < 5368709120 THEN '⚠️ Warning'  -- < 5GB
                ELSE '❌ Large' END;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION database_health_check IS 'Quick database health check';

-- ============================================
-- Migration Complete
-- ============================================

-- Run health check
SELECT * FROM database_health_check();

-- Show table stats
SELECT * FROM get_table_stats();

-- Show index usage
SELECT * FROM get_index_usage() LIMIT 10;
