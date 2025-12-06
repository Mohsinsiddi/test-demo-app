#!/bin/bash

echo "🚀 BasePay Phase 1A: Contract Hooks"
echo "===================================="
echo ""

# Create directories
echo "📁 Creating directories..."
mkdir -p lib
mkdir -p hooks/contract
mkdir -p components/examples

# ============================================
# LIB: FULL CONTRACT ABI
# ============================================
echo "📝 Creating lib/contract-abi.ts..."
cat > lib/contract-abi.ts << 'EOFABI'
// PaymentHub Contract ABI - Full version
// Based on PaymentHub.sol

export const PAYMENT_HUB_ABI = [
  // READ FUNCTIONS
  {
    inputs: [],
    name: "ANONYMOUS_FEE",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "VERIFIED_FEE",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "PREMIUM_FEE",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "BASIS_POINTS",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "premiumThreshold",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "productCounter",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "totalUsers",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "user", type: "address" }],
    name: "getUser",
    outputs: [
      {
        components: [
          { name: "wallet", type: "address" },
          { name: "userType", type: "uint8" },
          { name: "tier", type: "uint8" },
          { name: "customFee", type: "uint256" },
          { name: "hasCustomFee", type: "bool" },
          { name: "totalSales", type: "uint256" },
          { name: "registeredAt", type: "uint256" },
          { name: "isActive", type: "bool" },
        ],
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "productId", type: "uint256" }],
    name: "getProduct",
    outputs: [
      {
        components: [
          { name: "id", type: "uint256" },
          { name: "seller", type: "address" },
          { name: "price", type: "uint256" },
          { name: "paymentToken", type: "address" },
          { name: "isActive", type: "bool" },
          { name: "metadataUri", type: "string" },
        ],
        name: "",
        type: "tuple",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { name: "seller", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    name: "calculateFee",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "user", type: "address" }],
    name: "getFeeRate",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "owner",
    outputs: [{ name: "", type: "address" }],
    stateMutability: "view",
    type: "function",
  },
  // WRITE FUNCTIONS
  {
    inputs: [{ name: "userType", type: "uint8" }],
    name: "registerUser",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { name: "price", type: "uint256" },
      { name: "paymentToken", type: "address" },
      { name: "metadataUri", type: "string" },
    ],
    name: "createProduct",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { name: "productId", type: "uint256" },
      { name: "newPrice", type: "uint256" },
      { name: "isActive", type: "bool" },
    ],
    name: "updateProduct",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ name: "productId", type: "uint256" }],
    name: "buyProduct",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      { name: "creator", type: "address" },
      { name: "contentId", type: "uint256" },
      { name: "amount", type: "uint256" },
      { name: "paymentToken", type: "address" },
    ],
    name: "tipCreator",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  // EVENTS
  {
    anonymous: false,
    inputs: [
      { indexed: true, name: "user", type: "address" },
      { indexed: false, name: "userType", type: "uint8" },
      { indexed: false, name: "timestamp", type: "uint256" },
    ],
    name: "UserRegistered",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, name: "productId", type: "uint256" },
      { indexed: true, name: "seller", type: "address" },
      { indexed: false, name: "price", type: "uint256" },
      { indexed: false, name: "paymentToken", type: "address" },
    ],
    name: "ProductCreated",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, name: "productId", type: "uint256" },
      { indexed: true, name: "buyer", type: "address" },
      { indexed: true, name: "seller", type: "address" },
      { indexed: false, name: "amount", type: "uint256" },
      { indexed: false, name: "platformFee", type: "uint256" },
      { indexed: false, name: "paymentToken", type: "address" },
      { indexed: false, name: "sellerTier", type: "uint8" },
    ],
    name: "ProductPurchased",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, name: "contentId", type: "uint256" },
      { indexed: true, name: "tipper", type: "address" },
      { indexed: true, name: "creator", type: "address" },
      { indexed: false, name: "amount", type: "uint256" },
      { indexed: false, name: "paymentToken", type: "address" },
    ],
    name: "TipSent",
    type: "event",
  },
] as const;

export const ERC20_ABI = [
  {
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    name: "approve",
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { name: "owner", type: "address" },
      { name: "spender", type: "address" },
    ],
    name: "allowance",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "account", type: "address" }],
    name: "balanceOf",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
] as const;

export interface ContractUser {
  wallet: `0x${string}`;
  userType: number;
  tier: number;
  customFee: bigint;
  hasCustomFee: boolean;
  totalSales: bigint;
  registeredAt: bigint;
  isActive: boolean;
}

export interface ContractProduct {
  id: bigint;
  seller: `0x${string}`;
  price: bigint;
  paymentToken: `0x${string}`;
  isActive: boolean;
  metadataUri: string;
}

export enum ContractUserType {
  None = 0,
  Creator = 1,
  Store = 2,
}

export enum ContractUserTier {
  Anonymous = 0,
  Verified = 1,
  Premium = 2,
}

export const CONTRACT_FEES = {
  ANONYMOUS_FEE: 200n,
  VERIFIED_FEE: 100n,
  PREMIUM_FEE: 50n,
  BASIS_POINTS: 10000n,
} as const;

export const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000" as `0x${string}`;
EOFABI

# ============================================
# HOOKS: CONTRACT CONFIG
# ============================================
echo "📝 Creating hooks/contract/use-contract-config.ts..."
cat > hooks/contract/use-contract-config.ts << 'EOFCONFIG'
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
EOFCONFIG

# ============================================
# HOOKS: CONTRACT USER
# ============================================
echo "📝 Creating hooks/contract/use-contract-user.ts..."
cat > hooks/contract/use-contract-user.ts << 'EOFUSER'
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
EOFUSER

# ============================================
# HOOKS: CONTRACT PRODUCT
# ============================================
echo "📝 Creating hooks/contract/use-contract-product.ts..."
cat > hooks/contract/use-contract-product.ts << 'EOFPRODUCT'
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
EOFPRODUCT

# ============================================
# HOOKS: FEE CALCULATOR
# ============================================
echo "📝 Creating hooks/contract/use-fee-calculator.ts..."
cat > hooks/contract/use-fee-calculator.ts << 'EOFFEE'
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
EOFFEE

# ============================================
# HOOKS: REGISTER USER
# ============================================
echo "📝 Creating hooks/contract/use-register-user.ts..."
cat > hooks/contract/use-register-user.ts << 'EOFREG'
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
EOFREG

# ============================================
# HOOKS: BUY PRODUCT
# ============================================
echo "📝 Creating hooks/contract/use-buy-product.ts..."
cat > hooks/contract/use-buy-product.ts << 'EOFBUY'
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
EOFBUY

# ============================================
# HOOKS: TIP CREATOR
# ============================================
echo "📝 Creating hooks/contract/use-tip-creator.ts..."
cat > hooks/contract/use-tip-creator.ts << 'EOFTIP'
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
EOFTIP

# ============================================
# HOOKS: CREATE PRODUCT CONTRACT
# ============================================
echo "📝 Creating hooks/contract/use-create-product-contract.ts..."
cat > hooks/contract/use-create-product-contract.ts << 'EOFCREATE'
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
EOFCREATE

# ============================================
# HOOKS: CONTRACT INDEX
# ============================================
echo "📝 Creating hooks/contract/index.ts..."
cat > hooks/contract/index.ts << 'EOFINDEX'
export { useContractConfig } from './use-contract-config';
export type { ContractConfig } from './use-contract-config';

export { useContractUser } from './use-contract-user';
export type { ContractUserData } from './use-contract-user';

export { useContractProduct } from './use-contract-product';
export type { ContractProductData } from './use-contract-product';

export { useFeeCalculator, useStaticFeeCalculator } from './use-fee-calculator';
export type { FeeCalculatorData } from './use-fee-calculator';

export { useRegisterUser } from './use-register-user';
export type { RegisterUserHook } from './use-register-user';

export { useBuyProduct } from './use-buy-product';
export type { BuyProductHook } from './use-buy-product';

export { useTipCreator } from './use-tip-creator';
export type { TipCreatorHook } from './use-tip-creator';

export { useCreateProductContract } from './use-create-product-contract';
export type { CreateProductContractHook } from './use-create-product-contract';

export {
  ContractUserType,
  ContractUserTier,
  CONTRACT_FEES,
  ZERO_ADDRESS,
} from '@/lib/contract-abi';
export type { ContractUser, ContractProduct } from '@/lib/contract-abi';
EOFINDEX

# ============================================
# UPDATE MAIN HOOKS INDEX
# ============================================
echo "📝 Updating hooks/index.ts..."
cat > hooks/index.ts << 'EOFMAIN'
// User & Feed Hooks
export { useUser } from './use-user';
export { useFeed } from './use-feed';
export type { FeedItem, FeedUser, FeedResponse, FilterType } from './use-feed';
export { useProducts, useProduct, useCreateProduct } from './use-products';
export { useContent, useCreateContent } from './use-content';
export { useStats } from './use-stats';
export { useLike } from './use-like';
export { useSeedStatus, useSeedDatabase } from './use-seed';

// Contract Hooks (Phase 1A)
export * from './contract';
EOFMAIN

echo ""
echo "============================================"
echo "✅ Phase 1A Complete: Contract Hooks Created!"
echo "============================================"
echo ""
echo "📁 FILES CREATED:"
echo ""
echo "lib/"
echo "  └── contract-abi.ts              (Full contract ABI + types)"
echo ""
echo "hooks/contract/"
echo "  ├── use-contract-config.ts       (Contract configuration)"
echo "  ├── use-contract-user.ts         (Read user from chain)"
echo "  ├── use-contract-product.ts      (Read product from chain)"
echo "  ├── use-fee-calculator.ts        (Calculate fees)"
echo "  ├── use-register-user.ts         (Register on-chain)"
echo "  ├── use-buy-product.ts           (Buy product)"
echo "  ├── use-tip-creator.ts           (Tip creator)"
echo "  ├── use-create-product-contract.ts (Create product on-chain)"
echo "  └── index.ts                     (Export all)"
echo ""
echo "hooks/"
echo "  └── index.ts                     (Updated exports)"
echo ""
echo "============================================"
echo "🔧 SETUP REQUIRED:"
echo "============================================"
echo ""
echo "Add to your .env.local:"
echo ""
echo "  NEXT_PUBLIC_PAYMENT_HUB_ADDRESS=0xYourContractAddress"
echo ""
echo "============================================"