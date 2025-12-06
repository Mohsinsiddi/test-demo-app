"use client";

import { useEffect, useState } from 'react';
import { APP_NAME, APP_TAGLINE } from '@/lib/constants';

interface SplashScreenProps {
  onComplete: () => void;
  duration?: number;
}

export function SplashScreen({ onComplete, duration = 2500 }: SplashScreenProps) {
  const [fadeOut, setFadeOut] = useState(false);

  useEffect(() => {
    const fadeTimer = setTimeout(() => setFadeOut(true), duration - 500);
    const completeTimer = setTimeout(onComplete, duration);
    return () => {
      clearTimeout(fadeTimer);
      clearTimeout(completeTimer);
    };
  }, [duration, onComplete]);

  return (
    <div className={`fixed inset-0 z-50 flex flex-col items-center justify-center gradient-bg transition-opacity duration-500 ${fadeOut ? 'opacity-0' : 'opacity-100'}`}>
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-[var(--pay-blue)] rounded-full blur-[150px] opacity-20 animate-pulse" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[300px] h-[300px] bg-[var(--pay-purple)] rounded-full blur-[100px] opacity-15 animate-pulse" style={{ animationDelay: '0.5s' }} />
      </div>
      <div className="relative z-10 flex flex-col items-center">
        <div className="relative mb-6">
          <div className="w-24 h-24 rounded-3xl gradient-border flex items-center justify-center animate-glow">
            <div className="w-[94px] h-[94px] rounded-[22px] bg-[var(--background)] flex items-center justify-center">
              <svg className="w-12 h-12" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
                <circle cx="24" cy="24" r="20" stroke="url(#logoGradient)" strokeWidth="3" fill="none" />
                <path d="M24 12V36M18 18C18 15.8 20.7 14 24 14C27.3 14 30 15.8 30 18C30 20.2 27.3 22 24 22C20.7 22 18 23.8 18 26C18 28.2 20.7 30 24 30C27.3 30 30 28.2 30 26" stroke="url(#logoGradient)" strokeWidth="2.5" strokeLinecap="round" />
                <defs>
                  <linearGradient id="logoGradient" x1="4" y1="4" x2="44" y2="44" gradientUnits="userSpaceOnUse">
                    <stop stopColor="#6366f1" />
                    <stop offset="0.5" stopColor="#a855f7" />
                    <stop offset="1" stopColor="#10b981" />
                  </linearGradient>
                </defs>
              </svg>
            </div>
          </div>
        </div>
        <h1 className="text-4xl font-bold text-gradient-brand mb-2">{APP_NAME}</h1>
        <p className="text-[var(--muted-foreground)] text-sm">{APP_TAGLINE}</p>
        <div className="mt-8 flex gap-1">
          <div className="w-2 h-2 rounded-full bg-[var(--pay-blue)] animate-bounce" style={{ animationDelay: '0ms' }} />
          <div className="w-2 h-2 rounded-full bg-[var(--pay-purple)] animate-bounce" style={{ animationDelay: '150ms' }} />
          <div className="w-2 h-2 rounded-full bg-[var(--pay-green)] animate-bounce" style={{ animationDelay: '300ms' }} />
        </div>
      </div>
    </div>
  );
}
