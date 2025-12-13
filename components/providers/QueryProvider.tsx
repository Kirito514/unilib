'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useState } from 'react'

export default function QueryProvider({
    children,
}: {
    children: React.ReactNode
}) {
    const [queryClient] = useState(
        () =>
            new QueryClient({
                defaultOptions: {
                    queries: {
                        // Cache configuration
                        staleTime: 60 * 1000, // 1 minute - data considered fresh
                        gcTime: 5 * 60 * 1000, // 5 minutes - cache retention

                        // Refetch configuration
                        refetchOnWindowFocus: false, // Don't refetch on window focus
                        refetchOnReconnect: false, // Don't refetch on reconnect
                        refetchOnMount: false, // Don't refetch on component mount

                        // Retry configuration
                        retry: 2, // Retry failed requests 2 times
                        retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),

                        // Performance
                        structuralSharing: true, // Optimize re-renders
                    },
                    mutations: {
                        // Retry configuration for mutations
                        retry: 1,
                        retryDelay: 1000,
                    },
                },
            })
    )

    return (
        <QueryClientProvider client={queryClient}>
            {children}
        </QueryClientProvider>
    )
}
