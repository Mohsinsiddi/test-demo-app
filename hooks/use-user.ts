"use client";

import { useAccount } from "wagmi";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { User, UserType } from "@/types";

interface RegisterData {
  userType: UserType;
  displayName?: string;
  username?: string;
  bio?: string;
  storeName?: string;
  storeCategory?: string;
  location?: string;
}

export function useUser() {
  const { address, isConnected } = useAccount();
  const queryClient = useQueryClient();

  const { 
    data: user, 
    isLoading, 
    error,
    refetch 
  } = useQuery({
    queryKey: ["user", address],
    queryFn: async (): Promise<User | null> => {
      if (!address) return null;
      
      console.log("📡 Fetching user from API for:", address);
      
      const res = await fetch(`/api/users?wallet=${address}`);
      const json = await res.json();
      
      console.log("📡 API response:", json);
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    enabled: !!address && isConnected,
    staleTime: 1000 * 60 * 5,
  });

  const registerMutation = useMutation({
    mutationFn: async (data: RegisterData): Promise<User> => {
      console.log("📡 Registering user:", { wallet: address, ...data });
      
      const res = await fetch("/api/users", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ wallet: address, ...data }),
      });
      const json = await res.json();
      
      console.log("📡 Registration response:", json);
      
      if (!json.success) throw new Error(json.error);
      return json.data as User;
    },
    onSuccess: (newUser) => {
      queryClient.setQueryData(["user", address], newUser);
    },
  });

  const updateMutation = useMutation({
    mutationFn: async (data: Partial<RegisterData>): Promise<User> => {
      const res = await fetch("/api/users", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ wallet: address, ...data }),
      });
      const json = await res.json();
      if (!json.success) throw new Error(json.error);
      return json.data as User;
    },
    onSuccess: (updatedUser) => {
      queryClient.setQueryData(["user", address], updatedUser);
    },
  });

  return {
    user,
    isLoading,
    error,
    refetch,
    isConnected,
    address,
    isRegistered: !!user && user.userType !== UserType.None,
    needsOnboarding: isConnected && !isLoading && (!user || user.userType === UserType.None),
    registerUser: registerMutation.mutate,
    registerUserAsync: registerMutation.mutateAsync,
    isRegistering: registerMutation.isPending,
    registerError: registerMutation.error,
    updateUser: updateMutation.mutate,
    updateUserAsync: updateMutation.mutateAsync,
    isUpdating: updateMutation.isPending,
    updateError: updateMutation.error,
  };
}
