import { supabaseAdmin } from '@/lib/supabase/server';
import {
    BookOpen,
    Users,
    MessageSquare,
    TrendingUp,
    Activity,
    Clock
} from 'lucide-react';
import Link from 'next/link';

export const dynamic = 'force-dynamic';

async function getAdminStats() {
    const [
        { count: booksCount },
        { count: usersCount },
        { count: groupsCount },
        { data: recentActivity }
    ] = await Promise.all([
        supabaseAdmin.from('books').select('*', { count: 'exact', head: true }),
        supabaseAdmin.from('profiles').select('*', { count: 'exact', head: true }),
        supabaseAdmin.from('groups').select('*', { count: 'exact', head: true }),
        supabaseAdmin
            .from('admin_logs')
            .select('*')
            .order('created_at', { ascending: false })
            .limit(5)
    ]);

    return {
        booksCount: booksCount || 0,
        usersCount: usersCount || 0,
        groupsCount: groupsCount || 0,
        recentActivity: recentActivity || []
    };
}

export default async function AdminDashboard() {
    const { booksCount, usersCount, groupsCount, recentActivity } = await getAdminStats();

    const stats = [
        {
            label: 'Jami Kitoblar',
            value: booksCount.toLocaleString(),
            icon: BookOpen,
            color: 'text-blue-500',
            bg: 'bg-blue-500/10'
        },
        {
            label: 'Foydalanuvchilar',
            value: usersCount.toLocaleString(),
            icon: Users,
            color: 'text-green-500',
            bg: 'bg-green-500/10'
        },
        {
            label: 'Faol Guruhlar',
            value: groupsCount.toLocaleString(),
            icon: MessageSquare,
            color: 'text-purple-500',
            bg: 'bg-purple-500/10'
        },
        {
            label: 'Tizim Holati',
            value: 'Stabil',
            icon: Activity,
            color: 'text-orange-500',
            bg: 'bg-orange-500/10'
        },
    ];

    return (
        <div className="space-y-6">
            {/* Welcome Section */}
            <div className="bg-gradient-to-r from-primary/10 to-accent/10 border border-primary/20 rounded-2xl p-6">
                <h1 className="text-3xl font-bold mb-2">
                    Admin Panel
                </h1>
                <p className="text-muted-foreground">
                    Tizimni boshqarish va nazorat qilish markazi
                </p>
            </div>

            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                {stats.map((stat, i) => {
                    const Icon = stat.icon;
                    return (
                        <div key={i} className="bg-card border border-border rounded-xl p-6 hover:shadow-lg transition-all">
                            <div className="flex items-center justify-between mb-4">
                                <div className={`w-12 h-12 rounded-lg ${stat.bg} flex items-center justify-center`}>
                                    <Icon className={`w-6 h-6 ${stat.color}`} />
                                </div>
                            </div>
                            <p className="text-sm text-muted-foreground mb-1">{stat.label}</p>
                            <p className="text-3xl font-bold">{stat.value}</p>
                        </div>
                    );
                })}
            </div>

            {/* Recent Activity */}
            <div className="bg-card border border-border rounded-xl p-6">
                <div className="flex items-center justify-between mb-6">
                    <h2 className="text-xl font-bold flex items-center gap-2">
                        <Clock className="w-5 h-5 text-primary" />
                        So'nggi Faoliyat (Loglar)
                    </h2>
                </div>
                <div className="space-y-4">
                    {recentActivity.length > 0 ? (
                        recentActivity.map((activity, i) => (
                            <div key={i} className="flex items-start gap-4 p-4 rounded-lg hover:bg-muted/50 transition-colors border border-border/50">
                                <div className="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center flex-shrink-0">
                                    <Activity className="w-5 h-5 text-primary" />
                                </div>
                                <div className="flex-1">
                                    <p className="font-medium">{activity.action}</p>
                                    <p className="text-sm text-muted-foreground">
                                        {activity.details ? JSON.stringify(activity.details) : 'Batafsil ma\'lumot yo\'q'}
                                    </p>
                                </div>
                                <span className="text-xs text-muted-foreground whitespace-nowrap">
                                    {new Date(activity.created_at).toLocaleString()}
                                </span>
                            </div>
                        ))
                    ) : (
                        <div className="text-center py-8 text-muted-foreground">
                            Hozircha loglar mavjud emas
                        </div>
                    )}
                </div>
            </div>

            {/* Quick Actions */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <Link href="/admin/books/create" className="p-6 bg-card border border-border rounded-xl hover:border-primary hover:shadow-lg transition-all text-left group">
                    <BookOpen className="w-8 h-8 text-primary mb-3 group-hover:scale-110 transition-transform" />
                    <h3 className="font-bold mb-1">Kitob Qo'shish</h3>
                    <p className="text-sm text-muted-foreground">Yangi kitob qo'shing</p>
                </Link>

                <Link href="/admin/users" className="p-6 bg-card border border-border rounded-xl hover:border-primary hover:shadow-lg transition-all text-left group">
                    <Users className="w-8 h-8 text-primary mb-3 group-hover:scale-110 transition-transform" />
                    <h3 className="font-bold mb-1">Foydalanuvchilar</h3>
                    <p className="text-sm text-muted-foreground">Foydalanuvchilarni boshqarish</p>
                </Link>

                <Link href="/admin/analytics" className="p-6 bg-card border border-border rounded-xl hover:border-primary hover:shadow-lg transition-all text-left group">
                    <TrendingUp className="w-8 h-8 text-primary mb-3 group-hover:scale-110 transition-transform" />
                    <h3 className="font-bold mb-1">Hisobotlar</h3>
                    <p className="text-sm text-muted-foreground">Statistikani ko'rish</p>
                </Link>
            </div>
        </div>
    );
}
