-- Migration: 07_fix_org_insert_policy
-- Description: Add INSERT/UPDATE/DELETE policies for organizations

-- 1. Allow Super Admins to INSERT organizations
CREATE POLICY "Super admins can insert organizations"
    ON organizations FOR INSERT
    WITH CHECK (
        get_auth_user_role() IN ('super_admin', 'system_admin')
    );

-- 2. Allow Super Admins to UPDATE organizations
CREATE POLICY "Super admins can update organizations"
    ON organizations FOR UPDATE
    USING (
        get_auth_user_role() IN ('super_admin', 'system_admin')
    );

-- 3. Allow Super Admins to DELETE organizations
CREATE POLICY "Super admins can delete organizations"
    ON organizations FOR DELETE
    USING (
        get_auth_user_role() IN ('super_admin', 'system_admin')
    );
