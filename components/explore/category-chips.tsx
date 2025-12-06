"use client";

import { STORE_CATEGORIES, CONTENT_CATEGORIES } from '@/lib/constants';

interface CategoryChipsProps {
  selected: string | null;
  onChange: (category: string | null) => void;
  type?: 'store' | 'content' | 'all';
}

export function CategoryChips({ selected, onChange, type = 'all' }: CategoryChipsProps) {
  const categories = type === 'content' 
    ? CONTENT_CATEGORIES 
    : type === 'store' 
      ? STORE_CATEGORIES 
      : [...STORE_CATEGORIES, ...CONTENT_CATEGORIES.filter(c => 
          !STORE_CATEGORIES.find(s => s.id === c.id)
        )];

  return (
    <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
      <button
        onClick={() => onChange(null)}
        className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all ${
          selected === null
            ? 'bg-gradient-to-r from-[var(--pay-blue)] to-[var(--pay-purple)] text-white'
            : 'bg-[var(--muted)] text-[var(--muted-foreground)] hover:bg-[var(--muted)]/80'
        }`}
      >
        All
      </button>
      
      {categories.map((cat) => (
        <button
          key={cat.id}
          onClick={() => onChange(cat.id === selected ? null : cat.id)}
          className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all flex items-center gap-1 ${
            selected === cat.id
              ? 'bg-gradient-to-r from-[var(--pay-blue)] to-[var(--pay-purple)] text-white'
              : 'bg-[var(--muted)] text-[var(--muted-foreground)] hover:bg-[var(--muted)]/80'
          }`}
        >
          <span>{cat.icon}</span>
          <span>{cat.label}</span>
        </button>
      ))}
    </div>
  );
}
