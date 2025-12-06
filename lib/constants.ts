export const ANONYMOUS_FEE = 200n;
export const VERIFIED_FEE = 100n;
export const PREMIUM_FEE = 50n;
export const BASIS_POINTS = 10000n;
export const PREMIUM_THRESHOLD = 50_000n * 10n ** 18n;

export const PAYMENT_HUB_ADDRESS = process.env.NEXT_PUBLIC_PAYMENT_HUB_ADDRESS || '0x...';
export const BASE_PAY_TOKEN_ADDRESS = process.env.NEXT_PUBLIC_BASE_PAY_TOKEN_ADDRESS || '0x...';

export const APP_NAME = 'BasePay';
export const APP_TAGLINE = 'Social Commerce on Base';
export const KYC_DEADLINE_DAYS = 90;

export const STORE_CATEGORIES = [
  { id: 'food', label: 'Food & Beverages', icon: '🍔' },
  { id: 'fashion', label: 'Fashion', icon: '👕' },
  { id: 'art', label: 'Art & Crafts', icon: '🎨' },
  { id: 'tech', label: 'Tech & Gadgets', icon: '📱' },
  { id: 'beauty', label: 'Beauty', icon: '💄' },
  { id: 'home', label: 'Home & Living', icon: '🏠' },
  { id: 'sports', label: 'Sports', icon: '⚽' },
  { id: 'other', label: 'Other', icon: '📦' },
];

export const CONTENT_CATEGORIES = [
  { id: 'entertainment', label: 'Entertainment', icon: '🎬' },
  { id: 'education', label: 'Education', icon: '📚' },
  { id: 'lifestyle', label: 'Lifestyle', icon: '✨' },
  { id: 'gaming', label: 'Gaming', icon: '🎮' },
  { id: 'music', label: 'Music', icon: '🎵' },
  { id: 'tech', label: 'Tech', icon: '💻' },
  { id: 'food', label: 'Food', icon: '🍳' },
  { id: 'travel', label: 'Travel', icon: '✈️' },
];
