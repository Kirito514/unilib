-- ============================================================================
-- CONSOLIDATED MIGRATION FILE - UniLib Platform
-- Generated: 2025-12-13 17:43:58
-- Description: All SQL migrations consolidated into single file
-- ============================================================================


-- ============================================================================
-- FILE: supabase\migrations\20251213_add_student_id.sql
-- ============================================================================

-- Migration: Add Student Short ID System (Year-Based)
-- Date: 2025-12-13
-- Purpose: Add short numeric student IDs with year prefix for manual fallback when scanner fails
-- Format: YYXXX (e.g., 24001, 25001)

-- Add student_id column to profiles
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS student_id TEXT UNIQUE;

-- Create sequences for each year (we'll create them dynamically)
-- Function to get or create sequence for a year
CREATE OR REPLACE FUNCTION get_year_sequence(year_suffix TEXT)
RETURNS TEXT AS $$
DECLARE
    seq_name TEXT;
BEGIN
    seq_name := 'student_id_seq_' || year_suffix;
    
    -- Create sequence if it doesn't exist
    EXECUTE format('CREATE SEQUENCE IF NOT EXISTS %I START 1', seq_name);
    
    RETURN seq_name;
END;
$$ LANGUAGE plpgsql;

-- Function to generate year-based student ID (YYXXX format)
CREATE OR REPLACE FUNCTION generate_student_id()
RETURNS TEXT AS $$
DECLARE
    current_year TEXT;
    year_suffix TEXT;
    seq_name TEXT;
    next_id INTEGER;
    student_id TEXT;
BEGIN
    -- Get current year (last 2 digits)
    current_year := to_char(CURRENT_DATE, 'YY');
    year_suffix := current_year;
    
    -- Get or create sequence for this year
    seq_name := get_year_sequence(year_suffix);
    
    -- Get next sequence value for this year
    EXECUTE format('SELECT nextval(%L)', seq_name) INTO next_id;
    
    -- Format as YYXXX (year + 3-digit sequential)
    student_id := year_suffix || LPAD(next_id::TEXT, 3, '0');
    
    RETURN student_id;
END;
$$ LANGUAGE plpgsql;

-- Update existing users with student IDs
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN 
        SELECT id FROM profiles WHERE student_id IS NULL ORDER BY created_at
    LOOP
        UPDATE profiles 
        SET student_id = generate_student_id()
        WHERE id = user_record.id;
    END LOOP;
END $$;

-- Create index for fast student ID lookups
CREATE INDEX IF NOT EXISTS idx_profiles_student_id ON profiles(student_id);

-- Add comment
COMMENT ON COLUMN profiles.student_id IS 'Short 5-digit student ID for manual input (00001, 00002, etc.)';

-- ============================================================================
-- FILE: supabase\migrations\20251213_add_student_id_trigger.sql
-- ============================================================================

-- Add trigger to auto-generate student_id on profile creation
-- Date: 2025-12-13

-- Drop existing trigger if any
DROP TRIGGER IF EXISTS trigger_auto_generate_student_id ON profiles;

-- Create trigger function
CREATE OR REPLACE FUNCTION auto_generate_student_id()
RETURNS TRIGGER AS $$
BEGIN
    -- Only generate if student_id is NULL
    IF NEW.student_id IS NULL THEN
        NEW.student_id := generate_student_id();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER trigger_auto_generate_student_id
    BEFORE INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_student_id();

-- Verify trigger was created
SELECT 
    trigger_name, 
    event_manipulation, 
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'profiles' 
AND trigger_name = 'trigger_auto_generate_student_id';

-- ============================================================================
-- FILE: supabase\FORCE_CREATE_INDEXES.sql
-- ============================================================================

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

-- ============================================================================
-- FILE: supabase\FIX_STUDENT_IDS.sql
-- ============================================================================

-- Check and fix student_id for all users
-- Date: 2025-12-13

-- 1. Check how many users don't have student_id
SELECT 
    COUNT(*) as total_users,
    COUNT(student_id) as users_with_id,
    COUNT(*) - COUNT(student_id) as users_without_id
FROM profiles;

-- 2. Show users without student_id
SELECT id, name, email, student_id, created_at
FROM profiles
WHERE student_id IS NULL
ORDER BY created_at
LIMIT 10;

-- 3. Assign student_id to all users who don't have one
UPDATE profiles
SET student_id = generate_student_id()
WHERE student_id IS NULL;

-- 4. Verify all users now have student_id
SELECT 
    COUNT(*) as total_users,
    COUNT(student_id) as users_with_id,
    COUNT(*) - COUNT(student_id) as users_without_id
FROM profiles;

-- 5. Show sample of assigned IDs
SELECT id, name, email, student_id, created_at
FROM profiles
ORDER BY created_at DESC
LIMIT 10;

-- ============================================================================
-- END OF CONSOLIDATED MIGRATION
-- Generated: 2025-12-13 17:43:58
-- ============================================================================
