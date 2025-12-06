"use client";

import { useAccount, useChainId } from "wagmi";
import { PAYMENT_HUB_ABI, ERC20_ABI } from "@/lib/contract-abi";

const CONTRACT_ADDRESSES: Record<number, `0x${string}`> = {
  8453: process.env.NEXT_PUBLIC_PAYMENT_HUB_ADDRESS_MAINNET as `0x${string}` || "0x0000000000000000000000000000000000000000",
  84532: process.env.NEXT_PUBLIC_PAYMENT_HUB_ADDRESS as `0x${string}` || "0x0000000000000000000000000000000000000000",
  31337: "0x5FbDB2315678afecb367f032d93F642f64180aa3" as `0x${string}`,
};

const PAYMENT_TOKENS: Record<number, Record<string, `0x${string}`>> = {
  8453: {
    USDC: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
    ETH: "0x0000000000000000000000000000000000000000",
  },
  84532: {
    USDC: "0x036CbD53842c5426634e7929541eC2318f3dCF7e",
    ETH: "0x0000000000000000000000000000000000000000",
  },
  31337: {
    ETH: "0x0000000000000000000000000000000000000000",
  },
};

export function useContractConfig() {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();

  const paymentHubAddress = CONTRACT_ADDRESSES[chainId] || CONTRACT_ADDRESSES[84532];
  const paymentTokens = PAYMENT_TOKENS[chainId] || PAYMENT_TOKENS[84532];

  const isValidChain = chainId in CONTRACT_ADDRESSES;
  const isContractConfigured = paymentHubAddress !== "0x0000000000000000000000000000000000000000";

  return {
    address,
    isConnected,
    chainId,
    paymentHubAddress,
    paymentHubAbi: PAYMENT_HUB_ABI,
    erc20Abi: ERC20_ABI,
    paymentTokens,
    isValidChain,
    isContractConfigured,
    isReady: isConnected && isValidChain && isContractConfigured,
    chainName: chainId === 8453 ? "Base" : chainId === 84532 ? "Base Sepolia" : "Unknown",
    isTestnet: chainId === 84532 || chainId === 31337,
  };
}

export type ContractConfig = ReturnType<typeof useContractConfig>;
