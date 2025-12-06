"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";

interface LikeData {
  itemId: string;
  itemType: 'product' | 'content';
  userWallet: string;
}

export function useLike() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: LikeData): Promise<{ likes: number }> => {
      const res = await fetch("/api/like", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["feed"] });
      queryClient.invalidateQueries({ queryKey: ["products"] });
      queryClient.invalidateQueries({ queryKey: ["content"] });
    },
  });
}
