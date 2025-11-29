"use client";

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';

interface AdminRouteProps {
    children: React.ReactNode;
    requireSuperAdmin?: boolean;
}

export function AdminRoute({ children, requireSuperAdmin }: AdminRouteProps) {
    const { user, isLoading, isAdmin, isSuperAdmin } = useAuth();
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

            // Require any admin role
            if (!requireSuperAdmin && !isAdmin()) {
                router.push('/dashboard');
                return;
            }
        }
    }, [user, isLoading, router, requireSuperAdmin, isAdmin, isSuperAdmin]);

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
    if (!requireSuperAdmin && !isAdmin()) return null;

    return <>{children}</>;
}
