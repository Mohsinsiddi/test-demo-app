"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Product } from "@/types";

interface ProductsResponse {
  products: Product[];
  total: number;
  hasMore: boolean;
}

interface CreateProductData {
  seller: string;
  title: string;
  description?: string;
  price: string;
  images?: string[];
  category?: string;
  stock?: number;
  deliveryOptions?: {
    pickup: boolean;
    shipping: boolean;
  };
}

export function useProducts(options?: {
  seller?: string;
  category?: string;
  search?: string;
  limit?: number;
}) {
  const { seller, category, search, limit = 20 } = options || {};

  return useQuery({
    queryKey: ["products", seller, category, search, limit],
    queryFn: async (): Promise<ProductsResponse> => {
      const params = new URLSearchParams();
      params.set('limit', limit.toString());
      if (seller) params.set('seller', seller);
      if (category) params.set('category', category);
      if (search) params.set('search', search);
      
      const res = await fetch(`/api/products?${params.toString()}`);
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    staleTime: 1000 * 60 * 2,
  });
}

export function useProduct(id: string) {
  return useQuery({
    queryKey: ["product", id],
    queryFn: async () => {
      const res = await fetch(`/api/products/${id}`);
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    enabled: !!id,
  });
}

export function useCreateProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: CreateProductData): Promise<Product> => {
      const res = await fetch("/api/products", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      const json = await res.json();
      
      if (!json.success) throw new Error(json.error);
      return json.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["products"] });
      queryClient.invalidateQueries({ queryKey: ["feed"] });
    },
  });
}
