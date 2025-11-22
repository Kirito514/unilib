"use client";

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { Permission } from '@/lib/permissions';

interface AdminRouteProps {
    children: React.ReactNode;
    requiredPermission?: Permission;
    requireSuperAdmin?: boolean;
}

export function AdminRoute({ children, requiredPermission, requireSuperAdmin }: AdminRouteProps) {
    const { user, isLoading, isAdmin, isSuperAdmin, hasPermission } = useAuth();
    const router = useRouter();

    useEffect(() => {
        if (!isLoading) {
            // Not logged in
            if (!user) {
                router.push('/login');
                return;
            }

            // Require super admin
            if (requireSuperAdmin && !isSuperAdmin()) {
                router.push('/dashboard');
                return;
            }

            // Require specific permission
            if (requiredPermission && !hasPermission(requiredPermission)) {
                router.push('/dashboard');
                return;
            }

            // Require any admin role
            if (!requireSuperAdmin && !requiredPermission && !isAdmin()) {
                router.push('/dashboard');
                return;
            }
        }
    }, [user, isLoading, router, requireSuperAdmin, requiredPermission, isAdmin, isSuperAdmin, hasPermission]);

    if (isLoading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-background">
                <div className="text-center">
                    <div className="w-16 h-16 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
                    <p className="text-muted-foreground">Yuklanmoqda...</p>
                </div>
            </div>
        );
    }

    // Check permissions
    if (!user) return null;
    if (requireSuperAdmin && !isSuperAdmin()) return null;
    if (requiredPermission && !hasPermission(requiredPermission)) return null;
    if (!requireSuperAdmin && !requiredPermission && !isAdmin()) return null;

    return <>{children}</>;
}
