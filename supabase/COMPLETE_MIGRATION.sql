-- ============================================================================
-- COMPLETE DATABASE MIGRATION - UniLib Platform
-- Date: 2025-12-13
-- Description: Complete migration including all optimizations, indexes, and features
-- ============================================================================

-- ============================================================================
-- SECTION 1: PERFORMANCE INDEXES
-- ============================================================================

-- Profiles table indexes
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_university ON profiles(university);
CREATE INDEX IF NOT EXISTS idx_profiles_student_number ON profiles(student_number);
CREATE INDEX IF NOT EXISTS idx_profiles_student_id ON profiles(student_id);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON profiles(created_at);

-- Books table indexes
CREATE INDEX IF NOT EXISTS idx_books_category ON books(category);
CREATE INDEX IF NOT EXISTS idx_books_language ON books(language);
CREATE INDEX IF NOT EXISTS idx_books_year ON books(year);
CREATE INDEX IF NOT EXISTS idx_books_rating ON books(rating DESC);
CREATE INDEX IF NOT EXISTS idx_books_views_count ON books(views_count DESC);
CREATE INDEX IF NOT EXISTS idx_books_created_at ON books(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_books_title_trgm ON books USING gin(title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_books_author_trgm ON books USING gin(author gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_books_isbn ON books(isbn);

-- Book checkouts indexes
CREATE INDEX IF NOT EXISTS idx_book_checkouts_user_id ON book_checkouts(user_id);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_book_id ON book_checkouts(book_id);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_status ON book_checkouts(status);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_checkout_date ON book_checkouts(checkout_date DESC);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_due_date ON book_checkouts(due_date);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_user_status ON book_checkouts(user_id, status);

-- Reading schedule indexes
CREATE INDEX IF NOT EXISTS idx_reading_schedule_user_id ON reading_schedule(user_id);
CREATE INDEX IF NOT EXISTS idx_reading_schedule_book_id ON reading_schedule(book_id);
CREATE INDEX IF NOT EXISTS idx_reading_schedule_date ON reading_schedule(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_reading_schedule_completed ON reading_schedule(completed);
CREATE INDEX IF NOT EXISTS idx_reading_schedule_user_date ON reading_schedule(user_id, scheduled_date);

-- Study groups indexes
CREATE INDEX IF NOT EXISTS idx_study_groups_created_by ON study_groups(created_by);
CREATE INDEX IF NOT EXISTS idx_study_groups_created_at ON study_groups(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_study_groups_is_private ON study_groups(is_private);

-- Group members indexes
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_role ON group_members(role);
CREATE INDEX IF NOT EXISTS idx_group_members_group_user ON group_members(group_id, user_id);

-- Group messages indexes
CREATE INDEX IF NOT EXISTS idx_group_messages_group_id ON group_messages(group_id);
CREATE INDEX IF NOT EXISTS idx_group_messages_user_id ON group_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_group_messages_created_at ON group_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_group_messages_group_created ON group_messages(group_id, created_at DESC);

-- Achievements indexes
CREATE INDEX IF NOT EXISTS idx_achievements_category ON achievements(category);
CREATE INDEX IF NOT EXISTS idx_achievements_points ON achievements(points);

-- User achievements indexes
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement_id ON user_achievements(achievement_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_earned_at ON user_achievements(earned_at DESC);

-- Citations indexes
CREATE INDEX IF NOT EXISTS idx_citations_user_id ON citations(user_id);
CREATE INDEX IF NOT EXISTS idx_citations_book_id ON citations(book_id);
CREATE INDEX IF NOT EXISTS idx_citations_style ON citations(style);
CREATE INDEX IF NOT EXISTS idx_citations_created_at ON citations(created_at DESC);

-- Notifications indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, read);
CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON notifications(user_id, created_at DESC);

-- ============================================================================
-- SECTION 2: STUDENT ID SYSTEM
-- ============================================================================

-- Add student_id column if not exists
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS student_id TEXT UNIQUE;

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

-- Trigger function to auto-generate student_id
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

-- Drop existing trigger if any
DROP TRIGGER IF EXISTS trigger_auto_generate_student_id ON profiles;

-- Create trigger
CREATE TRIGGER trigger_auto_generate_student_id
    BEFORE INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_student_id();

-- Assign student_id to existing users who don't have one
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

-- ============================================================================
-- SECTION 3: COMMENTS AND DOCUMENTATION
-- ============================================================================

COMMENT ON COLUMN profiles.student_id IS 'Short 5-digit student ID for manual input (25001, 25002, etc.)';

-- ============================================================================
-- SECTION 4: VERIFICATION QUERIES
-- ============================================================================

-- Verify indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Verify student_id assignment
SELECT 
    COUNT(*) as total_users,
    COUNT(student_id) as users_with_id,
    COUNT(*) - COUNT(student_id) as users_without_id
FROM profiles;

-- Verify trigger
SELECT 
    trigger_name, 
    event_manipulation, 
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'profiles' 
AND trigger_name = 'trigger_auto_generate_student_id';

-- Sample of student IDs
SELECT id, name, email, student_id, student_number, created_at
FROM profiles
ORDER BY created_at DESC
LIMIT 10;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
