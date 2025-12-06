"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";

interface SeedStatus {
  seeded: boolean;
  stats: {
    stores: number;
    creators: number;
    products: number;
    content: number;
  };
  message: string;
}

export function useSeedStatus() {
  return useQuery({
    queryKey: ["seedStatus"],
    queryFn: async (): Promise<SeedStatus> => {
      const res = await fetch("/api/feed_data");
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
  });
}

export function useSeedDatabase() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async () => {
      const res = await fetch("/api/feed_data", {
        method: "POST",
      });
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    onSuccess: () => {
      // Invalidate all queries to refetch with new data
      queryClient.invalidateQueries({ queryKey: ["feed"] });
      queryClient.invalidateQueries({ queryKey: ["products"] });
      queryClient.invalidateQueries({ queryKey: ["content"] });
      queryClient.invalidateQueries({ queryKey: ["stats"] });
      queryClient.invalidateQueries({ queryKey: ["seedStatus"] });
    },
  });
}
