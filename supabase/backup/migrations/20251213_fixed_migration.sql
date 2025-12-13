-- FIXED Migration - Skip existing indexes
-- Date: 2025-12-13
-- Run this if you got "already exists" error

-- ============================================
-- 1. Create Missing Indexes Only
-- ============================================

-- Books: Online books filter
CREATE INDEX IF NOT EXISTS idx_books_online_only 
ON books(id, created_at DESC) 
WHERE cover_url IS NOT NULL;

-- Book Checkouts: Today stats
CREATE INDEX IF NOT EXISTS idx_book_checkouts_checked_out_at 
ON book_checkouts(checked_out_at DESC) 
WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_book_checkouts_returned_at 
ON book_checkouts(returned_at DESC) 
WHERE status = 'returned';

-- Daily Progress: Schedule queries
CREATE INDEX IF NOT EXISTS idx_daily_progress_schedule_date 
ON daily_progress(schedule_id, date DESC);

-- User Progress: Active reading
CREATE INDEX IF NOT EXISTS idx_user_progress_active 
ON user_progress(user_id, last_read_at DESC) 
WHERE progress_percentage > 0 AND progress_percentage < 100;

-- Profiles: Leaderboard (recreate to ensure correct)
DROP INDEX IF EXISTS idx_profiles_leaderboard;
CREATE INDEX idx_profiles_leaderboard 
ON profiles(xp DESC, streak_days DESC) 
WHERE is_active = true;

-- Books: Category + rating filter
CREATE INDEX IF NOT EXISTS idx_books_category_rating 
ON books(category, rating DESC) 
WHERE cover_url IS NOT NULL;

-- Books: Search index (skip if exists)
-- Already exists, so we skip it

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
-- 3. Verify Indexes Created
-- ============================================

SELECT 
    indexname, 
    tablename,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
AND (
    indexname LIKE 'idx_books_%'
    OR indexname LIKE 'idx_book_checkouts_%'
    OR indexname LIKE 'idx_daily_progress_%'
    OR indexname LIKE 'idx_user_progress_%'
    OR indexname LIKE 'idx_profiles_%'
)
ORDER BY tablename, indexname;

-- ============================================
-- 4. Test Query Performance
-- ============================================

-- Should use Index Scan now (not Seq Scan)
EXPLAIN ANALYZE
SELECT id, title, author, rating
FROM books
WHERE cover_url IS NOT NULL
ORDER BY created_at DESC
LIMIT 12;

-- Expected: "Index Scan using idx_books_online_only"
-- NOT: "Seq Scan on books"
