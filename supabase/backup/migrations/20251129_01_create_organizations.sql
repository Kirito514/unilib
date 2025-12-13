-- Migration: 01_create_organizations
-- Description: Create organizations table and default organization

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Create organizations table
CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('school', 'college', 'university', 'public_library', 'private_library')),
    logo_url TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    address TEXT,
    city TEXT,
    region TEXT,
    settings JSONB DEFAULT '{}',
    subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'basic', 'premium', 'enterprise')),
    subscription_status TEXT DEFAULT 'active' CHECK (subscription_status IN ('active', 'suspended', 'cancelled')),
    max_students INTEGER DEFAULT 200,
    max_books INTEGER,
    max_librarians INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create index
CREATE INDEX IF NOT EXISTS idx_organizations_slug ON organizations(slug);

-- 3. Insert default organization
INSERT INTO organizations (name, slug, type, subscription_tier, subscription_status, max_students, max_books)
VALUES (
    'UniLib Platform',
    'unilib-platform',
    'public_library',
    'enterprise',
    'active',
    999999,
    999999
)
ON CONFLICT (slug) DO NOTHING;

-- 4. Enable RLS (Policies will be added in step 03)
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- 5. Trigger for updated_at
CREATE OR REPLACE FUNCTION update_organizations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_organizations_updated_at_trigger ON organizations;
CREATE TRIGGER update_organizations_updated_at_trigger
    BEFORE UPDATE ON organizations
    FOR EACH ROW
    EXECUTE FUNCTION update_organizations_updated_at();
