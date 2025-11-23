"use client";

import { Bell, CheckCircle, Info, Trophy, AlertTriangle, Clock } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { uz } from 'date-fns/locale';
import Link from 'next/link';

interface NotificationItemProps {
    notification: {
        id: string;
        title: string;
        message: string;
        type: string;
        is_read: boolean;
        created_at: string;
        link?: string;
    };
    onRead: (id: string) => void;
}

export function NotificationItem({ notification, onRead }: NotificationItemProps) {
    const getIcon = () => {
        switch (notification.type) {
            case 'success': return <CheckCircle className="w-5 h-5 text-emerald-500" />;
            case 'warning': return <AlertTriangle className="w-5 h-5 text-amber-500" />;
            case 'achievement': return <Trophy className="w-5 h-5 text-yellow-500" />;
            case 'reminder': return <Clock className="w-5 h-5 text-blue-500" />;
            default: return <Info className="w-5 h-5 text-slate-500" />;
        }
    };

    const Content = () => (
        <div
            className={`flex gap-4 p-4 hover:bg-muted/50 transition-colors cursor-pointer ${!notification.is_read ? 'bg-primary/5' : ''
                }`}
            onClick={() => !notification.is_read && onRead(notification.id)}
        >
            <div className="mt-1">
                {getIcon()}
            </div>
            <div className="flex-1 space-y-1">
                <div className="flex justify-between items-start gap-2">
                    <p className={`text-sm font-medium leading-none ${!notification.is_read ? 'text-foreground' : 'text-muted-foreground'}`}>
                        {notification.title}
                    </p>
                    <span className="text-xs text-muted-foreground whitespace-nowrap">
                        {formatDistanceToNow(new Date(notification.created_at), { addSuffix: true, locale: uz })}
                    </span>
                </div>
                <p className="text-sm text-muted-foreground line-clamp-2">
                    {notification.message}
                </p>
            </div>
            {!notification.is_read && (
                <div className="flex items-center justify-center">
                    <div className="w-2 h-2 rounded-full bg-primary" />
                </div>
            )}
        </div>
    );

    if (notification.link) {
        return (
            <Link href={notification.link} className="block border-b border-border last:border-0">
                <Content />
            </Link>
        );
    }

    return (
        <div className="border-b border-border last:border-0">
            <Content />
        </div>
    );
}
