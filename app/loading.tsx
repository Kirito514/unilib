import { Loader2 } from 'lucide-react';

export default function Loading() {
    return (
        <div className="container py-10 px-4 md:px-6 max-w-7xl mx-auto animate-pulse">
            {/* Header Skeleton */}
            <div className="mb-8">
                <div className="h-10 w-64 bg-muted rounded mb-2"></div>
                <div className="h-6 w-96 bg-muted rounded"></div>
            </div>

            {/* Stats Grid Skeleton */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
                {[1, 2, 3, 4].map((i) => (
                    <div key={i} className="bg-card border border-border rounded-2xl p-6">
                        <div className="h-8 w-16 bg-muted rounded mb-2"></div>
                        <div className="h-4 w-24 bg-muted rounded"></div>
                    </div>
                ))}
            </div>

            {/* Content Skeleton */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <div className="lg:col-span-2 space-y-6">
                    <div className="bg-card border border-border rounded-2xl p-6">
                        <div className="h-6 w-48 bg-muted rounded mb-4"></div>
                        <div className="space-y-3">
                            <div className="h-4 w-full bg-muted rounded"></div>
                            <div className="h-4 w-3/4 bg-muted rounded"></div>
                        </div>
                    </div>
                </div>
                <div className="space-y-6">
                    <div className="bg-card border border-border rounded-2xl p-6">
                        <div className="h-6 w-32 bg-muted rounded mb-4"></div>
                        <div className="space-y-2">
                            <div className="h-4 w-full bg-muted rounded"></div>
                            <div className="h-4 w-2/3 bg-muted rounded"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
