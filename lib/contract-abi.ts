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
