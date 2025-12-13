-- ============================================================================
-- COMPLETE DATABASE SETUP - UniLib Platform
-- Date: 2025-12-13
-- Description: Complete database schema with all tables, indexes, triggers, and RLS
-- Version: Final Production
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- SECTION 1: CORE TABLES (if not exist)
-- ============================================================================

-- Note: Most tables already exist from Supabase setup
-- This section only adds missing columns and constraints

-- Profiles table enhancements
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS student_id TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS student_number TEXT,
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS faculty TEXT,
ADD COLUMN IF NOT EXISTS group_name TEXT,
ADD COLUMN IF NOT EXISTS course INTEGER,
ADD COLUMN IF NOT EXISTS education_form TEXT,
ADD COLUMN IF NOT EXISTS specialty TEXT,
ADD COLUMN IF NOT EXISTS gpa NUMERIC(3,2),
ADD COLUMN IF NOT EXISTS last_synced_at TIMESTAMPTZ;

-- ============================================================================
-- SECTION 2: OFFLINE LIBRARY SYSTEM
-- ============================================================================

-- Book copies table
CREATE TABLE IF NOT EXISTS book_copies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    copy_number TEXT NOT NULL,
    barcode TEXT UNIQUE NOT NULL,
    status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'checked_out', 'reserved', 'maintenance', 'lost')),
    condition TEXT DEFAULT 'good' CHECK (condition IN ('excellent', 'good', 'fair', 'poor', 'damaged')),
    location TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(book_id, copy_number)
);

-- Book checkouts table
CREATE TABLE IF NOT EXISTS book_checkouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    copy_id UUID NOT NULL REFERENCES book_copies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    checkout_date TIMESTAMPTZ DEFAULT NOW(),
    due_date TIMESTAMPTZ NOT NULL,
    return_date TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'returned', 'overdue', 'lost')),
    librarian_id UUID REFERENCES profiles(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Library transactions log
CREATE TABLE IF NOT EXISTS library_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('checkout', 'return', 'renew', 'reserve')),
    copy_id UUID REFERENCES book_copies(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    book_id UUID REFERENCES books(id) ON DELETE SET NULL,
    librarian_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    checkout_id UUID REFERENCES book_checkouts(id) ON DELETE SET NULL,
    transaction_date TIMESTAMPTZ DEFAULT NOW(),
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- SECTION 3: PERFORMANCE INDEXES
-- ============================================================================

-- Profiles indexes
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_university ON profiles(university);
CREATE INDEX IF NOT EXISTS idx_profiles_student_number ON profiles(student_number);
CREATE INDEX IF NOT EXISTS idx_profiles_student_id ON profiles(student_id);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON profiles(created_at);

-- Books indexes
CREATE INDEX IF NOT EXISTS idx_books_category ON books(category);
CREATE INDEX IF NOT EXISTS idx_books_language ON books(language);
CREATE INDEX IF NOT EXISTS idx_books_year ON books(year);
CREATE INDEX IF NOT EXISTS idx_books_rating ON books(rating DESC);
CREATE INDEX IF NOT EXISTS idx_books_views_count ON books(views_count DESC);
CREATE INDEX IF NOT EXISTS idx_books_created_at ON books(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_books_title_trgm ON books USING gin(title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_books_author_trgm ON books USING gin(author gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_books_isbn ON books(isbn);

-- Book copies indexes
CREATE INDEX IF NOT EXISTS idx_book_copies_book_id ON book_copies(book_id);
CREATE INDEX IF NOT EXISTS idx_book_copies_barcode ON book_copies(barcode);
CREATE INDEX IF NOT EXISTS idx_book_copies_status ON book_copies(status);

-- Book checkouts indexes
CREATE INDEX IF NOT EXISTS idx_book_checkouts_user_id ON book_checkouts(user_id);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_book_id ON book_checkouts(book_id);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_copy_id ON book_checkouts(copy_id);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_status ON book_checkouts(status);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_checkout_date ON book_checkouts(checkout_date DESC);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_due_date ON book_checkouts(due_date);
CREATE INDEX IF NOT EXISTS idx_book_checkouts_user_status ON book_checkouts(user_id, status);

-- Library transactions indexes
CREATE INDEX IF NOT EXISTS idx_library_transactions_user_id ON library_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_library_transactions_book_id ON library_transactions(book_id);
CREATE INDEX IF NOT EXISTS idx_library_transactions_type ON library_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_library_transactions_date ON library_transactions(transaction_date DESC);

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
-- SECTION 4: STUDENT ID SYSTEM
-- ============================================================================

-- Function to get or create sequence for a year
CREATE OR REPLACE FUNCTION get_year_sequence(year_suffix TEXT)
RETURNS TEXT AS $$
DECLARE
    seq_name TEXT;
BEGIN
    seq_name := 'student_id_seq_' || year_suffix;
    EXECUTE format('CREATE SEQUENCE IF NOT EXISTS %I START 1', seq_name);
    RETURN seq_name;
END;
$$ LANGUAGE plpgsql;

-- Function to generate year-based student ID
CREATE OR REPLACE FUNCTION generate_student_id()
RETURNS TEXT AS $$
DECLARE
    current_year TEXT;
    year_suffix TEXT;
    seq_name TEXT;
    next_id INTEGER;
    student_id TEXT;
BEGIN
    current_year := to_char(CURRENT_DATE, 'YY');
    year_suffix := current_year;
    seq_name := get_year_sequence(year_suffix);
    EXECUTE format('SELECT nextval(%L)', seq_name) INTO next_id;
    student_id := year_suffix || LPAD(next_id::TEXT, 3, '0');
    RETURN student_id;
END;
$$ LANGUAGE plpgsql;

-- Trigger function to auto-generate student_id
CREATE OR REPLACE FUNCTION auto_generate_student_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.student_id IS NULL THEN
        NEW.student_id := generate_student_id();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_auto_generate_student_id ON profiles;
CREATE TRIGGER trigger_auto_generate_student_id
    BEFORE INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_student_id();

-- Assign student_id to existing users
UPDATE profiles
SET student_id = generate_student_id()
WHERE student_id IS NULL;

-- ============================================================================
-- SECTION 5: RLS POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE book_copies ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_checkouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE library_transactions ENABLE ROW LEVEL SECURITY;

-- Book copies policies
DROP POLICY IF EXISTS "Anyone can view available book copies" ON book_copies;
CREATE POLICY "Anyone can view available book copies" ON book_copies
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Librarians can manage book copies" ON book_copies;
CREATE POLICY "Librarians can manage book copies" ON book_copies
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('librarian', 'admin', 'superadmin')
        )
    );

-- Book checkouts policies
DROP POLICY IF EXISTS "Users can view their own checkouts" ON book_checkouts;
CREATE POLICY "Users can view their own checkouts" ON book_checkouts
    FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Librarians can view all checkouts" ON book_checkouts;
CREATE POLICY "Librarians can view all checkouts" ON book_checkouts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('librarian', 'admin', 'superadmin')
        )
    );

DROP POLICY IF EXISTS "Librarians can manage checkouts" ON book_checkouts;
CREATE POLICY "Librarians can manage checkouts" ON book_checkouts
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('librarian', 'admin', 'superadmin')
        )
    );

-- Library transactions policies
DROP POLICY IF EXISTS "Users can view their own transactions" ON library_transactions;
CREATE POLICY "Users can view their own transactions" ON library_transactions
    FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Librarians can view all transactions" ON library_transactions;
CREATE POLICY "Librarians can view all transactions" ON library_transactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('librarian', 'admin', 'superadmin')
        )
    );

DROP POLICY IF EXISTS "Librarians can create transactions" ON library_transactions;
CREATE POLICY "Librarians can create transactions" ON library_transactions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('librarian', 'admin', 'superadmin')
        )
    );

-- ============================================================================
-- SECTION 6: HELPER FUNCTIONS
-- ============================================================================

-- Function to update book copy status
CREATE OR REPLACE FUNCTION update_book_copy_status()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE book_copies
        SET status = 'checked_out', updated_at = NOW()
        WHERE id = NEW.copy_id;
    ELSIF TG_OP = 'UPDATE' AND NEW.status = 'returned' THEN
        UPDATE book_copies
        SET status = 'available', updated_at = NOW()
        WHERE id = NEW.copy_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for book copy status
DROP TRIGGER IF EXISTS trigger_update_book_copy_status ON book_checkouts;
CREATE TRIGGER trigger_update_book_copy_status
    AFTER INSERT OR UPDATE ON book_checkouts
    FOR EACH ROW
    EXECUTE FUNCTION update_book_copy_status();

-- ============================================================================
-- SECTION 7: COMMENTS
-- ============================================================================

COMMENT ON COLUMN profiles.student_id IS 'Short 5-digit student ID (25001, 25002, etc.)';
COMMENT ON TABLE book_copies IS 'Physical copies of books in the library';
COMMENT ON TABLE book_checkouts IS 'Book checkout records';
COMMENT ON TABLE library_transactions IS 'Complete log of all library transactions';

-- ============================================================================
-- SECTION 8: VERIFICATION
-- ============================================================================

-- Count indexes
SELECT COUNT(*) as total_indexes
FROM pg_indexes
WHERE schemaname = 'public';

-- Verify student IDs
SELECT 
    COUNT(*) as total_users,
    COUNT(student_id) as users_with_id,
    COUNT(*) - COUNT(student_id) as users_without_id
FROM profiles;

-- Verify triggers
SELECT trigger_name, event_object_table, action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND trigger_name IN ('trigger_auto_generate_student_id', 'trigger_update_book_copy_status');

-- ============================================================================
-- END OF COMPLETE MIGRATION
-- ============================================================================
