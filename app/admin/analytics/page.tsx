import { supabaseAdmin } from '@/lib/supabase/server';
import { AnalyticsCharts } from '@/components/admin/AnalyticsCharts';
import { BarChart3 } from 'lucide-react';

export const dynamic = 'force-dynamic';

async function getAnalyticsData() {
    // In a real app, we would use a more complex query or a dedicated analytics table
    // For now, we'll fetch all records and aggregate them in JS (not efficient for large data, but fine for MVP)

    const [
        { data: users },
        { data: books },
        { data: groups }
    ] = await Promise.all([
        supabaseAdmin.from('profiles').select('created_at'),
        supabaseAdmin.from('books').select('created_at'),
        supabaseAdmin.from('groups').select('created_at')
    ]);

    // Helper to group by date (last 7 days)
    const getLast7Days = () => {
        const days = [];
        for (let i = 6; i >= 0; i--) {
            const d = new Date();
            d.setDate(d.getDate() - i);
            days.push(d.toISOString().split('T')[0]);
        }
        return days;
    };

    const days = getLast7Days();

    const userGrowth = days.map(date => ({
        date,
        count: users?.filter(u => u.created_at.startsWith(date)).length || 0
    }));

    // Accumulate counts for line chart
    let totalUsers = 0;
    const accumulatedUserGrowth = userGrowth.map(day => {
        totalUsers += day.count;
        return { ...day, count: totalUsers };
    });

    const contentGrowth = days.map(date => ({
        date,
        books: books?.filter(b => b.created_at.startsWith(date)).length || 0,
        groups: groups?.filter(g => g.created_at.startsWith(date)).length || 0
    }));

    return {
        userGrowth: accumulatedUserGrowth,
        contentGrowth
    };
}

export default async function AnalyticsPage() {
    const { userGrowth, contentGrowth } = await getAnalyticsData();

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold flex items-center gap-2">
                        <BarChart3 className="w-8 h-8 text-primary" />
                        Statistika
                    </h1>
                    <p className="text-muted-foreground mt-1">
                        Tizim o'sish ko'rsatkichlari
                    </p>
                </div>
            </div>

            <AnalyticsCharts
                userGrowth={userGrowth}
                contentGrowth={contentGrowth}
            />
        </div>
    );
}
