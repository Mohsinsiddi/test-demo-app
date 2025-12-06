"use client";

import { useWriteContract, useWaitForTransactionReceipt, useReadContract } from "wagmi";
import { useContractConfig } from "./use-contract-config";
import { useContractUser } from "./use-contract-user";
import { ZERO_ADDRESS, ERC20_ABI, ContractUserType } from "@/lib/contract-abi";
import { useCallback, useEffect, useState } from "react";
import { parseEther } from "viem";

interface UseTipCreatorOptions {
  creatorAddress: `0x${string}`;
  onSuccess?: (txHash: `0x${string}`) => void;
  onError?: (error: Error) => void;
}

export function useTipCreator({ creatorAddress, onSuccess, onError }: UseTipCreatorOptions) {
  const config = useContractConfig();
  const { user: creatorUser, isLoading: isCreatorLoading } = useContractUser({ address: creatorAddress });
  
  const [step, setStep] = useState<'idle' | 'approving' | 'tipping' | 'confirmed'>('idle');

  const isValidCreator = creatorUser?.isActive && creatorUser?.userType === ContractUserType.Creator;

  const {
    writeContract: writeTip,
    data: tipTxHash,
    isPending: isTipPending,
    error: tipError,
    reset: resetTip,
  } = useWriteContract();

  const { isLoading: isTipWaiting, isSuccess: isTipConfirmed } = useWaitForTransactionReceipt({
    hash: tipTxHash,
  });

  useEffect(() => {
    if (isTipConfirmed && tipTxHash) {
      setStep('confirmed');
      onSuccess?.(tipTxHash);
    }
  }, [isTipConfirmed, tipTxHash, onSuccess]);

  useEffect(() => {
    if (tipError) {
      setStep('idle');
      onError?.(tipError);
    }
  }, [tipError, onError]);

  const tip = useCallback(async (params: {
    contentId?: number | bigint;
    amount: string | bigint;
    paymentToken?: `0x${string}`;
  }) => {
    if (!config.isReady) throw new Error("Please connect wallet");
    if (!isValidCreator) throw new Error("Invalid creator or creator not active");

    const amountInWei = typeof params.amount === 'string' ? parseEther(params.amount) : params.amount;
    if (amountInWei <= 0n) throw new Error("Amount must be greater than 0");

    const paymentToken = params.paymentToken || ZERO_ADDRESS;
    const contentId = BigInt(params.contentId ?? 0);

    setStep('tipping');
    writeTip({
      address: config.paymentHubAddress,
      abi: config.paymentHubAbi,
      functionName: "tipCreator",
      args: [creatorAddress, contentId, amountInWei, paymentToken],
      value: paymentToken === ZERO_ADDRESS ? amountInWei : 0n,
    });
  }, [config, isValidCreator, creatorAddress, writeTip]);

  const tipEth = useCallback((amount: string, contentId?: number) => {
    return tip({ amount, contentId, paymentToken: ZERO_ADDRESS });
  }, [tip]);

  const reset = useCallback(() => {
    setStep('idle');
    resetTip();
  }, [resetTip]);

  return {
    tip,
    tipEth,
    reset,
    creatorUser,
    isCreatorLoading,
    isValidCreator,
    step,
    txHash: tipTxHash,
    isPending: isTipPending || isTipWaiting,
    isConfirmed: isTipConfirmed,
    error: tipError,
    canTip: config.isReady && isValidCreator,
  };
}

export type TipCreatorHook = ReturnType<typeof useTipCreator>;
