"use client";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { cn } from "@/lib/utils";
import { Medal, Trophy, Flame, Star } from "lucide-react";

interface LeaderboardItemProps {
    rank: number;
    user: {
        id: string;
        full_name: string;
        avatar_url?: string;
        level: number;
        xp?: number;
        streak_days?: number;
    };
    isCurrentUser?: boolean;
    type: 'xp' | 'streak';
}

export function LeaderboardItem({ rank, user, isCurrentUser, type }: LeaderboardItemProps) {
    const getRankIcon = (rank: number) => {
        switch (rank) {
            case 1:
                return <Trophy className="w-6 h-6 text-yellow-500 fill-yellow-500" />;
            case 2:
                return <Medal className="w-6 h-6 text-gray-400 fill-gray-400" />;
            case 3:
                return <Medal className="w-6 h-6 text-amber-700 fill-amber-700" />;
            default:
                return <span className="font-bold text-muted-foreground w-6 text-center">{rank}</span>;
        }
    };

    const getRankStyle = (rank: number) => {
        switch (rank) {
            case 1:
                return "bg-yellow-500/10 border-yellow-500/20";
            case 2:
                return "bg-gray-400/10 border-gray-400/20";
            case 3:
                return "bg-amber-700/10 border-amber-700/20";
            default:
                return "bg-card border-border hover:bg-accent/5";
        }
    };

    return (
        <div className={cn(
            "flex items-center gap-4 p-4 rounded-xl border transition-all",
            getRankStyle(rank),
            isCurrentUser && "ring-2 ring-primary ring-offset-2 ring-offset-background"
        )}>
            <div className="flex items-center justify-center w-8">
                {getRankIcon(rank)}
            </div>

            <Avatar className="w-10 h-10 border-2 border-background">
                <AvatarImage src={user.avatar_url} />
                <AvatarFallback>{user.full_name?.charAt(0) || 'U'}</AvatarFallback>
            </Avatar>

            <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                    <h3 className="font-bold truncate">
                        {user.full_name || 'Foydalanuvchi'}
                        {isCurrentUser && <span className="ml-2 text-xs bg-primary/10 text-primary px-2 py-0.5 rounded-full">Siz</span>}
                    </h3>
                </div>
                <p className="text-xs text-muted-foreground">
                    {user.level}-daraja
                </p>
            </div>

            <div className="text-right">
                <div className="font-bold text-lg flex items-center justify-end gap-1">
                    {type === 'xp' ? (
                        <>
                            <Star className="w-4 h-4 text-yellow-500 fill-yellow-500" />
                            {user.xp?.toLocaleString()} XP
                        </>
                    ) : (
                        <>
                            <Flame className="w-4 h-4 text-orange-500 fill-orange-500" />
                            {user.streak_days} kun
                        </>
                    )}
                </div>
            </div>
        </div>
    );
}
