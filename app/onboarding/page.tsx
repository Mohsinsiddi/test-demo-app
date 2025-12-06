"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useUser } from "@/hooks/use-user";
import { UserType } from "@/types";
import { APP_NAME, STORE_CATEGORIES } from "@/lib/constants";
import { toast } from "sonner";
import { ChevronLeft, Loader2, Store, Palette, ShoppingBag } from "lucide-react";

type Step = 'type' | 'profile' | 'complete';

export default function OnboardingPage() {
  const router = useRouter();
  const { address, isConnected, registerUserAsync, isRegistering } = useUser();
  
  const [step, setStep] = useState<Step>('type');
  const [userType, setUserType] = useState<UserType | null>(null);
  const [displayName, setDisplayName] = useState('');
  const [username, setUsername] = useState('');
  const [bio, setBio] = useState('');
  const [storeName, setStoreName] = useState('');
  const [storeCategory, setStoreCategory] = useState('');

  if (!isConnected) {
    return (
      <div className="min-h-screen gradient-bg p-4 flex items-center justify-center">
        <div className="glass-card p-6 text-center max-w-md">
          <div className="text-4xl mb-4">🔗</div>
          <h2 className="text-xl font-bold mb-2">Connect Your Wallet</h2>
          <p className="text-[var(--muted-foreground)] text-sm">
            Please connect your wallet to continue.
          </p>
        </div>
      </div>
    );
  }

  const handleTypeSelect = (type: UserType) => {
    setUserType(type);
    setStep('profile');
  };

  const handleBack = () => {
    if (step === 'profile') setStep('type');
  };

  const handleSubmit = async () => {
    if (!userType || !address) return;

    if (!displayName.trim()) {
      toast.error('Please enter a display name');
      return;
    }

    if (userType === UserType.Store && !storeName.trim()) {
      toast.error('Please enter a store name');
      return;
    }

    try {
      await registerUserAsync({
        userType,
        displayName: displayName.trim(),
        username: username.trim() || displayName.trim().toLowerCase().replace(/\s+/g, ''),
        bio: bio.trim(),
        storeName: storeName.trim(),
        storeCategory,
      });

      setStep('complete');
      toast.success('Profile created successfully!');
      
      setTimeout(() => router.push('/'), 2000);
    } catch (error) {
      console.error('Registration error:', error);
      toast.error('Failed to create profile. Please try again.');
    }
  };

  return (
    <div className="min-h-screen gradient-bg">
      {/* Progress bar */}
      <div className="h-1 bg-[var(--border)]">
        <div 
          className="h-full bg-gradient-to-r from-[var(--pay-blue)] to-[var(--pay-purple)] transition-all duration-500"
          style={{ width: step === 'type' ? '33%' : step === 'profile' ? '66%' : '100%' }}
        />
      </div>

      <div className="p-4 max-w-md mx-auto">
        {/* Header */}
        <div className="text-center py-6">
          <h1 className="text-2xl font-bold text-gradient-brand mb-2">
            {step === 'type' && 'Choose Your Role'}
            {step === 'profile' && 'Set Up Profile'}
            {step === 'complete' && 'Welcome to BasePay!'}
          </h1>
          <p className="text-[var(--muted-foreground)] text-sm">
            {step === 'type' && 'How will you use BasePay?'}
            {step === 'profile' && 'Tell us about yourself'}
            {step === 'complete' && 'Your profile is ready'}
          </p>
        </div>

        {/* Step: Type Selection */}
        {step === 'type' && (
          <div className="space-y-4">
            <button
              onClick={() => handleTypeSelect(UserType.Store)}
              className="w-full glass-card p-5 card-hover text-left flex items-start gap-4"
            >
              <div className="w-12 h-12 rounded-xl bg-[var(--pay-blue)]/20 flex items-center justify-center">
                <Store className="w-6 h-6 text-[var(--pay-blue)]" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold mb-1">🏪 Store Owner</h3>
                <p className="text-sm text-[var(--muted-foreground)]">
                  Sell products, manage orders, grow your business
                </p>
              </div>
            </button>

            <button
              onClick={() => handleTypeSelect(UserType.Creator)}
              className="w-full glass-card p-5 card-hover text-left flex items-start gap-4"
            >
              <div className="w-12 h-12 rounded-xl bg-[var(--pay-purple)]/20 flex items-center justify-center">
                <Palette className="w-6 h-6 text-[var(--pay-purple)]" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold mb-1">🎨 Content Creator</h3>
                <p className="text-sm text-[var(--muted-foreground)]">
                  Share content, receive tips, build your audience
                </p>
              </div>
            </button>

            <div className="divider my-4" />

            <button
              onClick={() => router.push('/')}
              className="w-full text-center text-sm text-[var(--muted-foreground)] py-2"
            >
              Skip for now, just browse
            </button>
          </div>
        )}

        {/* Step: Profile */}
        {step === 'profile' && (
          <div className="space-y-4">
            <button
              onClick={handleBack}
              className="flex items-center gap-1 text-sm text-[var(--muted-foreground)] mb-4"
            >
              <ChevronLeft className="w-4 h-4" /> Back
            </button>

            <div className="glass-card p-4">
              <label className="block text-sm font-medium mb-2">Display Name *</label>
              <input
                type="text"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                placeholder="Your name"
                className="w-full bg-[var(--muted)] border border-[var(--border)] rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-[var(--pay-blue)]"
              />
            </div>

            <div className="glass-card p-4">
              <label className="block text-sm font-medium mb-2">Username</label>
              <div className="flex items-center">
                <span className="text-[var(--muted-foreground)] text-sm mr-1">@</span>
                <input
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, ''))}
                  placeholder="username"
                  className="flex-1 bg-[var(--muted)] border border-[var(--border)] rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-[var(--pay-blue)]"
                />
              </div>
            </div>

            <div className="glass-card p-4">
              <label className="block text-sm font-medium mb-2">Bio</label>
              <textarea
                value={bio}
                onChange={(e) => setBio(e.target.value)}
                placeholder="Tell us about yourself..."
                rows={3}
                className="w-full bg-[var(--muted)] border border-[var(--border)] rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-[var(--pay-blue)] resize-none"
              />
            </div>

            {userType === UserType.Store && (
              <>
                <div className="glass-card p-4">
                  <label className="block text-sm font-medium mb-2">Store Name *</label>
                  <input
                    type="text"
                    value={storeName}
                    onChange={(e) => setStoreName(e.target.value)}
                    placeholder="Your store name"
                    className="w-full bg-[var(--muted)] border border-[var(--border)] rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-[var(--pay-blue)]"
                  />
                </div>

                <div className="glass-card p-4">
                  <label className="block text-sm font-medium mb-2">Category</label>
                  <select
                    value={storeCategory}
                    onChange={(e) => setStoreCategory(e.target.value)}
                    className="w-full bg-[var(--muted)] border border-[var(--border)] rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-[var(--pay-blue)]"
                  >
                    <option value="">Select category</option>
                    {STORE_CATEGORIES.map((cat) => (
                      <option key={cat.id} value={cat.id}>
                        {cat.icon} {cat.label}
                      </option>
                    ))}
                  </select>
                </div>
              </>
            )}

            <button
              onClick={handleSubmit}
              disabled={isRegistering}
              className="w-full btn-pay flex items-center justify-center gap-2"
            >
              {isRegistering ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Creating Profile...
                </>
              ) : (
                'Create Profile'
              )}
            </button>
          </div>
        )}

        {/* Step: Complete */}
        {step === 'complete' && (
          <div className="text-center py-8">
            <div className="w-20 h-20 rounded-full bg-[var(--pay-green)]/20 flex items-center justify-center mx-auto mb-6">
              <span className="text-4xl">✓</span>
            </div>
            <h2 className="text-xl font-bold mb-2">You're All Set!</h2>
            <p className="text-[var(--muted-foreground)] text-sm mb-6">
              Redirecting you to the feed...
            </p>
            <div className="shimmer h-2 w-32 mx-auto rounded-full" />
          </div>
        )}
      </div>
    </div>
  );
}
