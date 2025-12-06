"use client";

import { useReadContract } from "wagmi";
import { useContractConfig } from "./use-contract-config";
import { CONTRACT_FEES, ContractUserTier } from "@/lib/contract-abi";
import { formatEther } from "viem";

interface UseFeeCalculatorOptions {
  sellerAddress?: `0x${string}`;
  amount?: bigint;
  enabled?: boolean;
}

export function useFeeCalculator({ sellerAddress, amount, enabled = true }: UseFeeCalculatorOptions) {
  const config = useContractConfig();

  const {
    data: feeAmount,
    isLoading: isFeeLoading,
    error: feeError,
    refetch: refetchFee,
  } = useReadContract({
    address: config.paymentHubAddress,
    abi: config.paymentHubAbi,
    functionName: "calculateFee",
    args: sellerAddress && amount ? [sellerAddress, amount] : undefined,
    query: {
      enabled: enabled && config.isReady && !!sellerAddress && !!amount && amount > 0n,
    },
  });

  const {
    data: feeRate,
    isLoading: isRateLoading,
  } = useReadContract({
    address: config.paymentHubAddress,
    abi: config.paymentHubAbi,
    functionName: "getFeeRate",
    args: sellerAddress ? [sellerAddress] : undefined,
    query: {
      enabled: enabled && config.isReady && !!sellerAddress,
    },
  });

  const sellerAmount = amount && feeAmount ? amount - feeAmount : 0n;
  const formattedFee = feeAmount ? formatEther(feeAmount) : "0";
  const formattedSellerAmount = sellerAmount ? formatEther(sellerAmount) : "0";
  const formattedTotal = amount ? formatEther(amount) : "0";
  const feePercentage = feeRate ? `${(Number(feeRate) / 100).toFixed(2)}%` : "2%";

  const getTierFromFeeRate = (rate: bigint | undefined): ContractUserTier => {
    if (!rate) return ContractUserTier.Anonymous;
    if (rate === CONTRACT_FEES.PREMIUM_FEE) return ContractUserTier.Premium;
    if (rate === CONTRACT_FEES.VERIFIED_FEE) return ContractUserTier.Verified;
    return ContractUserTier.Anonymous;
  };

  return {
    feeAmount: feeAmount ?? 0n,
    feeRate: feeRate ?? CONTRACT_FEES.ANONYMOUS_FEE,
    sellerAmount,
    totalAmount: amount ?? 0n,
    formattedFee,
    formattedSellerAmount,
    formattedTotal,
    feePercentage,
    isLoading: isFeeLoading || isRateLoading,
    error: feeError,
    refetch: refetchFee,
    sellerTier: getTierFromFeeRate(feeRate),
    calculateFeeForAmount: (newAmount: bigint): bigint => {
      if (!feeRate) return (newAmount * CONTRACT_FEES.ANONYMOUS_FEE) / CONTRACT_FEES.BASIS_POINTS;
      return (newAmount * feeRate) / CONTRACT_FEES.BASIS_POINTS;
    },
  };
}

export function useStaticFeeCalculator() {
  const calculateFee = (amount: bigint, tier: ContractUserTier) => {
    let feeRate: bigint;
    let feePercent: string;

    switch (tier) {
      case ContractUserTier.Premium:
        feeRate = CONTRACT_FEES.PREMIUM_FEE;
        feePercent = "0.5%";
        break;
      case ContractUserTier.Verified:
        feeRate = CONTRACT_FEES.VERIFIED_FEE;
        feePercent = "1%";
        break;
      default:
        feeRate = CONTRACT_FEES.ANONYMOUS_FEE;
        feePercent = "2%";
    }

    const fee = (amount * feeRate) / CONTRACT_FEES.BASIS_POINTS;
    const sellerAmount = amount - fee;

    return { fee, sellerAmount, feePercent };
  };

  return { calculateFee };
}

export type FeeCalculatorData = ReturnType<typeof useFeeCalculator>;
