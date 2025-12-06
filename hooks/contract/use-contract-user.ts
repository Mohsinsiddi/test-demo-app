"use client";

import { useReadContract } from "wagmi";
import { useContractConfig } from "./use-contract-config";
import { ContractUser, ContractUserType, ContractUserTier } from "@/lib/contract-abi";

interface UseContractUserOptions {
  address?: `0x${string}`;
  enabled?: boolean;
}

export function useContractUser(options: UseContractUserOptions = {}) {
  const config = useContractConfig();
  const userAddress = options.address || config.address;

  const {
    data: rawUser,
    isLoading,
    error,
    refetch,
  } = useReadContract({
    address: config.paymentHubAddress,
    abi: config.paymentHubAbi,
    functionName: "getUser",
    args: userAddress ? [userAddress] : undefined,
    query: {
      enabled: !!userAddress && config.isReady && (options.enabled !== false),
    },
  });

  const user: ContractUser | null = rawUser ? {
    wallet: rawUser.wallet,
    userType: rawUser.userType,
    tier: rawUser.tier,
    customFee: rawUser.customFee,
    hasCustomFee: rawUser.hasCustomFee,
    totalSales: rawUser.totalSales,
    registeredAt: rawUser.registeredAt,
    isActive: rawUser.isActive,
  } : null;

  const isRegistered = user && user.wallet !== "0x0000000000000000000000000000000000000000";

  const getUserTypeName = (type: number): string => {
    switch (type) {
      case ContractUserType.Creator: return "Creator";
      case ContractUserType.Store: return "Store";
      default: return "None";
    }
  };

  const getTierName = (tier: number): string => {
    switch (tier) {
      case ContractUserTier.Premium: return "Premium";
      case ContractUserTier.Verified: return "Verified";
      default: return "Anonymous";
    }
  };

  const getTierFeePercent = (tier: number): string => {
    switch (tier) {
      case ContractUserTier.Premium: return "0.5%";
      case ContractUserTier.Verified: return "1%";
      default: return "2%";
    }
  };

  return {
    user,
    isLoading,
    error,
    refetch,
    isRegistered,
    isActive: user?.isActive ?? false,
    userType: user?.userType ?? ContractUserType.None,
    tier: user?.tier ?? ContractUserTier.Anonymous,
    totalSales: user?.totalSales ?? 0n,
    userTypeName: getUserTypeName(user?.userType ?? 0),
    tierName: getTierName(user?.tier ?? 0),
    tierFeePercent: getTierFeePercent(user?.tier ?? 0),
    config,
  };
}

export type ContractUserData = ReturnType<typeof useContractUser>;
