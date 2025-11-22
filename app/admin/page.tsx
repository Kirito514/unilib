"use client";

import { useAuth } from '@/contexts/AuthContext';
import { getRoleDisplayName } from '@/lib/permissions';
import {
    BookOpen,
    Users,
    MessageSquare,
    TrendingUp,
    Activity,
    Clock
} from 'lucide-react';

export default function AdminDashboard() {
    const { user } = useAuth();

    const stats = [
        {
            label: 'Jami Kitoblar',
            value: '1,234',
            icon: BookOpen,
            color: 'text-blue-500',
            bg: 'bg-blue-500/10'
        },
        {
            label: 'Foydalanuvchilar',
            value: '856',
            icon: Users,
            color: 'text-green-500',
            bg: 'bg-green-500/10'
        },
        {
            label: 'Faol Guruhlar',
            value: '42',
            icon: MessageSquare,
            color: 'text-purple-500',
            bg: 'bg-purple-500/10'
        },
        {
            label: 'Bugungi Faollik',
            value: '234',
            icon: TrendingUp,
            color: 'text-orange-500',
            bg: 'bg-orange-500/10'
        },
    ];

    const recentActivity = [
        { action: 'Yangi kitob qo\'shildi', user: 'Admin', time: '5 daqiqa oldin', icon: BookOpen },
        { action: 'Foydalanuvchi ro\'yxatdan o\'tdi', user: 'Jasur Karimov', time: '15 daqiqa oldin', icon: Users },
        { action: 'Guruh yaratildi', user: 'Malika Saidova', time: '1 soat oldin', icon: MessageSquare },
        { action: 'Kitob tahrirlandi', user: 'Librarian', time: '2 soat oldin', icon: Activity },
    ];

    return (
        <div className="space-y-6">
            {/* Welcome Section */}
            <div className="bg-gradient-to-r from-primary/10 to-accent/10 border border-primary/20 rounded-2xl p-6">
                <h1 className="text-3xl font-bold mb-2">
                    Xush kelibsiz, {user?.name}! 👋
                </h1>
                <p className="text-muted-foreground">
                    Sizning rolingiz: <span className="font-semibold text-primary">{user && getRoleDisplayName(user.role)}</span>
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
                        So'nggi Faoliyat
                    </h2>
                </div>
                <div className="space-y-4">
                    {recentActivity.map((activity, i) => {
                        const Icon = activity.icon;
                        return (
                            <div key={i} className="flex items-start gap-4 p-4 rounded-lg hover:bg-muted/50 transition-colors">
                                <div className="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center flex-shrink-0">
                                    <Icon className="w-5 h-5 text-primary" />
                                </div>
                                <div className="flex-1">
                                    <p className="font-medium">{activity.action}</p>
                                    <p className="text-sm text-muted-foreground">{activity.user}</p>
                                </div>
                                <span className="text-xs text-muted-foreground">{activity.time}</span>
                            </div>
                        );
                    })}
                </div>
            </div>

            {/* Quick Actions */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <button className="p-6 bg-card border border-border rounded-xl hover:border-primary hover:shadow-lg transition-all text-left group">
                    <BookOpen className="w-8 h-8 text-primary mb-3 group-hover:scale-110 transition-transform" />
                    <h3 className="font-bold mb-1">Kitob Qo'shish</h3>
                    <p className="text-sm text-muted-foreground">Yangi kitob qo'shing</p>
                </button>

                <button className="p-6 bg-card border border-border rounded-xl hover:border-primary hover:shadow-lg transition-all text-left group">
                    <Users className="w-8 h-8 text-primary mb-3 group-hover:scale-110 transition-transform" />
                    <h3 className="font-bold mb-1">Foydalanuvchilar</h3>
                    <p className="text-sm text-muted-foreground">Foydalanuvchilarni boshqarish</p>
                </button>

                <button className="p-6 bg-card border border-border rounded-xl hover:border-primary hover:shadow-lg transition-all text-left group">
                    <Activity className="w-8 h-8 text-primary mb-3 group-hover:scale-110 transition-transform" />
                    <h3 className="font-bold mb-1">Hisobotlar</h3>
                    <p className="text-sm text-muted-foreground">Statistikani ko'rish</p>
                </button>
            </div>
        </div>
    );
}
