"use client";

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { BookOpen, LayoutDashboard, User } from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';

export function MobileNav() {
    const pathname = usePathname();
    const { user } = useAuth();

    if (!user || pathname === '/' || pathname === '/login' || pathname === '/register') {
        return null;
    }

    const navItems = [
        { href: '/library', label: 'Kutubxona', icon: BookOpen },
        { href: '/dashboard', label: 'Kabinet', icon: LayoutDashboard },
        { href: '/profile', label: 'Profil', icon: User },
    ];

    return (
        <div className="md:hidden fixed bottom-0 left-0 right-0 z-50 bg-background/80 backdrop-blur-xl border-t border-border/40 pb-safe-area-bottom">
            <nav className="flex items-center justify-around px-2 py-3">
                {navItems.map((item) => {
                    const isActive = pathname === item.href || pathname.startsWith(item.href + '/');
                    const Icon = item.icon;

                    return (
                        <Link
                            key={item.href}
                            href={item.href}
                            className={`flex flex-col items-center justify-center w-full transition-all duration-300 group`}
                        >
                            <div className={`relative px-5 py-1.5 rounded-full transition-all duration-300 ease-out ${isActive
                                    ? 'bg-primary text-primary-foreground translate-y-0'
                                    : 'text-muted-foreground hover:bg-muted/50'
                                }`}>
                                <Icon className={`w-6 h-6 ${isActive ? 'fill-current' : ''}`} />
                            </div>

                            <span className={`text-[10px] font-medium mt-1 transition-all duration-300 ${isActive
                                    ? 'text-primary opacity-100 translate-y-0'
                                    : 'text-muted-foreground opacity-70 scale-90'
                                }`}>
                                {item.label}
                            </span>
                        </Link>
                    );
                })}
            </nav>
        </div>
    );
}
