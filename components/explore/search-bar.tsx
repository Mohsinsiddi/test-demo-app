"use client";

import { useState, useEffect, useCallback } from 'react';
import { Search, X } from 'lucide-react';

interface SearchBarProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  autoFocus?: boolean;
}

export function SearchBar({ 
  value, 
  onChange, 
  placeholder = 'Search products, stores, creators...',
  autoFocus = false,
}: SearchBarProps) {
  const [localValue, setLocalValue] = useState(value);

  // Debounce the onChange callback
  useEffect(() => {
    const timer = setTimeout(() => {
      onChange(localValue);
    }, 300);

    return () => clearTimeout(timer);
  }, [localValue, onChange]);

  // Sync with external value changes
  useEffect(() => {
    setLocalValue(value);
  }, [value]);

  const handleClear = useCallback(() => {
    setLocalValue('');
    onChange('');
  }, [onChange]);

  return (
    <div className="relative">
      <div className="absolute left-4 top-1/2 -translate-y-1/2 text-[var(--muted-foreground)]">
        <Search className="w-5 h-5" />
      </div>
      
      <input
        type="text"
        value={localValue}
        onChange={(e) => setLocalValue(e.target.value)}
        placeholder={placeholder}
        autoFocus={autoFocus}
        className="w-full pl-12 pr-10 py-3 bg-[var(--muted)] border border-[var(--border)] rounded-xl text-sm focus:outline-none focus:border-[var(--pay-blue)] focus:ring-2 focus:ring-[var(--pay-blue)]/20 transition-all"
      />
      
      {localValue && (
        <button
          onClick={handleClear}
          className="absolute right-3 top-1/2 -translate-y-1/2 p-1 rounded-full hover:bg-[var(--border)] transition-colors"
        >
          <X className="w-4 h-4 text-[var(--muted-foreground)]" />
        </button>
      )}
    </div>
  );
}
