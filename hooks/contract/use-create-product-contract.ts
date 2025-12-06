"use client";

import { useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { useContractConfig } from "./use-contract-config";
import { useContractUser } from "./use-contract-user";
import { ZERO_ADDRESS, ContractUserType } from "@/lib/contract-abi";
import { useCallback, useEffect, useState } from "react";
import { parseEther } from "viem";

interface UseCreateProductContractOptions {
  onSuccess?: (txHash: `0x${string}`, productId?: bigint) => void;
  onError?: (error: Error) => void;
}

interface CreateProductParams {
  price: string | bigint;
  paymentToken?: `0x${string}`;
  metadataUri?: string;
}

export function useCreateProductContract(options: UseCreateProductContractOptions = {}) {
  const config = useContractConfig();
  const { isRegistered, userType, isActive } = useContractUser();
  const [isConfirming, setIsConfirming] = useState(false);

  const canCreate = isRegistered && isActive && userType === ContractUserType.Store;

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
    data: receipt,
    error: waitError,
  } = useWaitForTransactionReceipt({
    hash: txHash,
  });

  useEffect(() => {
    if (isConfirmed && txHash && receipt) {
      setIsConfirming(false);
      options.onSuccess?.(txHash);
    }
  }, [isConfirmed, txHash, receipt, options]);

  useEffect(() => {
    if (writeError || waitError) {
      setIsConfirming(false);
      options.onError?.(writeError || waitError || new Error("Unknown error"));
    }
  }, [writeError, waitError, options]);

  const createProduct = useCallback(
    async ({ price, paymentToken = ZERO_ADDRESS, metadataUri = "" }: CreateProductParams) => {
      if (!config.isReady) throw new Error("Please connect wallet");
      if (!canCreate) throw new Error("Only registered stores can create products");

      const priceInWei = typeof price === 'string' ? parseEther(price) : price;
      if (priceInWei <= 0n) throw new Error("Price must be greater than 0");

      setIsConfirming(true);

      writeContract({
        address: config.paymentHubAddress,
        abi: config.paymentHubAbi,
        functionName: "createProduct",
        args: [priceInWei, paymentToken, metadataUri],
      });
    },
    [config, canCreate, writeContract]
  );

  return {
    createProduct,
    reset,
    txHash,
    isPending: isWritePending || isWaitLoading || isConfirming,
    isWritePending,
    isWaitLoading,
    isConfirmed,
    error: writeError || waitError,
    canCreate,
    isRegistered,
    userType,
  };
}

export type CreateProductContractHook = ReturnType<typeof useCreateProductContract>;
