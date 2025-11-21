# BookVerse - Dummy Data & Testing Guide

## 🎉 What's New

✅ **Project Renamed**: BookBorg → **BookVerse**  
✅ **Dummy Data Added**: 12 test books for immediate testing  
✅ **Logo Updated**: SVG logo integrated into Header  
✅ **Testing Page**: Ready-to-use version with dummy data  

---

## 📚 Dummy Data Included

The project now includes `src/lib/dummyData.ts` with 12 realistic books:

- **The Midnight Library** - Fiction
- **Atomic Habits** - Self-Help
- **Dune** - Science Fiction
- **The Power of Now** - Self-Help
- **Project Hail Mary** - Science Fiction
- **The Silent Patient** - Mystery
- **Educated** - Biography
- **The Great Gatsby** - Fiction
- **Sapiens** - Non-Fiction
- **The Hobbit** - Fantasy
- **Thinking, Fast and Slow** - Non-Fiction
- **1984** - Fiction

Each book has: title, author, description, price, category, cover image (from Unsplash), rating, reviews, stock status, ISBN, publisher, and tags.

---

## 🔄 How to Use Dummy Data

### Option 1: Use the Provided Test Page (Easiest)

```bash
# Rename the dummy data page to replace the current page
mv src/app/page.tsx src/app/page-api.tsx
mv src/app/page-with-dummy-data.tsx src/app/page.tsx

# Then run
npm run dev
```

This page automatically:
- ✅ Uses dummy data instead of API calls
- ✅ Simulates network delay (500ms)
- ✅ Shows a testing notice banner
- ✅ Displays all 12 books immediately

### Option 2: Manually Update Your Current page.tsx

Replace the `fetchBooks` function in your `src/app/page.tsx`:

```tsx
import { getDummyBooks } from '@/lib/dummyData';

const fetchBooks = async () => {
  try {
    setLoading(true);
    // Simulate network delay
    await new Promise((resolve) => setTimeout(resolve, 500));

    // Get dummy data instead of API
    const dummyData = getDummyBooks(1, 12);
    setBooks(dummyData.data);
    setError(null);
  } catch (err) {
    setError('Failed to load books');
    console.error(err);
  } finally {
    setLoading(false);
  }
};
```

---

## 🔌 Switching Back to API

When you're ready to connect to real data:

```tsx
import { bookService } from '@/lib/api';

const fetchBooks = async () => {
  try {
    setLoading(true);
    const response = await bookService.getBooks(1, 12);
    setBooks(response.data.data);
    setError(null);
  } catch (err) {
    setError('Failed to load books');
    console.error(err);
  } finally {
    setLoading(false);
  }
};
```

Then make sure your `.env.local` has:
```env
NEXT_PUBLIC_API_BASE_URL=http://localhost:8080/api
```

---

## 📖 Dummy Data Functions

All functions are in `src/lib/dummyData.ts`:

```typescript
// Get paginated books
getDummyBooks(page: number, limit: number)

// Search books
searchDummyBooks(query: string)

// Get books by category
getDummyBooksByCategory(category: string)

// Get single book
getDummyBookById(id: string)
```

Example usage:
```tsx
import { getDummyBooks, searchDummyBooks } from '@/lib/dummyData';

const books = getDummyBooks(1, 12);  // First page, 12 books
const results = searchDummyBooks('dune');  // Search for 'dune'
```

---

## 🎨 Logo Update

The logo has been:
- ✅ Added to `public/logo.svg`
- ✅ Integrated into Header component
- ✅ Styled to match the theme (uses `text-primary` color)

The book icon SVG is embedded directly in the Header for performance.

---

## 🏷️ Branding Changes

All references changed from **BookBorg** to **BookVerse**:

| File | Changes |
|------|---------|
| `src/app/page.tsx` | Hero title, About section, footer |
| `src/components/Header.tsx` | Logo text, favicon emoji |
| `src/lib/dummyData.ts` | All book data added |
| `package.json` | Name remains as `bookstore-frontend` (unchanged) |

---

## 📝 Next Steps

### For Local Testing:
```bash
cd bookstore-frontend
npm install
npm run dev
# Visit http://localhost:3000
```

Books will load immediately with dummy data.

### For API Integration:
1. Update `fetchBooks()` to use `bookService.getBooks()`
2. Ensure your API gateway is running on port 8080
3. Update `.env.local` with correct API URL
4. Test the connection in DevTools Network tab

### For Production:
1. Replace dummy data with real API calls
2. Update logo in header if needed
3. Customize book data fetching
4. Deploy to AWS (see DEPLOYMENT_GUIDE.md)

---

## 🧪 Testing Checklist

Using dummy data, verify:

- [ ] App loads at http://localhost:3000
- [ ] "Welcome to BookVerse" header displays
- [ ] 12 books load in grid
- [ ] Each book shows: image, title, author, rating, price
- [ ] "Add to Cart" buttons visible
- [ ] Wishlist hearts visible
- [ ] Search bar works (won't search yet, just logs)
- [ ] Footer displays correctly
- [ ] One book (1984) shows as "Out of Stock"
- [ ] No console errors
- [ ] Testing banner displays at top

---

## 🔍 Quick Reference

| Task | File | Function |
|------|------|----------|
| View dummy books | `src/lib/dummyData.ts` | `DUMMY_BOOKS` array |
| Add more dummy books | `src/lib/dummyData.ts` | Add to `DUMMY_BOOKS` array |
| Switch to API | `src/app/page.tsx` | Update `fetchBooks()` |
| Update logo | `src/components/Header.tsx` | Modify SVG or link |
| Change branding | Multiple | Search for "BookVerse" |

---

## 📚 Book Data Structure

Each dummy book has:
```typescript
{
  _id: string;           // Unique ID
  title: string;         // Book title
  author: string;        // Author name
  description: string;   // Full description
  price: number;         // Price in USD
  category: string;      // Genre/category
  coverImage: string;    // Image URL
  rating: number;        // Rating 0-5
  reviewCount: number;   // Number of reviews
  inStock: boolean;      // Stock status
  stockCount: number;    // Quantity available
  isbn: string;          // ISBN number
  publisher: string;     // Publisher name
  publishedDate: string; // Publication date
  tags: string[];        // Tag keywords
}
```

---

## ✅ You're Ready!

The app is fully functional with dummy data. No API connection needed to test locally.

```bash
npm run dev
# Enjoy BookVerse! 📚
```

---

**Questions?** Check the original README.md or SETUP_GUIDE.md for more details.
