-- Migration: 06_nuke_and_fix_rls
-- Description: Completely reset RLS policies for profiles to eliminate infinite recursion

-- 1. Temporarily disable RLS on profiles to break any active recursion loops
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- 2. Drop ALL existing policies on profiles (be exhaustive)
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view org profiles" ON profiles;
DROP POLICY IF EXISTS "Super admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can view org users" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on email" ON profiles;

-- 3. Re-create the SECURITY DEFINER function (ensure it's correct)
CREATE OR REPLACE FUNCTION get_auth_user_organization_id()
RETURNS UUID AS $$
BEGIN
    -- This runs with the privileges of the function creator (postgres/admin)
    -- effectively bypassing RLS on the profiles table
    RETURN (
        SELECT organization_id 
        FROM profiles 
        WHERE id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Create "Safe" Policies

-- Policy 1: Users can ALWAYS view their own profile (Simple, non-recursive)
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

-- Policy 2: Users can view other profiles in their organization (Uses SECURITY DEFINER function)
CREATE POLICY "Users can view org profiles"
    ON profiles FOR SELECT
    USING (
        organization_id = get_auth_user_organization_id()
    );

-- Policy 3: Super Admins can view ALL profiles (Uses SECURITY DEFINER function to check role)
-- We need a separate function for role check to be 100% safe from recursion
CREATE OR REPLACE FUNCTION get_auth_user_role()
RETURNS TEXT AS $$
BEGIN
    RETURN (
        SELECT role 
        FROM profiles 
        WHERE id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE POLICY "Super admins can view all profiles"
    ON profiles FOR SELECT
    USING (
        get_auth_user_role() IN ('super_admin', 'system_admin')
    );

-- Policy 4: Update own profile
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- 5. Re-enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 6. Apply similar fixes to Organizations and Books just in case

-- Organizations
DROP POLICY IF EXISTS "Users can view own organization" ON organizations;
DROP POLICY IF EXISTS "Super admins can view all orgs" ON organizations;

CREATE POLICY "Users can view own organization"
    ON organizations FOR SELECT
    USING (
        id = get_auth_user_organization_id()
    );

CREATE POLICY "Super admins can view all orgs"
    ON organizations FOR SELECT
    USING (
        get_auth_user_role() IN ('super_admin', 'system_admin')
    );

-- Books
DROP POLICY IF EXISTS "Users can view org books" ON books;
DROP POLICY IF EXISTS "Librarians can manage books" ON books;

CREATE POLICY "Users can view org books"
    ON books FOR SELECT
    USING (
        organization_id = get_auth_user_organization_id()
    );

CREATE POLICY "Librarians can manage books"
    ON books FOR ALL
    USING (
        organization_id = get_auth_user_organization_id()
        AND
        get_auth_user_role() IN ('super_admin', 'org_admin', 'head_librarian', 'librarian')
    );
