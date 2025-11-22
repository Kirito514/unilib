export default function Loading() {
    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div className="space-y-2">
                    <div className="h-8 w-48 bg-muted rounded animate-pulse" />
                    <div className="h-4 w-64 bg-muted rounded animate-pulse" />
                </div>
                <div className="h-10 w-32 bg-muted rounded animate-pulse" />
            </div>

            <div className="bg-card border border-border rounded-xl overflow-hidden">
                <div className="p-4 border-b border-border flex items-center gap-4">
                    <div className="h-10 flex-1 bg-muted rounded animate-pulse" />
                </div>
                <div className="divide-y divide-border">
                    {[1, 2, 3, 4, 5].map((i) => (
                        <div key={i} className="p-4 flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <div className="w-10 h-14 bg-muted rounded animate-pulse" />
                                <div className="space-y-2">
                                    <div className="h-4 w-48 bg-muted rounded animate-pulse" />
                                    <div className="h-3 w-32 bg-muted rounded animate-pulse" />
                                </div>
                            </div>
                            <div className="h-4 w-32 bg-muted rounded animate-pulse" />
                            <div className="h-6 w-20 bg-muted rounded animate-pulse" />
                            <div className="h-4 w-12 bg-muted rounded animate-pulse" />
                            <div className="flex gap-2">
                                <div className="w-8 h-8 bg-muted rounded animate-pulse" />
                                <div className="w-8 h-8 bg-muted rounded animate-pulse" />
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
}
