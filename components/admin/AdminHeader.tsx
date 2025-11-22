"use client";

import { useAuth } from '@/contexts/AuthContext';
import { getRoleDisplayName, getRoleColor } from '@/lib/permissions';
import { Bell, LogOut } from 'lucide-react';
import { useRouter } from 'next/navigation';

export function AdminHeader() {
    const { user, logout } = useAuth();
    const router = useRouter();

    const handleLogout = () => {
        logout();
        router.push('/');
    };

    if (!user) return null;

    return (
        <header className="h-16 border-b border-border bg-card/50 backdrop-blur-sm sticky top-0 z-10">
            <div className="h-full px-6 flex items-center justify-between">
                <div>
                    <h2 className="text-lg font-semibold">Boshqaruv paneli</h2>
                    <p className="text-xs text-muted-foreground">UniLib Admin</p>
                </div>

                <div className="flex items-center gap-4">
                    {/* Notifications */}
                    <button className="p-2 hover:bg-muted rounded-lg transition-colors relative">
                        <Bell className="w-5 h-5 text-muted-foreground" />
                        <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
                    </button>

                    {/* User Info */}
                    <div className="flex items-center gap-3 pl-4 border-l border-border">
                        <div className="text-right">
                            <p className="text-sm font-medium">{user.name}</p>
                            <div className="flex items-center gap-2">
                                <span className={`text-xs px-2 py-0.5 rounded-full text-white ${getRoleColor(user.role)}`}>
                                    {getRoleDisplayName(user.role)}
                                </span>
                            </div>
                        </div>
                        <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-accent flex items-center justify-center font-bold text-white">
                            {user.name.charAt(0).toUpperCase()}
                        </div>
                    </div>

                    {/* Logout */}
                    <button
                        onClick={handleLogout}
                        className="p-2 hover:bg-red-500/10 text-red-500 rounded-lg transition-colors"
                        title="Chiqish"
                    >
                        <LogOut className="w-5 h-5" />
                    </button>
                </div>
            </div>
        </header>
    );
}
