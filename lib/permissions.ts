// Role types
export type UserRole = 'USER' | 'LIBRARIAN' | 'MODERATOR' | 'SUPER_ADMIN';

// Permission types
export type Permission =
    | 'books:create'
    | 'books:read'
    | 'books:update'
    | 'books:delete'
    | 'users:read'
    | 'users:update'
    | 'users:delete'
    | 'users:change_role'
    | 'groups:moderate'
    | 'groups:delete'
    | 'analytics:view'
    | 'settings:manage';

// Role to permissions mapping
export const ROLE_PERMISSIONS: Record<UserRole, Permission[]> = {
    USER: [],

    LIBRARIAN: [
        'books:create',
        'books:read',
        'books:update',
        'books:delete',
        'analytics:view',
    ],

    MODERATOR: [
        'groups:moderate',
        'groups:delete',
        'users:read',
        'analytics:view',
    ],

    SUPER_ADMIN: [
        'books:create',
        'books:read',
        'books:update',
        'books:delete',
        'users:read',
        'users:update',
        'users:delete',
        'users:change_role',
        'groups:moderate',
        'groups:delete',
        'analytics:view',
        'settings:manage',
    ],
};

// Check if a role has a specific permission
export function hasPermission(role: UserRole, permission: Permission): boolean {
    return ROLE_PERMISSIONS[role]?.includes(permission) ?? false;
}

// Check if a role has any of the specified permissions
export function hasAnyPermission(role: UserRole, permissions: Permission[]): boolean {
    return permissions.some(permission => hasPermission(role, permission));
}

// Check if a role has all of the specified permissions
export function hasAllPermissions(role: UserRole, permissions: Permission[]): boolean {
    return permissions.every(permission => hasPermission(role, permission));
}

// Check if a role is admin (any admin type)
export function isAdmin(role: UserRole): boolean {
    return role !== 'USER';
}

// Check if a role is super admin
export function isSuperAdmin(role: UserRole): boolean {
    return role === 'SUPER_ADMIN';
}

// Get role display name
export function getRoleDisplayName(role: UserRole): string {
    const names: Record<UserRole, string> = {
        USER: 'Foydalanuvchi',
        LIBRARIAN: 'Kutubxonachi',
        MODERATOR: 'Moderator',
        SUPER_ADMIN: 'Super Admin',
    };
    return names[role];
}

// Get role color for badges
export function getRoleColor(role: UserRole): string {
    const colors: Record<UserRole, string> = {
        USER: 'bg-gray-500',
        LIBRARIAN: 'bg-blue-500',
        MODERATOR: 'bg-purple-500',
        SUPER_ADMIN: 'bg-red-500',
    };
    return colors[role];
}
