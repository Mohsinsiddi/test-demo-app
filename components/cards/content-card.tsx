"use client";

import { Heart, MessageCircle, ExternalLink } from 'lucide-react';
import { FeedItem } from '@/hooks/use-feed';
import { useLike } from '@/hooks/use-like';
import { useUser } from '@/hooks/use-user';
import { useState } from 'react';

interface ContentCardProps {
  item: FeedItem;
}

export function ContentCard({ item }: ContentCardProps) {
  const { address } = useUser();
  const likeMutation = useLike();
  const [likes, setLikes] = useState(item.data.likes || 0);
  const [isLiked, setIsLiked] = useState(false);

  const handleLike = async () => {
    if (!address || isLiked) return;
    
    try {
      const result = await likeMutation.mutateAsync({
        itemId: item._id,
        itemType: 'content',
        userWallet: address,
      });
      setLikes(result.likes);
      setIsLiked(true);
    } catch (error) {
      console.error('Failed to like:', error);
    }
  };

  const getPlatformIcon = (platform?: string) => {
    switch (platform) {
      case 'youtube': return '▶️';
      case 'instagram': return '📸';
      case 'twitter': return '🐦';
      default: return '🔗';
    }
  };

  const getPlatformColor = (platform?: string) => {
    switch (platform) {
      case 'youtube': return 'from-red-500/20 to-red-600/20';
      case 'instagram': return 'from-pink-500/20 to-purple-500/20';
      case 'twitter': return 'from-blue-400/20 to-blue-500/20';
      default: return 'from-[var(--pay-purple)]/20 to-[var(--pay-green)]/20';
    }
  };

  const getTierBadge = (tier: number) => {
    switch (tier) {
      case 2: return { text: '★ Premium', class: 'badge-premium' };
      case 1: return { text: '✓ Verified', class: 'badge-verified' };
      default: return null;
    }
  };

  const tierBadge = item.user ? getTierBadge(item.user.tier) : null;

  return (
    <div className="glass-card overflow-hidden card-hover">
      {/* Thumbnail */}
      <div className={`h-32 bg-gradient-to-br ${getPlatformColor(item.data.platform)} flex items-center justify-center relative`}>
        <span className="text-4xl">{item.data.thumbnail || getPlatformIcon(item.data.platform)}</span>
        <span className="absolute top-2 left-2 bg-black/50 text-white text-xs px-2 py-1 rounded-full flex items-center gap-1">
          {getPlatformIcon(item.data.platform)} {item.data.platform}
        </span>
      </div>

      {/* Content */}
      <div className="p-4">
        {/* Title */}
        <h4 className="font-semibold mb-1 line-clamp-2">{item.data.title}</h4>

        {/* Creator */}
        <div className="flex items-center gap-2 mb-3">
          <span className="text-sm">{item.user?.avatar}</span>
          <span className="text-xs text-[var(--muted-foreground)]">
            @{item.user?.username || 'creator'}
          </span>
          {tierBadge && (
            <span className={`${tierBadge.class} text-xs`}>{tierBadge.text}</span>
          )}
        </div>

        {/* Actions */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4 text-xs text-[var(--muted-foreground)]">
            <button 
              onClick={handleLike}
              disabled={isLiked || likeMutation.isPending}
              className={`flex items-center gap-1 transition-colors ${
                isLiked ? 'text-red-400' : 'hover:text-red-400'
              }`}
            >
              <Heart className={`w-4 h-4 ${isLiked ? 'fill-current' : ''}`} />
              {likes.toLocaleString()}
            </button>
            <span className="flex items-center gap-1">
              <MessageCircle className="w-4 h-4" />
              {Math.floor(Math.random() * 100)}
            </span>
          </div>
          
          <div className="flex items-center gap-2">
            <a 
              href={item.data.url} 
              target="_blank" 
              rel="noopener noreferrer"
              className="p-2 rounded-lg bg-[var(--muted)] hover:bg-[var(--muted)]/80 transition-colors"
            >
              <ExternalLink className="w-4 h-4" />
            </a>
            <button className="tip-button text-sm py-2 px-3">
              💰 Tip
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
