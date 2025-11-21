export interface Book {
  _id: string;
  title: string;
  author: string;
  description: string;
  price: number;
  category: string;
  coverImage: string;
  rating: number;
  reviewCount: number;
  inStock: boolean;
  stockCount: number;
  isbn?: string;
  publisher?: string;
  publishedDate?: string;
  tags?: string[];
}

export interface CartItem {
  bookId: string;
  book: Book;
  quantity: number;
  price: number;
  subtotal: number;
}

export interface Cart {
  userId: string;
  items: CartItem[];
  totalItems: number;
  totalPrice: number;
  createdAt: string;
  updatedAt: string;
}

export interface Review {
  _id: string;
  bookId: string;
  userId: string;
  userName: string;
  rating: number;
  text: string;
  verifiedPurchase: boolean;
  createdAt: string;
  helpful: number;
}

export interface Rating {
  bookId: string;
  averageRating: number;
  totalRatings: number;
  distribution: {
    [key: number]: number;
  };
}

export interface User {
  _id: string;
  email: string;
  name: string;
  avatar?: string;
  addresses: Address[];
  wishlist: string[];
  preferences?: UserPreferences;
  createdAt: string;
}

export interface Address {
  _id: string;
  street: string;
  city: string;
  state: string;
  postalCode: string;
  country: string;
  isDefault: boolean;
}

export interface UserPreferences {
  favoriteCategories: string[];
  notifications: boolean;
  newsletter: boolean;
}

export interface Order {
  _id: string;
  userId: string;
  items: Array<{
    bookId: string;
    title: string;
    quantity: number;
    price: number;
  }>;
  totalAmount: number;
  status: 'pending' | 'confirmed' | 'shipped' | 'delivered' | 'cancelled';
  paymentStatus: 'pending' | 'completed' | 'failed';
  shippingAddress: Address;
  trackingNumber?: string;
  createdAt: string;
  updatedAt: string;
}

export interface SearchFilters {
  category?: string;
  priceRange?: [number, number];
  rating?: number;
  inStockOnly?: boolean;
  sortBy?: 'relevance' | 'price' | 'rating' | 'newest';
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  hasMore: boolean;
}
