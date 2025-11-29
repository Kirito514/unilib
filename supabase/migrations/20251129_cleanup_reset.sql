-- CLEANUP SCRIPT: Reset database to pre-multi-tenant state
-- WARNING: This will delete data in 'organizations' and remove columns from other tables.

-- 1. Drop organizations table
DROP TABLE IF EXISTS organizations CASCADE;

-- 2. Remove columns from profiles
ALTER TABLE profiles DROP COLUMN IF EXISTS organization_id CASCADE;
ALTER TABLE profiles DROP COLUMN IF EXISTS role CASCADE;
ALTER TABLE profiles DROP COLUMN IF EXISTS is_active CASCADE;
ALTER TABLE profiles DROP COLUMN IF EXISTS student_id CASCADE;
ALTER TABLE profiles DROP COLUMN IF EXISTS parent_phone CASCADE;
-- Note: 'bio' might have been there before or added, keeping it safe or removing if it was part of this feature set? 
-- The user mentioned "hamma narsani", but bio is generic. I'll leave bio for now unless requested.

-- 3. Remove columns from books
ALTER TABLE books DROP COLUMN IF EXISTS organization_id CASCADE;

-- 4. Remove columns from study_groups (if it exists)
DO $$ 
BEGIN 
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'study_groups') THEN
        ALTER TABLE study_groups DROP COLUMN IF EXISTS organization_id CASCADE;
    END IF;
END $$;

-- 5. Drop any remaining policies that might not have been cascaded (just in case)
DROP POLICY IF EXISTS "Users can view org profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can view org users" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Super admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view org books" ON books;
DROP POLICY IF EXISTS "Librarians can add books" ON books;
DROP POLICY IF EXISTS "Librarians can update books" ON books;
DROP POLICY IF EXISTS "Librarians can delete books" ON books;

-- 6. Re-enable RLS on tables if we disabled it (optional, but good practice to reset to secure state)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
-- Add back original policies if known? 
-- For now, we just remove the new stuff.

-- 7. Drop functions/triggers
DROP FUNCTION IF EXISTS update_organizations_updated_at CASCADE;
