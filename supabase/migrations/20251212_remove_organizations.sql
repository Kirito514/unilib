-- Remove all organization references from database
-- This migration removes the organizations table and all related columns
-- Date: 2025-12-12

-- Step 1: Drop all RLS policies that reference organizations
DROP POLICY IF EXISTS "Super admins can insert organizations" ON organizations;
DROP POLICY IF EXISTS "Super admins can update organizations" ON organizations;
DROP POLICY IF EXISTS "Super admins can delete organizations" ON organizations;
DROP POLICY IF EXISTS "Users can view profiles in their organization" ON profiles;
DROP POLICY IF EXISTS "Librarians can view all views in their organization" ON library_views;

-- Step 2: Drop functions that reference organizations
DROP FUNCTION IF EXISTS get_auth_user_organization_id() CASCADE;
DROP FUNCTION IF EXISTS get_overdue_checkouts(UUID) CASCADE;
DROP FUNCTION IF EXISTS update_organizations_updated_at() CASCADE;

-- Step 3: Drop indexes related to organization_id
DROP INDEX IF EXISTS idx_library_views_org_id;
DROP INDEX IF EXISTS idx_physical_copies_org;
DROP INDEX IF EXISTS idx_checkouts_org;

-- Step 4: Remove organization_id columns from tables
ALTER TABLE profiles DROP COLUMN IF EXISTS organization_id CASCADE;
ALTER TABLE books DROP COLUMN IF EXISTS organization_id CASCADE;
ALTER TABLE physical_book_copies DROP COLUMN IF EXISTS organization_id CASCADE;
ALTER TABLE book_checkouts DROP COLUMN IF EXISTS organization_id CASCADE;
ALTER TABLE library_views DROP COLUMN IF EXISTS organization_id CASCADE;

-- Check if study_groups table exists before dropping column
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'study_groups') THEN
        ALTER TABLE study_groups DROP COLUMN IF EXISTS organization_id CASCADE;
    END IF;
END $$;

-- Step 5: Drop organizations table
DROP TABLE IF EXISTS organizations CASCADE;

-- Step 6: Recreate simplified RLS policies without organization checks

-- Profiles: Users can view their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

-- Profiles: Users can update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- Profiles: Allow public read for basic info (needed for leaderboards, etc)
DROP POLICY IF EXISTS "Public profiles are viewable by authenticated users" ON profiles;
CREATE POLICY "Public profiles are viewable by authenticated users"
    ON profiles FOR SELECT
    TO authenticated
    USING (true);

-- Books: Anyone authenticated can view books
DROP POLICY IF EXISTS "Anyone can view books" ON books;
CREATE POLICY "Anyone can view books"
    ON books FOR SELECT
    TO authenticated
    USING (true);

-- Physical book copies: Anyone authenticated can view
DROP POLICY IF EXISTS "Anyone can view physical copies" ON physical_book_copies;
CREATE POLICY "Anyone can view physical copies"
    ON physical_book_copies FOR SELECT
    TO authenticated
    USING (true);

-- Book checkouts: Users can view their own checkouts
DROP POLICY IF EXISTS "Users can view own checkouts" ON book_checkouts;
CREATE POLICY "Users can view own checkouts"
    ON book_checkouts FOR SELECT
    USING (auth.uid() = user_id);

-- Library views: Users can view their own library views
DROP POLICY IF EXISTS "Users can view own library views" ON library_views;
CREATE POLICY "Users can view own library views"
    ON library_views FOR SELECT
    USING (auth.uid() = user_id);

-- Step 7: Update handle_new_user trigger to not use organizations
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    -- Create profile for new user
    INSERT INTO public.profiles (
        id,
        email,
        name,
        role,
        xp,
        level,
        streak_days,
        total_pages_read,
        total_books_completed,
        is_active
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        'student',
        0,
        1,
        0,
        0,
        0,
        true
    );
    
    RETURN NEW;
END;
$$;

-- Step 8: Recreate get_overdue_checkouts function without organization parameter
CREATE OR REPLACE FUNCTION get_overdue_checkouts()
RETURNS TABLE (
    checkout_id UUID,
    user_id UUID,
    user_name TEXT,
    user_email TEXT,
    book_id UUID,
    book_title TEXT,
    book_author TEXT,
    copy_id UUID,
    barcode TEXT,
    checkout_date TIMESTAMPTZ,
    due_date TIMESTAMPTZ,
    days_overdue INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bc.id AS checkout_id,
        bc.user_id,
        p.name AS user_name,
        p.email AS user_email,
        b.id AS book_id,
        b.title AS book_title,
        b.author AS book_author,
        pbc.id AS copy_id,
        pbc.barcode,
        bc.checkout_date,
        bc.due_date,
        EXTRACT(DAY FROM NOW() - bc.due_date)::INTEGER AS days_overdue
    FROM book_checkouts bc
    JOIN profiles p ON bc.user_id = p.id
    JOIN physical_book_copies pbc ON bc.copy_id = pbc.id
    JOIN books b ON pbc.book_id = b.id
    WHERE bc.status = 'active'
    AND bc.due_date < NOW()
    ORDER BY bc.due_date ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 9: Update librarian XP update policies
DROP POLICY IF EXISTS "Librarians can update user XP" ON profiles;
CREATE POLICY "Librarians can update user XP"
    ON profiles FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.role IN ('librarian', 'head_librarian', 'org_admin', 'system_admin', 'super_admin')
        )
    );

-- Migration complete: Removed all organization references from database
-- Simplified to single-tenant model
