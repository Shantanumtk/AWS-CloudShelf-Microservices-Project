'use client';

import { useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { Header } from '@/components/Header';
import { BookCard } from '@/components/BookCard';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Book, SearchFilters } from '@/types';
import { searchService } from '@/lib/api';
import { Loader, SlidersHorizontal, X } from 'lucide-react';

export default function SearchPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const query = searchParams.get('q') || '';
  const categoryParam = searchParams.get('category');

  const [books, setBooks] = useState<Book[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [total, setTotal] = useState(0);
  const [showFilters, setShowFilters] = useState(false);

  // Filter states
  const [filters, setFilters] = useState<SearchFilters>({
    category: categoryParam || undefined,
    priceRange: undefined,
    rating: undefined,
    inStockOnly: false,
    sortBy: 'relevance',
  });

  const [priceMin, setPriceMin] = useState('');
  const [priceMax, setPriceMax] = useState('');

  const categories = [
    'Fiction',
    'Non-Fiction',
    'Science Fiction',
    'Mystery',
    'Romance',
    'Biography',
    'History',
    'Science',
    'Technology',
    'Self-Help',
  ];

  useEffect(() => {
    if (query) {
      performSearch();
    }
  }, [query, filters]);

  const performSearch = async () => {
    try {
      setLoading(true);
      setError(null);

      const response = await searchService.search(query, filters);
      setBooks(response.data.data);
      setTotal(response.data.total);
    } catch (err) {
      setError('Failed to search books');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleCategoryFilter = (category: string) => {
    setFilters((prev) => ({
      ...prev,
      category: prev.category === category ? undefined : category,
    }));
  };

  const handleRatingFilter = (rating: number) => {
    setFilters((prev) => ({
      ...prev,
      rating: prev.rating === rating ? undefined : rating,
    }));
  };

  const handlePriceFilter = () => {
    const min = parseFloat(priceMin);
    const max = parseFloat(priceMax);

    if (!isNaN(min) && !isNaN(max) && min <= max) {
      setFilters((prev) => ({
        ...prev,
        priceRange: [min, max],
      }));
    }
  };

  const clearPriceFilter = () => {
    setPriceMin('');
    setPriceMax('');
    setFilters((prev) => ({
      ...prev,
      priceRange: undefined,
    }));
  };

  const clearAllFilters = () => {
    setFilters({
      category: undefined,
      priceRange: undefined,
      rating: undefined,
      inStockOnly: false,
      sortBy: 'relevance',
    });
    setPriceMin('');
    setPriceMax('');
  };

  const activeFiltersCount = [
    filters.category,
    filters.priceRange,
    filters.rating,
    filters.inStockOnly,
  ].filter(Boolean).length;

  return (
    <div className="min-h-screen bg-background">
      <Header
        cartCount={0}
        wishlistCount={0}
        onSearch={(q) => router.push(`/search?q=${q}`)}
        isAuthenticated={false}
      />

      <main className="container mx-auto px-4 py-8">
        {/* Search Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2">
            Search Results {query && `for "${query}"`}
          </h1>
          <p className="text-muted-foreground">
            {loading ? 'Searching...' : `${total} books found`}
          </p>
        </div>

        <div className="flex gap-8">
          {/* Filters Sidebar */}
          <aside
            className={`${
              showFilters ? 'block' : 'hidden'
            } lg:block w-full lg:w-64 flex-shrink-0`}
          >
            <Card className="sticky top-4">
              <CardContent className="p-6">
                <div className="flex items-center justify-between mb-6">
                  <h2 className="text-lg font-semibold">Filters</h2>
                  {activeFiltersCount > 0 && (
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={clearAllFilters}
                    >
                      Clear All
                    </Button>
                  )}
                </div>

                {/* Sort By */}
                <div className="mb-6">
                  <h3 className="font-semibold mb-3">Sort By</h3>
                  <select
                    className="w-full border rounded-lg px-3 py-2"
                    value={filters.sortBy}
                    onChange={(e) =>
                      setFilters((prev) => ({
                        ...prev,
                        sortBy: e.target.value as any,
                      }))
                    }
                  >
                    <option value="relevance">Relevance</option>
                    <option value="price">Price: Low to High</option>
                    <option value="rating">Rating: High to Low</option>
                    <option value="newest">Newest First</option>
                  </select>
                </div>

                {/* Category Filter */}
                <div className="mb-6">
                  <h3 className="font-semibold mb-3">Category</h3>
                  <div className="space-y-2">
                    {categories.map((category) => (
                      <button
                        key={category}
                        onClick={() => handleCategoryFilter(category)}
                        className={`block w-full text-left px-3 py-2 rounded-lg transition-colors ${
                          filters.category === category
                            ? 'bg-primary text-primary-foreground'
                            : 'hover:bg-muted'
                        }`}
                      >
                        {category}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Price Range Filter */}
                <div className="mb-6">
                  <h3 className="font-semibold mb-3">Price Range</h3>
                  <div className="space-y-2">
                    <Input
                      type="number"
                      placeholder="Min"
                      value={priceMin}
                      onChange={(e) => setPriceMin(e.target.value)}
                      min="0"
                      step="0.01"
                    />
                    <Input
                      type="number"
                      placeholder="Max"
                      value={priceMax}
                      onChange={(e) => setPriceMax(e.target.value)}
                      min="0"
                      step="0.01"
                    />
                    <div className="flex gap-2">
                      <Button
                        variant="secondary"
                        size="sm"
                        onClick={handlePriceFilter}
                        className="flex-1"
                      >
                        Apply
                      </Button>
                      {filters.priceRange && (
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={clearPriceFilter}
                        >
                          <X className="w-4 h-4" />
                        </Button>
                      )}
                    </div>
                  </div>
                </div>

                {/* Rating Filter */}
                <div className="mb-6">
                  <h3 className="font-semibold mb-3">Minimum Rating</h3>
                  <div className="space-y-2">
                    {[5, 4, 3, 2, 1].map((rating) => (
                      <button
                        key={rating}
                        onClick={() => handleRatingFilter(rating)}
                        className={`block w-full text-left px-3 py-2 rounded-lg transition-colors ${
                          filters.rating === rating
                            ? 'bg-primary text-primary-foreground'
                            : 'hover:bg-muted'
                        }`}
                      >
                        {'★'.repeat(rating)}{'☆'.repeat(5 - rating)} & up
                      </button>
                    ))}
                  </div>
                </div>

                {/* In Stock Only */}
                <div>
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={filters.inStockOnly}
                      onChange={(e) =>
                        setFilters((prev) => ({
                          ...prev,
                          inStockOnly: e.target.checked,
                        }))
                      }
                      className="w-4 h-4"
                    />
                    <span className="font-semibold">In Stock Only</span>
                  </label>
                </div>
              </CardContent>
            </Card>
          </aside>

          {/* Results */}
          <div className="flex-1">
            {/* Mobile Filter Toggle */}
            <div className="lg:hidden mb-4">
              <Button
                variant="outline"
                onClick={() => setShowFilters(!showFilters)}
                className="w-full"
              >
                <SlidersHorizontal className="mr-2" size={20} />
                Filters
                {activeFiltersCount > 0 && (
                  <Badge className="ml-2">{activeFiltersCount}</Badge>
                )}
              </Button>
            </div>

            {/* Active Filters */}
            {activeFiltersCount > 0 && (
              <div className="flex flex-wrap gap-2 mb-6">
                {filters.category && (
                  <Badge variant="secondary" className="flex items-center gap-1">
                    {filters.category}
                    <button
                      onClick={() => handleCategoryFilter(filters.category!)}
                      className="ml-1"
                    >
                      <X className="w-3 h-3" />
                    </button>
                  </Badge>
                )}
                {filters.priceRange && (
                  <Badge variant="secondary" className="flex items-center gap-1">
                    ${filters.priceRange[0]} - ${filters.priceRange[1]}
                    <button onClick={clearPriceFilter} className="ml-1">
                      <X className="w-3 h-3" />
                    </button>
                  </Badge>
                )}
                {filters.rating && (
                  <Badge variant="secondary" className="flex items-center gap-1">
                    {filters.rating}+ Stars
                    <button
                      onClick={() => handleRatingFilter(filters.rating!)}
                      className="ml-1"
                    >
                      <X className="w-3 h-3" />
                    </button>
                  </Badge>
                )}
                {filters.inStockOnly && (
                  <Badge variant="secondary" className="flex items-center gap-1">
                    In Stock
                    <button
                      onClick={() =>
                        setFilters((prev) => ({ ...prev, inStockOnly: false }))
                      }
                      className="ml-1"
                    >
                      <X className="w-3 h-3" />
                    </button>
                  </Badge>
                )}
              </div>
            )}

            {/* Loading State */}
            {loading ? (
              <div className="flex justify-center items-center h-64">
                <Loader className="animate-spin" size={32} />
              </div>
            ) : error ? (
              <Card>
                <CardContent className="p-12 text-center">
                  <p className="text-destructive mb-4">{error}</p>
                  <Button onClick={performSearch}>Try Again</Button>
                </CardContent>
              </Card>
            ) : books.length === 0 ? (
              <Card>
                <CardContent className="p-12 text-center">
                  <p className="text-muted-foreground mb-4">
                    No books found matching your criteria
                  </p>
                  <Button onClick={clearAllFilters}>Clear Filters</Button>
                </CardContent>
              </Card>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-6">
                {books.map((book) => (
                  <BookCard
                    key={book._id}
                    book={book}
                    onAddToCart={() => console.log('Add to cart:', book.title)}
                    onAddToWishlist={() =>
                      console.log('Add to wishlist:', book.title)
                    }
                  />
                ))}
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
