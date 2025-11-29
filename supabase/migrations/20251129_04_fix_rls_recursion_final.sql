-- Migration: 04_fix_rls_recursion_final
-- Description: Fix recursive RLS policies using SECURITY DEFINER function

-- 1. Create a secure function to get the current user's organization_id
-- This function runs with "SECURITY DEFINER", meaning it bypasses RLS
CREATE OR REPLACE FUNCTION get_auth_user_organization_id()
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT organization_id 
        FROM profiles 
        WHERE id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Update PROFILES policies to use the function
DROP POLICY IF EXISTS "Users can view org profiles" ON profiles;
CREATE POLICY "Users can view org profiles"
    ON profiles FOR SELECT
    USING (
        organization_id = get_auth_user_organization_id()
    );

-- 3. Update ORGANIZATIONS policies
DROP POLICY IF EXISTS "Users can view own organization" ON organizations;
CREATE POLICY "Users can view own organization"
    ON organizations FOR SELECT
    USING (
        id = get_auth_user_organization_id()
    );

-- 4. Update BOOKS policies
DROP POLICY IF EXISTS "Users can view org books" ON books;
CREATE POLICY "Users can view org books"
    ON books FOR SELECT
    USING (
        organization_id = get_auth_user_organization_id()
    );

DROP POLICY IF EXISTS "Librarians can manage books" ON books;
CREATE POLICY "Librarians can manage books"
    ON books FOR ALL
    USING (
        organization_id = get_auth_user_organization_id()
        AND
        (SELECT role FROM profiles WHERE id = auth.uid()) IN ('super_admin', 'org_admin', 'head_librarian', 'librarian')
    );
