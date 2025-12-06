"use client";

import { useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { useContractConfig } from "./use-contract-config";
import { useContractUser } from "./use-contract-user";
import { ContractUserType } from "@/lib/contract-abi";
import { useCallback, useEffect, useState } from "react";

interface UseRegisterUserOptions {
  onSuccess?: (txHash: `0x${string}`) => void;
  onError?: (error: Error) => void;
}

export function useRegisterUser(options: UseRegisterUserOptions = {}) {
  const config = useContractConfig();
  const { refetch: refetchUser, isRegistered } = useContractUser();
  const [isConfirming, setIsConfirming] = useState(false);

  const {
    writeContract,
    data: txHash,
    isPending: isWritePending,
    error: writeError,
    reset,
  } = useWriteContract();

  const {
    isLoading: isWaitLoading,
    isSuccess: isConfirmed,
    error: waitError,
  } = useWaitForTransactionReceipt({
    hash: txHash,
  });

  useEffect(() => {
    if (isConfirmed && txHash) {
      setIsConfirming(false);
      refetchUser();
      options.onSuccess?.(txHash);
    }
  }, [isConfirmed, txHash, refetchUser, options]);

  useEffect(() => {
    if (writeError || waitError) {
      setIsConfirming(false);
      options.onError?.(writeError || waitError || new Error("Unknown error"));
    }
  }, [writeError, waitError, options]);

  const register = useCallback(
    async (userType: ContractUserType) => {
      if (!config.isReady) {
        throw new Error("Contract not ready. Please connect wallet.");
      }
      if (isRegistered) {
        throw new Error("User already registered on-chain");
      }
      if (userType === ContractUserType.None) {
        throw new Error("Invalid user type. Must be Creator or Store.");
      }

      setIsConfirming(true);

      writeContract({
        address: config.paymentHubAddress,
        abi: config.paymentHubAbi,
        functionName: "registerUser",
        args: [userType],
      });
    },
    [config, writeContract, isRegistered]
  );

  const registerAsCreator = useCallback(() => register(ContractUserType.Creator), [register]);
  const registerAsStore = useCallback(() => register(ContractUserType.Store), [register]);

  return {
    register,
    registerAsCreator,
    registerAsStore,
    reset,
    txHash,
    isPending: isWritePending || isWaitLoading || isConfirming,
    isWritePending,
    isWaitLoading,
    isConfirmed,
    error: writeError || waitError,
    canRegister: config.isReady && !isRegistered,
    isAlreadyRegistered: isRegistered,
  };
}

export type RegisterUserHook = ReturnType<typeof useRegisterUser>;
