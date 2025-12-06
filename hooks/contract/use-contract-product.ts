"use client";

import { useReadContract } from "wagmi";
import { useContractConfig } from "./use-contract-config";
import { ContractProduct, ZERO_ADDRESS } from "@/lib/contract-abi";
import { formatEther } from "viem";

interface UseContractProductOptions {
  productId: number | bigint;
  enabled?: boolean;
}

export function useContractProduct({ productId, enabled = true }: UseContractProductOptions) {
  const config = useContractConfig();

  const {
    data: rawProduct,
    isLoading,
    error,
    refetch,
  } = useReadContract({
    address: config.paymentHubAddress,
    abi: config.paymentHubAbi,
    functionName: "getProduct",
    args: [BigInt(productId)],
    query: {
      enabled: enabled && config.isReady && productId > 0,
    },
  });

  const product: ContractProduct | null = rawProduct ? {
    id: rawProduct.id,
    seller: rawProduct.seller,
    price: rawProduct.price,
    paymentToken: rawProduct.paymentToken,
    isActive: rawProduct.isActive,
    metadataUri: rawProduct.metadataUri,
  } : null;

  const exists = product && product.seller !== ZERO_ADDRESS;
  const isEthPayment = product?.paymentToken === ZERO_ADDRESS;
  const formattedPrice = product ? formatEther(product.price) : "0";

  return {
    product,
    isLoading,
    error,
    refetch,
    exists,
    isActive: product?.isActive ?? false,
    isEthPayment,
    formattedPrice,
    config,
  };
}

export type ContractProductData = ReturnType<typeof useContractProduct>;
