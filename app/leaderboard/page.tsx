"use client";

import { useState, useEffect } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { supabase } from "@/lib/supabase/client";
import { LeaderboardList } from "@/components/leaderboard/LeaderboardList";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Trophy, Flame, Star, Loader2 } from "lucide-react";

export default function LeaderboardPage() {
    const { user } = useAuth();
    const [xpLeaderboard, setXpLeaderboard] = useState<any[]>([]);
    const [streakLeaderboard, setStreakLeaderboard] = useState<any[]>([]);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        const fetchLeaderboards = async () => {
            try {
                // Fetch XP Leaderboard
                const { data: xpData, error: xpError } = await supabase
                    .rpc('get_leaderboard', { limit_count: 50 });

                if (xpError) throw xpError;
                setXpLeaderboard(xpData || []);

                // Fetch Streak Leaderboard
                const { data: streakData, error: streakError } = await supabase
                    .rpc('get_streak_leaderboard', { limit_count: 50 });

                if (streakError) throw streakError;
                setStreakLeaderboard(streakData || []);

            } catch (error: any) {
                console.error("Error fetching leaderboards:", error);
                console.error("Error details:", error?.message, error?.details, error?.hint);
            } finally {
                setIsLoading(false);
            }
        };

        fetchLeaderboards();
    }, []);

    return (
        <div className="container py-8 px-4 md:px-6 max-w-4xl mx-auto">
            <div className="flex items-center gap-3 mb-8">
                <div className="w-12 h-12 rounded-xl bg-yellow-500/10 flex items-center justify-center">
                    <Trophy className="w-6 h-6 text-yellow-500" />
                </div>
                <div>
                    <h1 className="text-3xl font-bold">Reyting</h1>
                    <p className="text-muted-foreground">Eng faol kitobxonlar bilan bellashing</p>
                </div>
            </div>

            <Tabs defaultValue="xp" className="w-full">
                <TabsList className="grid w-full grid-cols-2 mb-8">
                    <TabsTrigger value="xp" className="flex items-center gap-2">
                        <Star className="w-4 h-4" />
                        XP Reytingi
                    </TabsTrigger>
                    <TabsTrigger value="streak" className="flex items-center gap-2">
                        <Flame className="w-4 h-4" />
                        Streak Reytingi
                    </TabsTrigger>
                </TabsList>

                {isLoading ? (
                    <div className="flex justify-center py-12">
                        <Loader2 className="w-8 h-8 animate-spin text-primary" />
                    </div>
                ) : (
                    <>
                        <TabsContent value="xp" className="animate-in fade-in slide-in-from-bottom-4 duration-500">
                            <div className="bg-gradient-to-br from-yellow-500/5 to-orange-500/5 border border-yellow-500/10 rounded-2xl p-6 mb-6">
                                <h2 className="text-lg font-bold mb-2 flex items-center gap-2">
                                    <Trophy className="w-5 h-5 text-yellow-500" />
                                    Eng ko'p XP to'plaganlar
                                </h2>
                                <p className="text-sm text-muted-foreground">
                                    Kitob o'qish va vazifalarni bajarish orqali XP to'plang va reytingda ko'tariling.
                                </p>
                            </div>
                            <LeaderboardList users={xpLeaderboard} currentUserId={user?.id} type="xp" />
                        </TabsContent>

                        <TabsContent value="streak" className="animate-in fade-in slide-in-from-bottom-4 duration-500">
                            <div className="bg-gradient-to-br from-orange-500/5 to-red-500/5 border border-orange-500/10 rounded-2xl p-6 mb-6">
                                <h2 className="text-lg font-bold mb-2 flex items-center gap-2">
                                    <Flame className="w-5 h-5 text-orange-500" />
                                    Eng uzun Streak
                                </h2>
                                <p className="text-sm text-muted-foreground">
                                    Har kuni uzluksiz o'qish orqali streakni saqlab qoling.
                                </p>
                            </div>
                            <LeaderboardList users={streakLeaderboard} currentUserId={user?.id} type="streak" />
                        </TabsContent>
                    </>
                )}
            </Tabs>
        </div>
    );
}
