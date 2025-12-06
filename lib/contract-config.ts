import { PAYMENT_HUB_ADDRESS, BASE_PAY_TOKEN_ADDRESS } from './constants';

export const PAYMENT_HUB_ABI = [
  {
    inputs: [{ name: 'user', type: 'address' }],
    name: 'getUser',
    outputs: [
      {
        components: [
          { name: 'wallet', type: 'address' },
          { name: 'userType', type: 'uint8' },
          { name: 'tier', type: 'uint8' },
          { name: 'isActive', type: 'bool' },
          { name: 'totalSales', type: 'uint256' },
          { name: 'hasCustomFee', type: 'bool' },
          { name: 'customFee', type: 'uint256' },
          { name: 'registeredAt', type: 'uint256' },
        ],
        name: '',
        type: 'tuple',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'productId', type: 'uint256' }],
    name: 'getProduct',
    outputs: [
      {
        components: [
          { name: 'id', type: 'uint256' },
          { name: 'seller', type: 'address' },
          { name: 'price', type: 'uint256' },
          { name: 'paymentToken', type: 'address' },
          { name: 'isActive', type: 'bool' },
          { name: 'metadataUri', type: 'string' },
        ],
        name: '',
        type: 'tuple',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [{ name: 'userType', type: 'uint8' }],
    name: 'registerUser',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      { name: 'price', type: 'uint256' },
      { name: 'paymentToken', type: 'address' },
      { name: 'metadataUri', type: 'string' },
    ],
    name: 'createProduct',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ name: 'productId', type: 'uint256' }],
    name: 'buyProduct',
    outputs: [],
    stateMutability: 'payable',
    type: 'function',
  },
  {
    inputs: [
      { name: 'creator', type: 'address' },
      { name: 'contentId', type: 'uint256' },
      { name: 'amount', type: 'uint256' },
      { name: 'paymentToken', type: 'address' },
    ],
    name: 'tipCreator',
    outputs: [],
    stateMutability: 'payable',
    type: 'function',
  },
] as const;

export const ERC20_ABI = [
  {
    inputs: [
      { name: 'spender', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    name: 'approve',
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [{ name: 'account', type: 'address' }],
    name: 'balanceOf',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
] as const;

export const contractConfig = {
  paymentHub: {
    address: PAYMENT_HUB_ADDRESS as `0x${string}`,
    abi: PAYMENT_HUB_ABI,
  },
  basePay: {
    address: BASE_PAY_TOKEN_ADDRESS as `0x${string}`,
    abi: ERC20_ABI,
  },
};
