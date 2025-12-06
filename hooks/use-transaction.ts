"use client";

import { useState, useCallback } from 'react';
import { useWaitForTransactionReceipt } from 'wagmi';
import { Transaction, TransactionType, TransactionStatus } from '@/types';

interface SubmitTransactionParams {
  txHash: `0x${string}`;
  type: TransactionType;
  from: string;
  to?: string;
  amount?: string;
  fee?: string;
  paymentToken?: string;
  productId?: string;
  contentId?: string;
  contractProductId?: number;
}

interface ConfirmTransactionParams {
  txHash: string;
  blockNumber: number;
  blockHash: string;
  gasUsed: string;
  orderData?: {
    productId?: string;
    seller?: string;
    amount?: string;
    fee?: string;
    deliveryType?: 'pickup' | 'shipping';
    shippingAddress?: string;
  };
  tipData?: {
    contentId?: string;
    to?: string;
    amount?: string;
  };
}

interface UseTransactionReturn {
  // State
  transaction: Transaction | null;
  isSubmitting: boolean;
  isConfirming: boolean;
  isProcessing: boolean;
  error: Error | null;
  
  // Actions
  submitTransaction: (params: SubmitTransactionParams) => Promise<Transaction>;
  confirmTransaction: (params: ConfirmTransactionParams) => Promise<Transaction>;
  failTransaction: (txHash: string, error: string) => Promise<Transaction>;
  getTransaction: (txHash: string) => Promise<Transaction | null>;
  
  // Helpers
  reset: () => void;
  status: TransactionStatus | null;
}

export function useTransaction(): UseTransactionReturn {
  const [transaction, setTransaction] = useState<Transaction | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isConfirming, setIsConfirming] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  // Submit transaction to DB (status: pending)
  const submitTransaction = useCallback(async (params: SubmitTransactionParams): Promise<Transaction> => {
    setIsSubmitting(true);
    setError(null);

    try {
      console.log('📤 Submitting transaction to DB:', params.txHash);

      const response = await fetch('/api/transactions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(params),
      });

      const json = await response.json();

      if (!json.success) {
        throw new Error(json.error || 'Failed to submit transaction');
      }

      console.log('✅ Transaction submitted:', json.data);
      setTransaction(json.data);
      return json.data;
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Unknown error');
      setError(error);
      throw error;
    } finally {
      setIsSubmitting(false);
    }
  }, []);

  // Confirm transaction (status: confirmed → processed)
  const confirmTransaction = useCallback(async (params: ConfirmTransactionParams): Promise<Transaction> => {
    setIsConfirming(true);
    setError(null);

    try {
      console.log('✅ Confirming transaction:', params.txHash);

      const response = await fetch(`/api/transactions/${params.txHash}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          status: 'confirmed',
          blockNumber: params.blockNumber,
          blockHash: params.blockHash,
          gasUsed: params.gasUsed,
          orderData: params.orderData,
          tipData: params.tipData,
        }),
      });

      const json = await response.json();

      if (!json.success) {
        throw new Error(json.error || 'Failed to confirm transaction');
      }

      console.log('✅ Transaction confirmed:', json.data);
      setTransaction(json.data);
      return json.data;
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Unknown error');
      setError(error);
      throw error;
    } finally {
      setIsConfirming(false);
    }
  }, []);

  // Fail transaction
  const failTransaction = useCallback(async (txHash: string, errorMessage: string): Promise<Transaction> => {
    setIsProcessing(true);
    setError(null);

    try {
      console.log('❌ Failing transaction:', txHash, errorMessage);

      const response = await fetch(`/api/transactions/${txHash}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          status: 'failed',
          error: errorMessage,
        }),
      });

      const json = await response.json();

      if (!json.success) {
        throw new Error(json.error || 'Failed to update transaction');
      }

      setTransaction(json.data);
      return json.data;
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Unknown error');
      setError(error);
      throw error;
    } finally {
      setIsProcessing(false);
    }
  }, []);

  // Get transaction by txHash
  const getTransaction = useCallback(async (txHash: string): Promise<Transaction | null> => {
    try {
      const response = await fetch(`/api/transactions/${txHash}`);
      const json = await response.json();

      if (!json.success) {
        return null;
      }

      setTransaction(json.data);
      return json.data;
    } catch (err) {
      console.error('Failed to get transaction:', err);
      return null;
    }
  }, []);

  // Reset state
  const reset = useCallback(() => {
    setTransaction(null);
    setIsSubmitting(false);
    setIsConfirming(false);
    setIsProcessing(false);
    setError(null);
  }, []);

  return {
    transaction,
    isSubmitting,
    isConfirming,
    isProcessing,
    error,
    submitTransaction,
    confirmTransaction,
    failTransaction,
    getTransaction,
    reset,
    status: transaction?.status || null,
  };
}

// ============================================
// Integrated hook for full transaction flow
// ============================================

interface UseTransactionFlowParams {
  onSuccess?: (transaction: Transaction) => void;
  onError?: (error: Error) => void;
}

interface ExecuteParams extends SubmitTransactionParams {
  orderData?: ConfirmTransactionParams['orderData'];
  tipData?: ConfirmTransactionParams['tipData'];
}

export function useTransactionFlow({ onSuccess, onError }: UseTransactionFlowParams = {}) {
  const {
    transaction,
    isSubmitting,
    isConfirming,
    error,
    submitTransaction,
    confirmTransaction,
    failTransaction,
    reset,
    status,
  } = useTransaction();

  const [txHash, setTxHash] = useState<`0x${string}` | undefined>();

  // Wait for transaction receipt
  const { 
    data: receipt, 
    isLoading: isWaiting,
    isSuccess: isReceiptSuccess,
    isError: isReceiptError,
    error: receiptError,
  } = useWaitForTransactionReceipt({
    hash: txHash,
  });

  // Execute full flow: submit → wait → confirm
  const execute = useCallback(async (params: ExecuteParams) => {
    try {
      // 1. Submit to DB
      await submitTransaction(params);
      
      // 2. Set txHash to trigger receipt waiting
      setTxHash(params.txHash);

    } catch (err) {
      const error = err instanceof Error ? err : new Error('Unknown error');
      onError?.(error);
      throw error;
    }
  }, [submitTransaction, onError]);

  // Handle receipt success
  const handleReceiptSuccess = useCallback(async (
    receipt: NonNullable<typeof receipt>,
    orderData?: ConfirmTransactionParams['orderData'],
    tipData?: ConfirmTransactionParams['tipData']
  ) => {
    if (!txHash) return;

    try {
      const confirmed = await confirmTransaction({
        txHash,
        blockNumber: receipt.blockNumber,
        blockHash: receipt.blockHash,
        gasUsed: receipt.gasUsed.toString(),
        orderData,
        tipData,
      });

      onSuccess?.(confirmed);
    } catch (err) {
      const error = err instanceof Error ? err : new Error('Failed to confirm');
      onError?.(error);
    }
  }, [txHash, confirmTransaction, onSuccess, onError]);

  // Handle receipt error
  const handleReceiptError = useCallback(async () => {
    if (!txHash) return;

    try {
      await failTransaction(txHash, receiptError?.message || 'Transaction failed');
    } catch (err) {
      console.error('Failed to mark transaction as failed:', err);
    }

    onError?.(receiptError || new Error('Transaction failed'));
  }, [txHash, receiptError, failTransaction, onError]);

  return {
    transaction,
    receipt,
    txHash,
    
    // States
    isSubmitting,
    isWaiting,
    isConfirming,
    isPending: isSubmitting || isWaiting || isConfirming,
    isSuccess: status === 'processed',
    isError: !!error || isReceiptError,
    
    // Data
    status,
    error: error || receiptError,
    
    // Actions
    execute,
    handleReceiptSuccess,
    handleReceiptError,
    reset: () => {
      reset();
      setTxHash(undefined);
    },
  };
}
