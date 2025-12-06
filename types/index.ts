// User Types
export enum UserType {
  None = 0,
  Creator = 1,
  Store = 2,
}

export enum UserTier {
  Anonymous = 0,
  Verified = 1,
  Premium = 2,
}

export interface User {
  _id?: string;
  wallet: string;
  userType: UserType;
  tier: UserTier;
  isActive: boolean;
  totalSales: string;
  hasCustomFee: boolean;
  customFee: number;
  registeredAt: Date;
  displayName?: string;
  username?: string;
  bio?: string;
  avatar?: string;
  banner?: string;
  storeName?: string;
  storeCategory?: string;
  location?: string;
  youtube?: string;
  instagram?: string;
  twitter?: string;
  kycStatus: 'pending' | 'submitted' | 'verified' | 'rejected';
  kycDeadline?: Date;
}

export interface Product {
  _id?: string;
  contractId: number;
  seller: string;
  price: string;
  paymentToken: string;
  isActive: boolean;
  metadataUri: string;
  createdAt: Date;
  title: string;
  description?: string;
  images: string[];
  category?: string;
  stock?: number;
  deliveryOptions: {
    pickup: boolean;
    shipping: boolean;
  };
}

export interface CreatorContent {
  _id?: string;
  creator: string;
  platform: 'youtube' | 'instagram' | 'twitter';
  url: string;
  title?: string;
  description?: string;
  thumbnail?: string;
  category?: string;
  suggestedTip?: string;
  createdAt: Date;
  likes: number;
  tips: string;
}

export interface Order {
  _id?: string;
  productId: string;
  buyer: string;
  seller: string;
  amount: string;
  fee: string;
  paymentToken: string;
  status: 'pending' | 'confirmed' | 'ready' | 'shipped' | 'delivered' | 'disputed' | 'cancelled';
  deliveryType: 'pickup' | 'shipping';
  shippingAddress?: string;
  trackingInfo?: string;
  txHash: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Tip {
  _id?: string;
  contentId: string;
  from: string;
  to: string;
  amount: string;
  paymentToken: string;
  txHash: string;
  createdAt: Date;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}
