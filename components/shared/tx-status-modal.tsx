"use client";

import { useEffect } from 'react';
import { Loader2, CheckCircle, XCircle, ExternalLink } from 'lucide-react';
import { TransactionStatus } from '@/types';

interface TxStatusModalProps {
  isOpen: boolean;
  onClose: () => void;
  status: TransactionStatus | null;
  txHash?: string;
  title?: string;
  successMessage?: string;
  errorMessage?: string;
  onSuccess?: () => void;
}

export function TxStatusModal({
  isOpen,
  onClose,
  status,
  txHash,
  title = 'Transaction',
  successMessage = 'Transaction completed successfully!',
  errorMessage,
  onSuccess,
}: TxStatusModalProps) {
  // Call onSuccess when processed
  useEffect(() => {
    if (status === 'processed') {
      onSuccess?.();
    }
  }, [status, onSuccess]);

  if (!isOpen) return null;

  const getStatusDisplay = () => {
    switch (status) {
      case 'pending':
        return {
          icon: <Loader2 className="w-12 h-12 text-[var(--pay-blue)] animate-spin" />,
          title: 'Confirming Transaction',
          message: 'Waiting for blockchain confirmation...',
          color: 'var(--pay-blue)',
        };
      case 'confirmed':
        return {
          icon: <Loader2 className="w-12 h-12 text-[var(--pay-purple)] animate-spin" />,
          title: 'Processing',
          message: 'Updating records...',
          color: 'var(--pay-purple)',
        };
      case 'processed':
        return {
          icon: <CheckCircle className="w-12 h-12 text-[var(--pay-green)]" />,
          title: 'Success!',
          message: successMessage,
          color: 'var(--pay-green)',
        };
      case 'failed':
        return {
          icon: <XCircle className="w-12 h-12 text-red-400" />,
          title: 'Transaction Failed',
          message: errorMessage || 'Something went wrong. Please try again.',
          color: 'red',
        };
      default:
        return {
          icon: <Loader2 className="w-12 h-12 text-[var(--muted-foreground)] animate-spin" />,
          title: 'Processing',
          message: 'Please wait...',
          color: 'var(--muted-foreground)',
        };
    }
  };

  const display = getStatusDisplay();
  const isComplete = status === 'processed' || status === 'failed';
  const baseScanUrl = process.env.NEXT_PUBLIC_CHAIN_ID === '8453'
    ? 'https://basescan.org/tx/'
    : 'https://sepolia.basescan.org/tx/';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={isComplete ? onClose : undefined}
      />
      
      {/* Modal */}
      <div className="relative glass-card p-6 max-w-sm w-full text-center animate-in fade-in zoom-in duration-200">
        {/* Icon */}
        <div className="flex justify-center mb-4">
          {display.icon}
        </div>

        {/* Title */}
        <h3 className="text-xl font-bold mb-2">{display.title}</h3>

        {/* Message */}
        <p className="text-[var(--muted-foreground)] text-sm mb-4">
          {display.message}
        </p>

        {/* Progress dots for pending states */}
        {!isComplete && (
          <div className="flex justify-center gap-1 mb-4">
            <div 
              className={`w-2 h-2 rounded-full ${status === 'pending' ? 'bg-[var(--pay-blue)]' : 'bg-[var(--muted)]'}`}
            />
            <div 
              className={`w-2 h-2 rounded-full ${status === 'confirmed' ? 'bg-[var(--pay-purple)]' : 'bg-[var(--muted)]'}`}
            />
            <div 
              className={`w-2 h-2 rounded-full ${status === 'processed' ? 'bg-[var(--pay-green)]' : 'bg-[var(--muted)]'}`}
            />
          </div>
        )}

        {/* Transaction hash link */}
        {txHash && (
          <a
            href={`${baseScanUrl}${txHash}`}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1 text-xs text-[var(--pay-blue)] hover:underline mb-4"
          >
            View on BaseScan
            <ExternalLink className="w-3 h-3" />
          </a>
        )}

        {/* Close button (only when complete) */}
        {isComplete && (
          <button
            onClick={onClose}
            className={`w-full py-3 rounded-xl font-medium transition-colors ${
              status === 'processed'
                ? 'bg-[var(--pay-green)] text-white hover:opacity-90'
                : 'bg-[var(--muted)] hover:bg-[var(--muted)]/80'
            }`}
          >
            {status === 'processed' ? 'Done' : 'Close'}
          </button>
        )}
      </div>
    </div>
  );
}
