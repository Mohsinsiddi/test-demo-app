"use client";

import { FilterType } from '@/hooks/use-feed';

interface FeedFiltersProps {
  activeFilter: FilterType;
  onFilterChange: (filter: FilterType) => void;
}

const FILTERS: { value: FilterType; label: string }[] = [
  { value: 'all', label: 'All' },
  { value: 'products', label: 'Products' },
  { value: 'creators', label: 'Creators' },
];

export function FeedFilters({ activeFilter, onFilterChange }: FeedFiltersProps) {
  return (
    <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
      {FILTERS.map((filter) => (
        <button
          key={filter.value}
          onClick={() => onFilterChange(filter.value)}
          className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all ${
            activeFilter === filter.value
              ? 'bg-gradient-to-r from-[var(--pay-blue)] to-[var(--pay-purple)] text-white'
              : 'bg-[var(--muted)] text-[var(--muted-foreground)] hover:bg-[var(--muted)]/80'
          }`}
        >
          {filter.label}
        </button>
      ))}
    </div>
  );
}
