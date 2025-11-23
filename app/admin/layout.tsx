"use client";

import { useState } from 'react';
import { AdminRoute } from '@/components/admin/AdminRoute';
import { AdminSidebar } from '@/components/admin/AdminSidebar';
import { AdminHeader } from '@/components/admin/AdminHeader';

export default function AdminLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    const [isSidebarOpen, setIsSidebarOpen] = useState(false);

    return (
        <AdminRoute>
            <div className="flex min-h-screen bg-background">
                <AdminSidebar
                    isOpen={isSidebarOpen}
                    onClose={() => setIsSidebarOpen(false)}
                />
                <div className="flex-1 flex flex-col min-w-0">
                    <AdminHeader onMenuClick={() => setIsSidebarOpen(true)} />
                    <main className="flex-1 p-4 md:p-6 overflow-x-auto">
                        {children}
                    </main>
                </div>
            </div>
        </AdminRoute>
    );
}
