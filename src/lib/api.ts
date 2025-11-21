import axios, { AxiosInstance } from 'axios';
import { getDummyBooks, searchDummyBooks, getDummyBooksByCategory, getDummyBookById } from './dummyData';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080/api';
const USE_DUMMY_DATA = process.env.NEXT_PUBLIC_USE_DUMMY_DATA === 'true';

const apiClient: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor
apiClient.interceptors.request.use(
  (config) => {
    const token = typeof window !== 'undefined' ? localStorage.getItem('authToken') : null;
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401 && typeof window !== 'undefined') {
      localStorage.removeItem('authToken');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Book Service with dummy data fallback
export const bookService = {
  getBooks: async (page = 1, limit = 12) => {
    if (USE_DUMMY_DATA) {
      const dummyData = getDummyBooks(page, limit);
      return {
        data: {
          data: dummyData.data,
          total: dummyData.total,
          page: dummyData.page,
          limit: dummyData.limit,
          hasMore: dummyData.hasMore,
        },
      };
    }
    try {
      return await apiClient.get('/books', { params: { page, limit } });
    } catch (error) {
      console.warn('API request failed, falling back to dummy data:', error);
      const dummyData = getDummyBooks(page, limit);
      return {
        data: {
          data: dummyData.data,
          total: dummyData.total,
          page: dummyData.page,
          limit: dummyData.limit,
          hasMore: dummyData.hasMore,
        },
      };
    }
  },

  getBook: async (bookId: string) => {
    if (USE_DUMMY_DATA) {
      const book = getDummyBookById(bookId);
      return { data: book };
    }
    try {
      return await apiClient.get(`/books/${bookId}`);
    } catch (error) {
      console.warn('API request failed, falling back to dummy data:', error);
      const book = getDummyBookById(bookId);
      return { data: book };
    }
  },

  getBookById: async (bookId: string) => {
    // Alias for consistency with other pages
    return bookService.getBook(bookId);
  },

  searchBooks: async (query: string, filters?: Record<string, any>) => {
    if (USE_DUMMY_DATA) {
      const results = searchDummyBooks(query);
      return { data: { data: results, total: results.length } };
    }
    try {
      return await apiClient.get('/search', { params: { q: query, ...filters } });
    } catch (error) {
      console.warn('API request failed, falling back to dummy data:', error);
      const results = searchDummyBooks(query);
      return { data: { data: results, total: results.length } };
    }
  },

  getBooksByCategory: async (category: string) => {
    if (USE_DUMMY_DATA) {
      const results = getDummyBooksByCategory(category);
      return { data: { data: results, total: results.length } };
    }
    try {
      return await apiClient.get('/books/category', { params: { category } });
    } catch (error) {
      console.warn('API request failed, falling back to dummy data:', error);
      const results = getDummyBooksByCategory(category);
      return { data: { data: results, total: results.length } };
    }
  },
};

// Cart Service with dummy data fallback
export const cartService = {
  getCart: async (userId: string) => {
    if (USE_DUMMY_DATA) {
      // Return dummy cart data
      return {
        data: {
          userId,
          items: getDummyBooks(1, 3).data.map((book, idx) => ({
            bookId: book._id,
            book,
            quantity: idx + 1,
            price: book.price,
            subtotal: book.price * (idx + 1),
          })),
          totalItems: 3,
          totalPrice: 0,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        },
      };
    }
    try {
      return await apiClient.get(`/cart/${userId}`);
    } catch (error) {
      console.warn('Cart API failed, falling back to dummy data:', error);
      return {
        data: {
          userId,
          items: [],
          totalItems: 0,
          totalPrice: 0,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        },
      };
    }
  },

  addToCart: async (userId: string, bookId: string, qty: number) => {
    if (USE_DUMMY_DATA) {
      return { data: { success: true } };
    }
    try {
      return await apiClient.post(`/cart/${userId}/items`, { bookId, qty });
    } catch (error) {
      console.warn('Add to cart API failed:', error);
      return { data: { success: false } };
    }
  },

  updateCartItem: async (userId: string, bookId: string, qty: number) => {
    if (USE_DUMMY_DATA) {
      return { data: { success: true } };
    }
    try {
      return await apiClient.put(`/cart/${userId}/items/${bookId}`, { qty });
    } catch (error) {
      console.warn('Update cart API failed:', error);
      return { data: { success: false } };
    }
  },

  removeCartItem: async (userId: string, bookId: string) => {
    if (USE_DUMMY_DATA) {
      return { data: { success: true } };
    }
    try {
      return await apiClient.delete(`/cart/${userId}/items/${bookId}`);
    } catch (error) {
      console.warn('Remove from cart API failed:', error);
      return { data: { success: false } };
    }
  },

  removeFromCart: async (userId: string, bookId: string) => {
    // Alias for backward compatibility
    return cartService.removeCartItem(userId, bookId);
  },

  checkout: async (userId: string) => {
    if (USE_DUMMY_DATA) {
      return { data: { orderId: 'dummy-order-123' } };
    }
    try {
      return await apiClient.post(`/cart/${userId}/checkout`);
    } catch (error) {
      console.warn('Checkout API failed:', error);
      return { data: { orderId: null } };
    }
  },
};

// Search Service with dummy data fallback
export const searchService = {
  search: async (query: string, filters?: any) => {
    if (USE_DUMMY_DATA) {
      let results = searchDummyBooks(query);
      
      // Apply filters
      if (filters?.category) {
        results = results.filter(book => book.category === filters.category);
      }
      if (filters?.priceRange) {
        const [min, max] = filters.priceRange;
        results = results.filter(book => book.price >= min && book.price <= max);
      }
      if (filters?.rating) {
        results = results.filter(book => book.rating >= filters.rating);
      }
      if (filters?.inStockOnly) {
        results = results.filter(book => book.inStock);
      }
      
      // Apply sorting
      if (filters?.sortBy === 'price') {
        results.sort((a, b) => a.price - b.price);
      } else if (filters?.sortBy === 'rating') {
        results.sort((a, b) => b.rating - a.rating);
      } else if (filters?.sortBy === 'newest') {
        // Newest books first (assuming they have publishedDate)
        results.sort((a, b) => {
          const dateA = new Date(a.publishedDate || 0);
          const dateB = new Date(b.publishedDate || 0);
          return dateB.getTime() - dateA.getTime();
        });
      }
      
      return {
        data: {
          data: results,
          total: results.length,
          page: 1,
          limit: results.length,
          hasMore: false,
        },
      };
    }
    try {
      return await apiClient.get('/search', { params: { q: query, ...filters } });
    } catch (error) {
      console.warn('Search API failed, falling back to dummy data:', error);
      const results = searchDummyBooks(query);
      return {
        data: {
          data: results,
          total: results.length,
          page: 1,
          limit: results.length,
          hasMore: false,
        },
      };
    }
  },
};

// Recommendation Service with dummy data fallback
export const recommendationService = {
  getUserRecommendations: async (userId: string) => {
    if (USE_DUMMY_DATA) {
      const recommendations = getDummyBooks(1, 4).data;
      return { data: recommendations };
    }
    try {
      return await apiClient.get(`/reco/user/${userId}`);
    } catch (error) {
      console.warn('Recommendation API failed, falling back to dummy data:', error);
      const recommendations = getDummyBooks(1, 4).data;
      return { data: recommendations };
    }
  },

  getSimilarBooks: async (bookId: string) => {
    if (USE_DUMMY_DATA) {
      const similar = getDummyBooks(1, 4).data;
      return { data: similar };
    }
    try {
      return await apiClient.get(`/reco/book/${bookId}`);
    } catch (error) {
      console.warn('Similar books API failed, falling back to dummy data:', error);
      const similar = getDummyBooks(1, 4).data;
      return { data: similar };
    }
  },

  getBookRecommendations: async (bookId: string) => {
    // Alias for consistency
    return recommendationService.getSimilarBooks(bookId);
  },
};

// Reviews & Ratings Service with dummy data fallback
export const reviewService = {
  getBookReviews: async (bookId: string) => {
    if (USE_DUMMY_DATA) {
      const dummyReviews = [
        {
          _id: '1',
          bookId,
          userId: 'user1',
          userName: 'John Smith',
          rating: 5,
          text: 'Absolutely loved this book! Could not put it down.',
          verifiedPurchase: true,
          createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
          helpful: 12,
        },
        {
          _id: '2',
          bookId,
          userId: 'user2',
          userName: 'Sarah Johnson',
          rating: 4,
          text: 'Great read with compelling characters. Highly recommend!',
          verifiedPurchase: true,
          createdAt: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString(),
          helpful: 8,
        },
        {
          _id: '3',
          bookId,
          userId: 'user3',
          userName: 'Michael Chen',
          rating: 5,
          text: 'One of the best books I have read this year. The writing is superb!',
          verifiedPurchase: false,
          createdAt: new Date(Date.now() - 21 * 24 * 60 * 60 * 1000).toISOString(),
          helpful: 5,
        },
      ];
      return { data: dummyReviews };
    }
    try {
      return await apiClient.get(`/reviews/book/${bookId}`);
    } catch (error) {
      console.warn('Reviews API failed, falling back to dummy data:', error);
      return { data: [] };
    }
  },

  getBookRatings: async (bookId: string) => {
    if (USE_DUMMY_DATA) {
      return {
        data: {
          bookId,
          averageRating: 4.5,
          totalRatings: 127,
          distribution: { 5: 80, 4: 30, 3: 12, 2: 3, 1: 2 },
        },
      };
    }
    try {
      return await apiClient.get(`/ratings/book/${bookId}`);
    } catch (error) {
      console.warn('Ratings API failed, falling back to dummy data:', error);
      return {
        data: {
          bookId,
          averageRating: 0,
          totalRatings: 0,
          distribution: {},
        },
      };
    }
  },

  createReview: async (bookId: string, userId: string, rating: number, text: string) => {
    if (USE_DUMMY_DATA) {
      return { data: { success: true, reviewId: 'dummy-review-123' } };
    }
    try {
      return await apiClient.post('/reviews', { bookId, userId, rating, text });
    } catch (error) {
      console.warn('Create review API failed:', error);
      return { data: { success: false } };
    }
  },
};

// Pricing & Promotions Service with dummy data fallback
export const pricingService = {
  getQuote: async (bookId: string, userId: string, qty: number, coupon?: string) => {
    if (USE_DUMMY_DATA) {
      const book = getDummyBookById(bookId);
      return {
        data: {
          price: book.price * qty,
          discount: coupon ? 5.00 : 0,
          total: book.price * qty - (coupon ? 5.00 : 0),
        },
      };
    }
    try {
      return await apiClient.post('/pricing/quote', { bookId, userId, qty, coupon });
    } catch (error) {
      console.warn('Pricing API failed, falling back to dummy data:', error);
      return {
        data: { price: 0, discount: 0, total: 0 },
      };
    }
  },

  validateCoupon: async (code: string, userId: string) => {
    if (USE_DUMMY_DATA) {
      // Simple dummy coupon validation
      const validCoupons = ['SAVE10', 'WELCOME', 'BOOKWORM'];
      const isValid = validCoupons.includes(code.toUpperCase());
      return {
        data: {
          valid: isValid,
          discountAmount: isValid ? 10.00 : 0,
          discountPercent: isValid ? 10 : 0,
        },
      };
    }
    try {
      return await apiClient.post('/coupons/validate', { code, userId });
    } catch (error) {
      console.warn('Coupon validation API failed:', error);
      return {
        data: { valid: false, discountAmount: 0, discountPercent: 0 },
      };
    }
  },
};

// Payment Service
export const paymentService = {
  createPaymentIntent: (orderId: string, amount: number, currency: string) =>
    apiClient.post('/payments/intent', { orderId, amount, currency }),
  confirmPayment: (intentId: string, method: string) =>
    apiClient.post('/payments/confirm', { intentId, method }),
  getPaymentStatus: (paymentId: string) =>
    apiClient.get(`/payments/${paymentId}`),
};

// Shipping Service with dummy data fallback
export const shippingService = {
  getShippingQuote: async (orderId: string, address: any) => {
    if (USE_DUMMY_DATA) {
      return {
        data: {
          standardShipping: 5.99,
          expressShipping: 15.99,
          estimatedDays: {
            standard: '5-7 business days',
            express: '2-3 business days',
          },
        },
      };
    }
    try {
      return await apiClient.post('/shipping/quote', { orderId, address });
    } catch (error) {
      console.warn('Shipping quote API failed, falling back to dummy data:', error);
      return {
        data: {
          standardShipping: 5.99,
          expressShipping: 15.99,
          estimatedDays: {
            standard: '5-7 business days',
            express: '2-3 business days',
          },
        },
      };
    }
  },

  createShipment: async (orderId: string, address: any) => {
    if (USE_DUMMY_DATA) {
      return {
        data: {
          trackingNumber: `TRK${Date.now()}`,
          carrier: 'USPS',
          estimatedDelivery: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        },
      };
    }
    try {
      return await apiClient.post('/shipping/ship', { orderId, address });
    } catch (error) {
      console.warn('Create shipment API failed:', error);
      return { data: null };
    }
  },

  getTracking: async (trackingNumber: string) => {
    if (USE_DUMMY_DATA) {
      return {
        data: {
          trackingNumber,
          status: 'In Transit',
          carrier: 'USPS',
          estimatedDelivery: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
          events: [
            {
              status: 'Package received by carrier',
              location: 'San Francisco, CA',
              timestamp: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
            },
            {
              status: 'In transit',
              location: 'Los Angeles, CA',
              timestamp: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
            },
            {
              status: 'Out for delivery',
              location: 'Huntington Beach, CA',
              timestamp: new Date().toISOString(),
            },
          ],
        },
      };
    }
    try {
      return await apiClient.get(`/shipping/track/${trackingNumber}`);
    } catch (error) {
      console.warn('Tracking API failed, falling back to dummy data:', error);
      return { data: null };
    }
  },
};

// Order Service with dummy data fallback
export const orderService = {
  createOrder: async (userId: string, items: Array<{ bookId: string; qty: number }>, address: string) => {
    if (USE_DUMMY_DATA) {
      return {
        data: {
          orderId: `ORD${Date.now()}`,
          status: 'pending',
          estimatedDelivery: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        },
      };
    }
    try {
      return await apiClient.post('/orders', { userId, items, address });
    } catch (error) {
      console.warn('Create order API failed:', error);
      return { data: { orderId: null } };
    }
  },

  getOrder: async (orderId: string) => {
    if (USE_DUMMY_DATA) {
      const dummyBooks = getDummyBooks(1, 3).data;
      return {
        data: {
          _id: orderId,
          userId: 'user-123',
          items: dummyBooks.map((book, idx) => ({
            bookId: book._id,
            title: book.title,
            quantity: idx + 1,
            price: book.price,
          })),
          totalAmount: dummyBooks.reduce((sum, book, idx) => sum + book.price * (idx + 1), 0),
          status: 'shipped' as const,
          paymentStatus: 'completed' as const,
          shippingAddress: {
            _id: '1',
            street: '123 Main St',
            city: 'Huntington Beach',
            state: 'CA',
            postalCode: '92648',
            country: 'United States',
            isDefault: true,
          },
          trackingNumber: `TRK${Date.now()}`,
          createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
          updatedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
        },
      };
    }
    try {
      return await apiClient.get(`/orders/${orderId}`);
    } catch (error) {
      console.warn('Get order API failed:', error);
      return { data: null };
    }
  },

  getUserOrders: async (userId: string) => {
    if (USE_DUMMY_DATA) {
      const dummyBooks = getDummyBooks(1, 5).data;
      const orders = [
        {
          _id: 'ORD001',
          userId,
          items: dummyBooks.slice(0, 2).map((book) => ({
            bookId: book._id,
            title: book.title,
            quantity: 1,
            price: book.price,
          })),
          totalAmount: dummyBooks.slice(0, 2).reduce((sum, book) => sum + book.price, 0) * 1.13,
          status: 'delivered' as const,
          paymentStatus: 'completed' as const,
          shippingAddress: {
            _id: '1',
            street: '123 Main St',
            city: 'Huntington Beach',
            state: 'CA',
            postalCode: '92648',
            country: 'United States',
            isDefault: true,
          },
          trackingNumber: 'TRK123456789',
          createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
          updatedAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
        },
        {
          _id: 'ORD002',
          userId,
          items: dummyBooks.slice(2, 4).map((book) => ({
            bookId: book._id,
            title: book.title,
            quantity: 2,
            price: book.price,
          })),
          totalAmount: dummyBooks.slice(2, 4).reduce((sum, book) => sum + book.price * 2, 0) * 1.13,
          status: 'shipped' as const,
          paymentStatus: 'completed' as const,
          shippingAddress: {
            _id: '1',
            street: '123 Main St',
            city: 'Huntington Beach',
            state: 'CA',
            postalCode: '92648',
            country: 'United States',
            isDefault: true,
          },
          trackingNumber: 'TRK987654321',
          createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
          updatedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
        },
        {
          _id: 'ORD003',
          userId,
          items: [dummyBooks[4]].map((book) => ({
            bookId: book._id,
            title: book.title,
            quantity: 1,
            price: book.price,
          })),
          totalAmount: dummyBooks[4].price * 1.13,
          status: 'pending' as const,
          paymentStatus: 'completed' as const,
          shippingAddress: {
            _id: '1',
            street: '123 Main St',
            city: 'Huntington Beach',
            state: 'CA',
            postalCode: '92648',
            country: 'United States',
            isDefault: true,
          },
          trackingNumber: undefined,
          createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
          updatedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
        },
      ];
      return { data: orders };
    }
    try {
      return await apiClient.get(`/orders/user/${userId}`);
    } catch (error) {
      console.warn('Get user orders API failed, falling back to dummy data:', error);
      return { data: [] };
    }
  },
};

// User Profile Service with dummy data fallback
export const userService = {
  getProfile: async (userId: string) => {
    if (USE_DUMMY_DATA) {
      return {
        data: {
          _id: userId,
          email: 'user@example.com',
          name: 'John Doe',
          avatar: undefined,
          addresses: [
            {
              _id: '1',
              street: '123 Main St',
              city: 'Huntington Beach',
              state: 'CA',
              postalCode: '92648',
              country: 'United States',
              isDefault: true,
            },
            {
              _id: '2',
              street: '456 Oak Avenue',
              city: 'Los Angeles',
              state: 'CA',
              postalCode: '90001',
              country: 'United States',
              isDefault: false,
            },
          ],
          wishlist: ['1', '2', '3'],
          preferences: {
            favoriteCategories: ['Fiction', 'Science Fiction', 'Mystery'],
            notifications: true,
            newsletter: true,
          },
          createdAt: new Date(Date.now() - 365 * 24 * 60 * 60 * 1000).toISOString(),
        },
      };
    }
    try {
      return await apiClient.get(`/users/${userId}/profile`);
    } catch (error) {
      console.warn('Get profile API failed, falling back to dummy data:', error);
      return {
        data: {
          _id: userId,
          email: 'user@example.com',
          name: 'Guest User',
          addresses: [],
          wishlist: [],
          preferences: {
            favoriteCategories: [],
            notifications: true,
            newsletter: true,
          },
          createdAt: new Date().toISOString(),
        },
      };
    }
  },

  updateProfile: async (userId: string, data: Record<string, any>) => {
    if (USE_DUMMY_DATA) {
      return { data: { success: true } };
    }
    try {
      return await apiClient.put(`/users/${userId}/profile`, data);
    } catch (error) {
      console.warn('Update profile API failed:', error);
      return { data: { success: false } };
    }
  },

  getWishlist: async (userId: string) => {
    if (USE_DUMMY_DATA) {
      const dummyBooks = getDummyBooks(1, 4).data;
      return { data: dummyBooks.map(book => book._id) };
    }
    try {
      return await apiClient.get(`/users/${userId}/wishlist`);
    } catch (error) {
      console.warn('Get wishlist API failed, falling back to dummy data:', error);
      return { data: [] };
    }
  },

  addToWishlist: async (userId: string, bookId: string) => {
    if (USE_DUMMY_DATA) {
      return { data: { success: true } };
    }
    try {
      return await apiClient.post(`/users/${userId}/wishlist`, { bookId });
    } catch (error) {
      console.warn('Add to wishlist API failed:', error);
      return { data: { success: false } };
    }
  },

  removeFromWishlist: async (userId: string, bookId: string) => {
    if (USE_DUMMY_DATA) {
      return { data: { success: true } };
    }
    try {
      return await apiClient.delete(`/users/${userId}/wishlist/${bookId}`);
    } catch (error) {
      console.warn('Remove from wishlist API failed:', error);
      return { data: { success: false } };
    }
  },
};

// Auth Service
export const authService = {
  login: (email: string, password: string) =>
    apiClient.post('/auth/login', { email, password }),
  register: (email: string, password: string, name: string) =>
    apiClient.post('/auth/register', { email, password, name }),
  logout: () => {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('authToken');
    }
  },
};

export default apiClient;
