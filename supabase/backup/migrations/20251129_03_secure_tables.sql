-- Migration: 03_secure_tables
-- Description: Add organization_id to books and implement comprehensive RLS

-- ============================================
-- BOOKS TABLE
-- ============================================

-- 1. Add organization_id to books
ALTER TABLE books ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id);

-- 2. Migrate existing books
UPDATE books 
SET organization_id = (SELECT id FROM organizations WHERE slug = 'unilib-platform')
WHERE organization_id IS NULL;

-- 3. Make required
ALTER TABLE books ALTER COLUMN organization_id SET NOT NULL;
CREATE INDEX IF NOT EXISTS idx_books_organization_id ON books(organization_id);

-- ============================================
-- RLS POLICIES (NON-RECURSIVE)
-- ============================================

-- PROFILES: View others in same org
DROP POLICY IF EXISTS "Users can view org profiles" ON profiles;
CREATE POLICY "Users can view org profiles"
    ON profiles FOR SELECT
    USING (
        organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())
    );

-- PROFILES: Super Admin view all
DROP POLICY IF EXISTS "Super admins can view all profiles" ON profiles;
CREATE POLICY "Super admins can view all profiles"
    ON profiles FOR SELECT
    USING (
        (SELECT role FROM profiles WHERE id = auth.uid()) IN ('super_admin', 'system_admin')
    );

-- ORGANIZATIONS: View own
DROP POLICY IF EXISTS "Users can view own organization" ON organizations;
CREATE POLICY "Users can view own organization"
    ON organizations FOR SELECT
    USING (
        id = (SELECT organization_id FROM profiles WHERE id = auth.uid())
    );

-- ORGANIZATIONS: Super Admin view all
DROP POLICY IF EXISTS "Super admins can view all orgs" ON organizations;
CREATE POLICY "Super admins can view all orgs"
    ON organizations FOR SELECT
    USING (
        (SELECT role FROM profiles WHERE id = auth.uid()) IN ('super_admin', 'system_admin')
    );

-- BOOKS: View own org books
DROP POLICY IF EXISTS "Users can view org books" ON books;
CREATE POLICY "Users can view org books"
    ON books FOR SELECT
    USING (
        organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())
    );

-- BOOKS: Librarians manage books
DROP POLICY IF EXISTS "Librarians can manage books" ON books;
CREATE POLICY "Librarians can manage books"
    ON books FOR ALL
    USING (
        organization_id = (SELECT organization_id FROM profiles WHERE id = auth.uid())
        AND
        (SELECT role FROM profiles WHERE id = auth.uid()) IN ('super_admin', 'org_admin', 'head_librarian', 'librarian')
    );
