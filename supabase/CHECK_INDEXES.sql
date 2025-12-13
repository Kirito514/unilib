-- Quick Check: Which indexes exist?
-- Run this in Supabase SQL Editor

SELECT indexname, tablename 
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

-- Expected indexes (should see these):
-- idx_books_category_rating
-- idx_books_online_only
-- idx_books_search_gin
-- idx_book_checkouts_checked_out_at
-- idx_book_checkouts_returned_at
-- idx_daily_progress_schedule_date
-- idx_user_progress_active
-- idx_profiles_leaderboard
