"use client";

import { useWriteContract, useWaitForTransactionReceipt, useReadContract } from "wagmi";
import { useContractConfig } from "./use-contract-config";
import { useContractProduct } from "./use-contract-product";
import { useFeeCalculator } from "./use-fee-calculator";
import { ZERO_ADDRESS, ERC20_ABI } from "@/lib/contract-abi";
import { useCallback, useEffect, useState } from "react";

interface UseBuyProductOptions {
  productId: number | bigint;
  onSuccess?: (txHash: `0x${string}`) => void;
  onError?: (error: Error) => void;
}

export function useBuyProduct({ productId, onSuccess, onError }: UseBuyProductOptions) {
  const config = useContractConfig();
  const { product, isLoading: isProductLoading, isActive, isEthPayment } = useContractProduct({ productId });
  const { feeAmount, sellerAmount, formattedFee, formattedTotal } = useFeeCalculator({
    sellerAddress: product?.seller,
    amount: product?.price,
    enabled: !!product,
  });

  const [step, setStep] = useState<'idle' | 'approving' | 'buying' | 'confirmed'>('idle');

  const { data: allowance, refetch: refetchAllowance } = useReadContract({
    address: product?.paymentToken as `0x${string}`,
    abi: ERC20_ABI,
    functionName: "allowance",
    args: config.address && product ? [config.address, config.paymentHubAddress] : undefined,
    query: { enabled: !!product && !isEthPayment && !!config.address },
  });

  const {
    writeContract: writeApprove,
    data: approveTxHash,
    isPending: isApprovePending,
    error: approveError,
    reset: resetApprove,
  } = useWriteContract();

  const { isLoading: isApproveWaiting, isSuccess: isApproveConfirmed } = useWaitForTransactionReceipt({
    hash: approveTxHash,
  });

  const {
    writeContract: writeBuy,
    data: buyTxHash,
    isPending: isBuyPending,
    error: buyError,
    reset: resetBuy,
  } = useWriteContract();

  const { isLoading: isBuyWaiting, isSuccess: isBuyConfirmed } = useWaitForTransactionReceipt({
    hash: buyTxHash,
  });

  const executeBuy = useCallback(() => {
    if (!product || !config.isReady) return;

    writeBuy({
      address: config.paymentHubAddress,
      abi: config.paymentHubAbi,
      functionName: "buyProduct",
      args: [BigInt(productId)],
      value: isEthPayment ? product.price : 0n,
    });
  }, [product, productId, config, isEthPayment, writeBuy]);

  useEffect(() => {
    if (isApproveConfirmed && step === 'approving') {
      refetchAllowance();
      setStep('buying');
      executeBuy();
    }
  }, [isApproveConfirmed, step, refetchAllowance, executeBuy]);

  useEffect(() => {
    if (isBuyConfirmed && buyTxHash) {
      setStep('confirmed');
      onSuccess?.(buyTxHash);
    }
  }, [isBuyConfirmed, buyTxHash, onSuccess]);

  useEffect(() => {
    if (approveError || buyError) {
      setStep('idle');
      onError?.(approveError || buyError || new Error("Transaction failed"));
    }
  }, [approveError, buyError, onError]);

  const buy = useCallback(async () => {
    if (!product || !config.isReady) throw new Error("Product not ready");
    if (!isActive) throw new Error("Product is not active");

    if (isEthPayment) {
      setStep('buying');
      executeBuy();
      return;
    }

    const needsApproval = !allowance || allowance < product.price;

    if (needsApproval) {
      setStep('approving');
      writeApprove({
        address: product.paymentToken,
        abi: ERC20_ABI,
        functionName: "approve",
        args: [config.paymentHubAddress, product.price],
      });
    } else {
      setStep('buying');
      executeBuy();
    }
  }, [product, config, isActive, isEthPayment, allowance, writeApprove, executeBuy]);

  const reset = useCallback(() => {
    setStep('idle');
    resetApprove();
    resetBuy();
  }, [resetApprove, resetBuy]);

  const isPending = isApprovePending || isBuyPending || isApproveWaiting || isBuyWaiting;

  return {
    buy,
    reset,
    product,
    isProductLoading,
    isActive,
    isEthPayment,
    feeAmount,
    sellerAmount,
    formattedFee,
    formattedTotal,
    totalPrice: product?.price ?? 0n,
    step,
    txHash: buyTxHash,
    approveTxHash,
    isPending,
    isLoading: isProductLoading || isPending,
    isConfirmed: isBuyConfirmed,
    error: approveError || buyError,
    canBuy: config.isReady && isActive && !!product,
    needsApproval: !isEthPayment && (!allowance || (allowance < (product?.price ?? 0n))),
  };
}

export type BuyProductHook = ReturnType<typeof useBuyProduct>;
