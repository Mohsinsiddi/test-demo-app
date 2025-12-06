"use client";

import { use } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { useContent } from '@/hooks/use-content';
import { ContentCard } from '@/components/cards/content-card';
import { ChevronLeft, Play, Coins, Share2 } from 'lucide-react';
import { UserTier } from '@/types';
import { toast } from 'sonner';

interface CreatorPageProps {
  params: Promise<{ wallet: string }>;
}

export default function CreatorPage({ params }: CreatorPageProps) {
  const { wallet } = use(params);
  const router = useRouter();

  // Fetch creator info
  const { data: creatorData, isLoading: isCreatorLoading } = useQuery({
    queryKey: ['creator', wallet],
    queryFn: async () => {
      const res = await fetch(`/api/users?wallet=${wallet}`);
      const json = await res.json();
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
  });

  // Fetch creator content
  const { data: contentData, isLoading: isContentLoading } = useContent({
    creator: wallet,
    limit: 50,
  });

  // Fetch tip stats
  const { data: tipStats } = useQuery({
    queryKey: ['tips', 'to', wallet],
    queryFn: async () => {
      const res = await fetch(`/api/tips?to=${wallet}`);
      const json = await res.json();
      if (!json.success) throw new Error(json.error);
      return json.data.stats;
    },
  });

  const handleBack = () => router.back();

  const handleShare = async () => {
    try {
      if (navigator.share) {
        await navigator.share({
          title: creatorData?.displayName || 'Creator',
          text: `Check out ${creatorData?.displayName} on BasePay!`,
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
        return { text: '★ Premium Creator', class: 'badge-premium' };
      case UserTier.Verified:
        return { text: '✓ Verified Creator', class: 'badge-verified' };
      default:
        return { text: 'Creator', class: 'badge-info' };
    }
  };

  const formatTips = (amount?: string) => {
    if (!amount || amount === '0') return '0';
    const num = parseFloat(amount) / 1e18;
    return num.toFixed(4).replace(/\.?0+$/, '');
  };

  if (isCreatorLoading) {
    return (
      <div className="pb-20">
        <div className="shimmer h-32 w-full" />
        <div className="p-4 space-y-4">
          <div className="flex items-start gap-4">
            <div className="shimmer w-20 h-20 rounded-full -mt-10" />
            <div className="flex-1 space-y-2 pt-10">
              <div className="shimmer h-6 w-3/4 rounded" />
              <div className="shimmer h-4 w-1/2 rounded" />
            </div>
          </div>
          <div className="shimmer h-20 rounded-xl" />
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className="shimmer h-40 rounded-xl" />
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (!creatorData) {
    return (
      <div className="p-4">
        <button onClick={handleBack} className="mb-4">
          <ChevronLeft className="w-6 h-6" />
        </button>
        <div className="glass-card p-8 text-center">
          <div className="text-4xl mb-4">😕</div>
          <h2 className="text-xl font-bold mb-2">Creator Not Found</h2>
          <button onClick={handleBack} className="btn-secondary mt-4">
            Go Back
          </button>
        </div>
      </div>
    );
  }

  const tierInfo = getTierBadge(creatorData.tier);

  return (
    <div className="pb-20">
      {/* Banner */}
      <div className="h-32 bg-gradient-to-br from-[var(--pay-purple)]/40 to-[var(--pay-green)]/40 relative">
        {creatorData.banner && (
          <img src={creatorData.banner} alt="" className="w-full h-full object-cover" />
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
          <div className="w-20 h-20 rounded-full bg-[var(--muted)] border-4 border-[var(--background)] flex items-center justify-center text-4xl shrink-0">
            {creatorData.avatar || '🎨'}
          </div>
          <div className="pt-10">
            <h1 className="text-xl font-bold">{creatorData.displayName}</h1>
            {creatorData.username && (
              <p className="text-sm text-[var(--muted-foreground)]">
                @{creatorData.username}
              </p>
            )}
          </div>
        </div>

        {/* Badge */}
        <div className="flex flex-wrap items-center gap-2 mt-4">
          <span className={tierInfo.class}>{tierInfo.text}</span>
        </div>

        {/* Bio */}
        {creatorData.bio && (
          <p className="mt-4 text-sm text-[var(--muted-foreground)]">
            {creatorData.bio}
          </p>
        )}

        {/* Social links */}
        {(creatorData.youtube || creatorData.instagram || creatorData.twitter) && (
          <div className="flex gap-2 mt-4">
            {creatorData.youtube && (
              <a
                href={creatorData.youtube}
                target="_blank"
                rel="noopener noreferrer"
                className="px-3 py-1 bg-red-500/20 text-red-400 rounded-full text-sm"
              >
                YouTube
              </a>
            )}
            {creatorData.instagram && (
              <a
                href={creatorData.instagram}
                target="_blank"
                rel="noopener noreferrer"
                className="px-3 py-1 bg-pink-500/20 text-pink-400 rounded-full text-sm"
              >
                Instagram
              </a>
            )}
            {creatorData.twitter && (
              <a
                href={creatorData.twitter}
                target="_blank"
                rel="noopener noreferrer"
                className="px-3 py-1 bg-blue-500/20 text-blue-400 rounded-full text-sm"
              >
                Twitter
              </a>
            )}
          </div>
        )}

        {/* Stats */}
        <div className="glass-card p-4 mt-4 grid grid-cols-3 gap-4 text-center">
          <div>
            <div className="text-xl font-bold text-[var(--pay-purple)]">
              {contentData?.content?.length || 0}
            </div>
            <div className="text-xs text-[var(--muted-foreground)]">Posts</div>
          </div>
          <div>
            <div className="text-xl font-bold text-[var(--pay-gold)]">
              {formatTips(tipStats?.totalAmount)} ETH
            </div>
            <div className="text-xs text-[var(--muted-foreground)]">Tips Received</div>
          </div>
          <div>
            <div className="text-xl font-bold text-[var(--pay-green)]">
              {tipStats?.count || 0}
            </div>
            <div className="text-xs text-[var(--muted-foreground)]">Supporters</div>
          </div>
        </div>

        {/* Tip button */}
        <button className="w-full tip-button justify-center mt-4">
          💰 Send Tip
        </button>

        {/* Content */}
        <div className="mt-6">
          <h2 className="text-lg font-semibold mb-3 flex items-center gap-2">
            <Play className="w-5 h-5" />
            Content
          </h2>

          {isContentLoading ? (
            <div className="space-y-4">
              {[1, 2, 3].map((i) => (
                <div key={i} className="shimmer h-40 rounded-xl" />
              ))}
            </div>
          ) : contentData?.content?.length > 0 ? (
            <div className="space-y-4">
              {contentData.content.map((content: any) => (
                <ContentCard
                  key={content._id}
                  item={{
                    _id: content._id,
                    type: 'content',
                    createdAt: content.createdAt,
                    data: {
                      platform: content.platform,
                      url: content.url,
                      title: content.title,
                      description: content.description,
                      thumbnail: content.thumbnail,
                      category: content.category,
                      suggestedTip: content.suggestedTip,
                      likes: content.likes,
                      tips: content.tips,
                    },
                    user: {
                      wallet: creatorData.wallet,
                      displayName: creatorData.displayName,
                      username: creatorData.username,
                      avatar: creatorData.avatar,
                      tier: creatorData.tier,
                      userType: creatorData.userType,
                    },
                  }}
                />
              ))}
            </div>
          ) : (
            <div className="glass-card p-8 text-center">
              <div className="text-4xl mb-4">📺</div>
              <p className="text-[var(--muted-foreground)]">No content yet</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
