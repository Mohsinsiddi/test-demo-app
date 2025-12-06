"use client";

import { use } from 'react';
import { useRouter } from 'next/navigation';
import { useProduct } from '@/hooks/use-products';
import { ProductInfo } from '@/components/product/product-info';
import { BuyButton } from '@/components/product/buy-button';
import { ChevronLeft, Share2, Heart } from 'lucide-react';
import { useLike } from '@/hooks/use-like';
import { useUser } from '@/hooks/use-user';
import { useState } from 'react';
import { toast } from 'sonner';

interface ProductPageProps {
  params: Promise<{ id: string }>;
}

export default function ProductPage({ params }: ProductPageProps) {
  const { id } = use(params);
  const router = useRouter();
  const { address } = useUser();
  const { data, isLoading, error } = useProduct(id);
  const likeMutation = useLike();
  const [isLiked, setIsLiked] = useState(false);

  const handleBack = () => {
    router.back();
  };

  const handleShare = async () => {
    try {
      if (navigator.share) {
        await navigator.share({
          title: data?.product?.title,
          text: `Check out ${data?.product?.title} on BasePay!`,
          url: window.location.href,
        });
      } else {
        await navigator.clipboard.writeText(window.location.href);
        toast.success('Link copied to clipboard!');
      }
    } catch (error) {
      console.error('Share failed:', error);
    }
  };

  const handleLike = async () => {
    if (!address || isLiked) return;
    
    try {
      await likeMutation.mutateAsync({
        itemId: id,
        itemType: 'product',
        userWallet: address,
      });
      setIsLiked(true);
      toast.success('Added to favorites!');
    } catch (error) {
      console.error('Like failed:', error);
    }
  };

  const handlePurchaseSuccess = () => {
    toast.success('Order placed successfully!');
    // Could redirect to orders page or show order details
  };

  if (isLoading) {
    return (
      <div className="p-4 space-y-4">
        {/* Header skeleton */}
        <div className="flex items-center justify-between">
          <div className="shimmer w-10 h-10 rounded-full" />
          <div className="flex gap-2">
            <div className="shimmer w-10 h-10 rounded-full" />
            <div className="shimmer w-10 h-10 rounded-full" />
          </div>
        </div>
        
        {/* Image skeleton */}
        <div className="shimmer aspect-square rounded-2xl" />
        
        {/* Title skeleton */}
        <div className="space-y-2">
          <div className="shimmer h-8 w-3/4 rounded" />
          <div className="shimmer h-6 w-1/2 rounded" />
        </div>
        
        {/* Seller skeleton */}
        <div className="shimmer h-20 rounded-xl" />
        
        {/* Button skeleton */}
        <div className="shimmer h-14 rounded-xl" />
      </div>
    );
  }

  if (error || !data?.product) {
    return (
      <div className="p-4">
        <button onClick={handleBack} className="mb-4">
          <ChevronLeft className="w-6 h-6" />
        </button>
        <div className="glass-card p-8 text-center">
          <div className="text-4xl mb-4">😕</div>
          <h2 className="text-xl font-bold mb-2">Product Not Found</h2>
          <p className="text-[var(--muted-foreground)] text-sm mb-4">
            This product may have been removed or doesn't exist.
          </p>
          <button onClick={handleBack} className="btn-secondary">
            Go Back
          </button>
        </div>
      </div>
    );
  }

  const { product, seller } = data;

  return (
    <div className="pb-24">
      {/* Header */}
      <div className="sticky top-0 z-30 bg-[var(--background)]/80 backdrop-blur-lg">
        <div className="flex items-center justify-between p-4">
          <button
            onClick={handleBack}
            className="w-10 h-10 rounded-full bg-[var(--muted)] flex items-center justify-center"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          
          <div className="flex gap-2">
            <button
              onClick={handleLike}
              disabled={isLiked}
              className={`w-10 h-10 rounded-full flex items-center justify-center transition-colors ${
                isLiked 
                  ? 'bg-red-500/20 text-red-400' 
                  : 'bg-[var(--muted)] hover:bg-[var(--muted)]/80'
              }`}
            >
              <Heart className={`w-5 h-5 ${isLiked ? 'fill-current' : ''}`} />
            </button>
            <button
              onClick={handleShare}
              className="w-10 h-10 rounded-full bg-[var(--muted)] flex items-center justify-center hover:bg-[var(--muted)]/80"
            >
              <Share2 className="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="p-4 space-y-6">
        <ProductInfo product={product} seller={seller} />
      </div>

      {/* Fixed Buy Button */}
      <div className="fixed bottom-0 left-0 right-0 p-4 bg-[var(--background)]/95 backdrop-blur-lg border-t border-[var(--border)]">
        <div className="max-w-lg mx-auto">
          <BuyButton
            product={product}
            seller={product.seller}
            onSuccess={handlePurchaseSuccess}
          />
        </div>
      </div>
    </div>
  );
}
