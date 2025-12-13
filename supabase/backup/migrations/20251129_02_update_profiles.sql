-- Migration: 02_update_profiles
-- Description: Add organization_id and roles to profiles, migrate existing users

-- 1. Add columns
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'student' 
    CHECK (role IN ('super_admin', 'system_admin', 'org_admin', 'head_librarian', 'librarian', 'teacher', 'parent', 'student'));
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS student_id TEXT UNIQUE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS parent_phone TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS bio TEXT;

-- 2. Migrate existing users to default organization
UPDATE profiles 
SET organization_id = (SELECT id FROM organizations WHERE slug = 'unilib-platform')
WHERE organization_id IS NULL;

-- 3. Make organization_id required
ALTER TABLE profiles ALTER COLUMN organization_id SET NOT NULL;

-- 4. Create indexes
CREATE INDEX IF NOT EXISTS idx_profiles_organization_id ON profiles(organization_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- 5. Basic RLS: Allow users to view their own profile (Critical for Auth)
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

-- 6. Basic RLS: Allow users to update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);
