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
