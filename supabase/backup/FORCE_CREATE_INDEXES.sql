-- FORCE CREATE ALL INDEXES
-- This will fix the Seq Scan problem

-- ============================================
-- 1. Drop and Recreate All Performance Indexes
-- ============================================

-- Books: Online books filter
DROP INDEX IF EXISTS idx_books_online_only;
CREATE INDEX idx_books_online_only 
ON books(created_at DESC, id) 
WHERE cover_url IS NOT NULL;

-- Books: Category + rating filter
DROP INDEX IF EXISTS idx_books_category_rating;
CREATE INDEX idx_books_category_rating 
ON books(category, rating DESC, created_at DESC) 
WHERE cover_url IS NOT NULL;

-- Books: Full-text search
DROP INDEX IF EXISTS idx_books_search_gin;
CREATE INDEX idx_books_search_gin 
ON books USING gin(to_tsvector('english', title || ' ' || author));

-- Book Checkouts: Today stats
DROP INDEX IF EXISTS idx_book_checkouts_checked_out_at;
CREATE INDEX idx_book_checkouts_checked_out_at 
ON book_checkouts(checked_out_at DESC) 
WHERE status = 'active';

DROP INDEX IF EXISTS idx_book_checkouts_returned_at;
CREATE INDEX idx_book_checkouts_returned_at 
ON book_checkouts(returned_at DESC) 
WHERE status = 'returned';

-- Daily Progress: Schedule queries
DROP INDEX IF EXISTS idx_daily_progress_schedule_date;
CREATE INDEX idx_daily_progress_schedule_date 
ON daily_progress(schedule_id, date DESC);

-- User Progress: Active reading
DROP INDEX IF EXISTS idx_user_progress_active;
CREATE INDEX idx_user_progress_active 
ON user_progress(user_id, last_read_at DESC) 
WHERE progress_percentage > 0 AND progress_percentage < 100;

-- Profiles: Leaderboard
DROP INDEX IF EXISTS idx_profiles_leaderboard;
CREATE INDEX idx_profiles_leaderboard 
ON profiles(xp DESC, streak_days DESC) 
WHERE is_active = true;

-- Profiles: Student number search
DROP INDEX IF EXISTS idx_profiles_student_number;
CREATE INDEX idx_profiles_student_number 
ON profiles(student_number) 
WHERE student_number IS NOT NULL;

-- Book Checkouts: User status
DROP INDEX IF EXISTS idx_checkouts_user_status;
CREATE INDEX idx_checkouts_user_status 
ON book_checkouts(user_id, status, checked_out_at DESC);

-- ============================================
-- 2. Update Statistics
-- ============================================

ANALYZE books;
ANALYZE book_checkouts;
ANALYZE profiles;
ANALYZE user_progress;
ANALYZE daily_progress;
ANALYZE reading_schedule;
ANALYZE physical_book_copies;

-- ============================================
-- 3. Verify Index Usage
-- ============================================

-- This should NOW use Index Scan
EXPLAIN ANALYZE
SELECT id, title, author, rating
FROM books
WHERE cover_url IS NOT NULL
ORDER BY created_at DESC
LIMIT 12;

-- Expected output should include:
-- "Index Scan using idx_books_online_only"
-- NOT "Seq Scan"

-- ============================================
-- 4. Show All Created Indexes
-- ============================================

SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;
