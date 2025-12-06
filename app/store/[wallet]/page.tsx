"use client";

import { use } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { useProducts } from '@/hooks/use-products';
import { ProductCard } from '@/components/cards/product-card';
import { ChevronLeft, MapPin, Package, Star, Share2 } from 'lucide-react';
import { UserTier } from '@/types';
import { toast } from 'sonner';

interface StorePageProps {
  params: Promise<{ wallet: string }>;
}

export default function StorePage({ params }: StorePageProps) {
  const { wallet } = use(params);
  const router = useRouter();

  // Fetch store info
  const { data: storeData, isLoading: isStoreLoading } = useQuery({
    queryKey: ['store', wallet],
    queryFn: async () => {
      const res = await fetch(`/api/users?wallet=${wallet}`);
      const json = await res.json();
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
  });

  // Fetch store products
  const { data: productsData, isLoading: isProductsLoading } = useProducts({
    seller: wallet,
    limit: 50,
  });

  const handleBack = () => router.back();

  const handleShare = async () => {
    try {
      if (navigator.share) {
        await navigator.share({
          title: storeData?.storeName || 'Store',
          text: `Check out ${storeData?.storeName} on BasePay!`,
          url: window.location.href,
        });
      } else {
        await navigator.clipboard.writeText(window.location.href);
        toast.success('Link copied!');
      }
    } catch (error) {
      console.error('Share failed:', error);
    }
  };

  const getTierBadge = (tier?: number) => {
    switch (tier) {
      case UserTier.Premium:
        return { text: '★ Premium Seller', class: 'badge-premium', fee: '0.5%' };
      case UserTier.Verified:
        return { text: '✓ Verified Seller', class: 'badge-verified', fee: '1%' };
      default:
        return { text: 'New Seller', class: 'badge-info', fee: '2%' };
    }
  };

  if (isStoreLoading) {
    return (
      <div className="pb-20">
        <div className="shimmer h-32 w-full" />
        <div className="p-4 space-y-4">
          <div className="flex items-start gap-4">
            <div className="shimmer w-20 h-20 rounded-xl -mt-10" />
            <div className="flex-1 space-y-2">
              <div className="shimmer h-6 w-3/4 rounded" />
              <div className="shimmer h-4 w-1/2 rounded" />
            </div>
          </div>
          <div className="shimmer h-20 rounded-xl" />
          <div className="grid grid-cols-2 gap-4">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="shimmer h-48 rounded-xl" />
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (!storeData) {
    return (
      <div className="p-4">
        <button onClick={handleBack} className="mb-4">
          <ChevronLeft className="w-6 h-6" />
        </button>
        <div className="glass-card p-8 text-center">
          <div className="text-4xl mb-4">😕</div>
          <h2 className="text-xl font-bold mb-2">Store Not Found</h2>
          <button onClick={handleBack} className="btn-secondary mt-4">
            Go Back
          </button>
        </div>
      </div>
    );
  }

  const tierInfo = getTierBadge(storeData.tier);

  return (
    <div className="pb-20">
      {/* Banner */}
      <div className="h-32 bg-gradient-to-br from-[var(--pay-blue)]/40 to-[var(--pay-purple)]/40 relative">
        {storeData.banner && (
          <img src={storeData.banner} alt="" className="w-full h-full object-cover" />
        )}
        
        {/* Header buttons */}
        <div className="absolute top-4 left-4 right-4 flex justify-between">
          <button
            onClick={handleBack}
            className="w-10 h-10 rounded-full bg-black/50 backdrop-blur flex items-center justify-center"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          <button
            onClick={handleShare}
            className="w-10 h-10 rounded-full bg-black/50 backdrop-blur flex items-center justify-center"
          >
            <Share2 className="w-5 h-5" />
          </button>
        </div>
      </div>

      <div className="p-4">
        {/* Avatar and basic info */}
        <div className="flex items-start gap-4 -mt-10 relative z-10">
          <div className="w-20 h-20 rounded-xl bg-[var(--muted)] border-4 border-[var(--background)] flex items-center justify-center text-4xl shrink-0">
            {storeData.avatar || '🏪'}
          </div>
          <div className="pt-10">
            <h1 className="text-xl font-bold">
              {storeData.storeName || storeData.displayName}
            </h1>
            {storeData.username && (
              <p className="text-sm text-[var(--muted-foreground)]">
                @{storeData.username}
              </p>
            )}
          </div>
        </div>

        {/* Badges and location */}
        <div className="flex flex-wrap items-center gap-2 mt-4">
          <span className={tierInfo.class}>{tierInfo.text}</span>
          {storeData.storeCategory && (
            <span className="badge-info">{storeData.storeCategory}</span>
          )}
          {storeData.location && (
            <span className="flex items-center gap-1 text-sm text-[var(--muted-foreground)]">
              <MapPin className="w-3 h-3" />
              {storeData.location}
            </span>
          )}
        </div>

        {/* Bio */}
        {storeData.bio && (
          <p className="mt-4 text-sm text-[var(--muted-foreground)]">
            {storeData.bio}
          </p>
        )}

        {/* Stats */}
        <div className="glass-card p-4 mt-4 grid grid-cols-3 gap-4 text-center">
          <div>
            <div className="text-xl font-bold text-[var(--pay-blue)]">
              {productsData?.products?.length || 0}
            </div>
            <div className="text-xs text-[var(--muted-foreground)]">Products</div>
          </div>
          <div>
            <div className="text-xl font-bold text-[var(--pay-green)]">
              {tierInfo.fee}
            </div>
            <div className="text-xs text-[var(--muted-foreground)]">Fee Rate</div>
          </div>
          <div>
            <div className="text-xl font-bold text-[var(--pay-purple)]">
              {storeData.tier === UserTier.Premium ? '★' : storeData.tier === UserTier.Verified ? '✓' : '-'}
            </div>
            <div className="text-xs text-[var(--muted-foreground)]">Tier</div>
          </div>
        </div>

        {/* Products */}
        <div className="mt-6">
          <h2 className="text-lg font-semibold mb-3 flex items-center gap-2">
            <Package className="w-5 h-5" />
            Products
          </h2>

          {isProductsLoading ? (
            <div className="grid grid-cols-2 gap-4">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="shimmer h-48 rounded-xl" />
              ))}
            </div>
          ) : productsData?.products?.length > 0 ? (
            <div className="grid grid-cols-2 gap-4">
              {productsData.products.map((product: any) => (
                <ProductCard
                  key={product._id}
                  item={{
                    _id: product._id,
                    type: 'product',
                    createdAt: product.createdAt,
                    data: {
                      title: product.title,
                      description: product.description,
                      price: product.price,
                      images: product.images,
                      category: product.category,
                      stock: product.stock,
                    },
                    user: {
                      wallet: storeData.wallet,
                      displayName: storeData.displayName,
                      storeName: storeData.storeName,
                      username: storeData.username,
                      avatar: storeData.avatar,
                      tier: storeData.tier,
                      userType: storeData.userType,
                    },
                  }}
                />
              ))}
            </div>
          ) : (
            <div className="glass-card p-8 text-center">
              <div className="text-4xl mb-4">📦</div>
              <p className="text-[var(--muted-foreground)]">No products yet</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
