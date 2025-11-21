# BookVerse Development Roadmap - Next Pages to Build

## Priority 1: Product Detail Page (Highest Impact)

### File: `src/app/book/[id]/page.tsx`

This page displays full information about a single book and is crucial for conversions.

```typescript
// Key responsibilities:
// 1. Fetch book by ID from API or dummy data
// 2. Display high-quality book cover with fade effect
// 3. Show complete book information
// 4. Render add-to-cart button
// 5. Display reviews section (when reviews API ready)
// 6. Show related/recommended books
// 7. Handle loading and error states

// Component structure:
<ProductDetail>
  <BreadcrumbNav />
  <ProductGrid>
    <BookCoverImage />
    <ProductInfo>
      <Title />
      <Rating />
      <Price />
      <InStockBadge />
      <Description />
      <MetaTags /> {/* ISBN, Publisher, Published Date */}
      <AddToCartForm />
      <ShareButtons />
    </ProductInfo>
  </ProductGrid>
  <ReviewsSection />
  <RelatedBooks />
</ProductDetail>
```

### Data Flow:
```
GET /api/books/{id}
→ Book object with full details
→ Display in ProductDetail component
→ Fetch related books from /api/books/related?id={id}
```

### Styling Considerations:
- Product image: 400x600px minimum for quality
- Use Playfair Display for title
- Card component for metadata sections
- Gold accent for buttons
- Star rating component with color

---

## Priority 2: Cart & Checkout Flow

### Files:
- `src/app/cart/page.tsx` - Cart display and management
- `src/app/checkout/page.tsx` - Checkout process
- `src/components/CartSummary.tsx` - Reusable cart summary
- `src/lib/cart.ts` - Cart state management

### Cart Page Features:
1. **Cart Items List**
   - Book cover thumbnail (100x150px)
   - Title and author
   - Unit price
   - Quantity adjuster (- / + buttons)
   - Line total
   - Remove button

2. **Order Summary**
   - Subtotal
   - Tax (if applicable)
   - Shipping estimate
   - Total price
   - Proceed to checkout button

3. **Empty State**
   - Illustration
   - "Your cart is empty" message
   - Link back to shop

### Checkout Page Features:
1. **Shipping Address Form**
2. **Billing Address (same as shipping toggle)**
3. **Shipping Method Selection**
4. **Payment Information** (integrates with Payment Service)
5. **Order Review** (summary before final submission)
6. **Confirmation Screen** (after payment success)

### Data Flow:
```
User adds book → Add to cart (localStorage or Cart API)
→ Navigate to /cart
→ Display cart items
→ User clicks checkout
→ Navigate to /checkout
→ Fill in shipping/payment
→ POST /api/orders (creates order)
→ Show confirmation
```

---

## Priority 3: Search Results Page

### File: `src/app/search/page.tsx`

### Features:
1. **Search Bar with Suggestions**
   - Real-time query input
   - Suggested searches based on categories
   - Clear button

2. **Results Display**
   - Grid of matching books
   - Result count
   - "No results" state with suggestions

3. **Sidebar Filters**
   - **Category** (checkboxes): Fiction, Science Fiction, Mystery, etc.
   - **Price Range** (slider): $0 - $30
   - **Rating** (star filter): 4+, 3.5+, 3+
   - **Availability** (toggle): In stock only
   - **Author** (search/autocomplete): For specific authors

4. **Sorting**
   - Relevance (default)
   - Newest
   - Best selling
   - Lowest price
   - Highest price
   - Highest rated

5. **Pagination**
   - Results: 12 per page
   - Page navigation
   - "Show more" button option

### API Integration:
```
GET /api/search?q={query}&category={cat}&minPrice={min}&maxPrice={max}&rating={rating}&sort={sort}&page={page}
→ Returns { results: [], total: number, hasMore: boolean }
```

### Query URL Structure:
```
/search?q=science&category=fiction&minPrice=5&maxPrice=25&rating=4&sort=relevance&page=1
```

---

## Priority 4: Category Pages

### File: `src/app/category/[category]/page.tsx`

### Features:
1. **Category Header**
   - Category name (Playfair Display)
   - Category description
   - Book count in category
   - Featured section

2. **Featured Books** (top 4 books in category)
   - Larger cards
   - Premium display
   - "Featured" badge

3. **All Books in Category**
   - Same grid as homepage
   - Filters and sorting
   - Pagination

4. **Category Sidebar Navigation**
   - Browse other categories
   - Best sellers in each category
   - Recently added

### Dynamic Routes:
```
/category/fiction
/category/science-fiction
/category/mystery
/category/biography
/category/self-help
/category/non-fiction
/category/fantasy
```

---

## Priority 5: User Account Pages

### Files:
- `src/app/login/page.tsx`
- `src/app/register/page.tsx`
- `src/app/profile/page.tsx`
- `src/app/orders/page.tsx`
- `src/app/wishlist/page.tsx`

### Login Page
- Email input
- Password input
- "Remember me" checkbox
- "Forgot password" link
- Social login options (optional)
- Link to register

### Register Page
- Full name input
- Email input
- Password input
- Confirm password
- Terms & conditions checkbox
- Submit button
- Link to login

### Profile Page
- User avatar
- Name, email, phone
- Billing and shipping addresses
- Edit profile button
- Change password section
- Account preferences
- Logout button

### Orders Page
- Order history table
  - Order ID
  - Order date
  - Items count
  - Total price
  - Status (Pending, Shipped, Delivered)
  - View details button
- Order detail modal/page
  - Items in order
  - Shipping status
  - Tracking number (if shipped)
  - Estimated delivery
  - Return options

### Wishlist Page
- Grid of wishlist items
- Add to cart from wishlist
- Remove from wishlist
- Share wishlist feature
- Price alert feature (email when on sale)

---

## Components to Create

### New Components Needed:
1. **BookGrid.tsx** - Reusable grid for displaying books
2. **ProductDetail.tsx** - Detailed product view
3. **FilterSidebar.tsx** - Search/category filters
4. **SortDropdown.tsx** - Sort options
5. **ReviewCard.tsx** - Individual review display
6. **ReviewForm.tsx** - Submit a review
7. **CartItem.tsx** - Individual cart item
8. **AddressForm.tsx** - Address input form
9. **PaymentForm.tsx** - Payment method input
10. **Breadcrumb.tsx** - Navigation breadcrumbs
11. **PriceRange.tsx** - Price slider filter
12. **StarRating.tsx** - Star rating component (interactive & display)
13. **Pagination.tsx** - Page navigation
14. **SearchBar.tsx** - Enhanced search with suggestions
15. **EmptyState.tsx** - Generic empty state display

---

## API Endpoints to Mock/Implement

```typescript
// Book Service
GET /api/books/{id}
GET /api/books?page=1&limit=12
POST /api/books/search?q={query}
GET /api/books/category/{category}
GET /api/books/related?id={id}

// Cart Service
GET /api/cart
POST /api/cart/items
PUT /api/cart/items/{itemId}
DELETE /api/cart/items/{itemId}
POST /api/cart/checkout

// Orders Service
POST /api/orders
GET /api/orders (user's orders)
GET /api/orders/{orderId}
GET /api/orders/{orderId}/tracking

// Reviews Service
GET /api/reviews?bookId={id}&page=1
POST /api/reviews
GET /api/reviews/{reviewId}
PUT /api/reviews/{reviewId}
DELETE /api/reviews/{reviewId}

// User Service
POST /api/auth/login
POST /api/auth/register
GET /api/auth/me
PUT /api/auth/profile
POST /api/auth/logout

// Wishlist Service
GET /api/wishlist
POST /api/wishlist/{bookId}
DELETE /api/wishlist/{bookId}

// Recommendations Service
GET /api/recommendations?userId={id}
GET /api/recommendations/trending

// Pricing Service
GET /api/prices/{bookId}
POST /api/prices/query (batch pricing)
```

---

## Styling Guidelines for New Pages

### Typography Usage
- **Page Titles**: Playfair Display 900, 48px
- **Section Headers**: Playfair Display 700, 36px
- **Subsections**: Playfair Display 700, 24px
- **Body Text**: Lora 400, 16px
- **UI Labels**: Lora 600, 14px

### Color Usage
- **Primary Actions**: Primary color (#D4A574) on cream
- **Danger Actions**: Destructive color (red)
- **Secondary Info**: Muted foreground (#7A6E66)
- **Borders**: Border color (#E8DCC8)

### Spacing Standards
- Page padding: 24px (mobile) → 32px (tablet) → 48px (desktop)
- Section gap: 32px
- Component gap: 16px
- Inline spacing: 8px

### Cards
- Background: Card color (white)
- Border: Subtle 1px border in border color
- Shadow: Soft shadow for depth
- Padding: 20px
- Radius: var(--radius) (6px)

---

## Testing Checklist for Each Page

- [ ] Loads without API (fallback to dummy data)
- [ ] Loads with API (when available)
- [ ] Responsive on mobile (375px)
- [ ] Responsive on tablet (768px)
- [ ] Responsive on desktop (1440px)
- [ ] Accessible (keyboard navigation, ARIA labels)
- [ ] Dark mode support
- [ ] Loading states display correctly
- [ ] Error states handled gracefully
- [ ] No console errors or warnings

---

## File Structure for New Pages

```
src/
├── app/
│   ├── book/
│   │   └── [id]/
│   │       └── page.tsx
│   ├── search/
│   │   └── page.tsx
│   ├── category/
│   │   └── [category]/
│   │       └── page.tsx
│   ├── cart/
│   │   └── page.tsx
│   ├── checkout/
│   │   └── page.tsx
│   ├── login/
│   │   └── page.tsx
│   ├── register/
│   │   └── page.tsx
│   └── profile/
│       ├── page.tsx
│       ├── orders/
│       │   └── page.tsx
│       └── wishlist/
│           └── page.tsx
├── components/
│   ├── BookGrid.tsx
│   ├── ProductDetail.tsx
│   ├── FilterSidebar.tsx
│   ├── CartItem.tsx
│   ├── ReviewCard.tsx
│   └── ...
└── lib/
    ├── cart.ts (client state management)
    └── hooks.ts (custom React hooks)
```

---

## Recommended Build Order

1. **Week 1**: Book Product Detail Page
   - Set up dynamic routing
   - Fetch and display book
   - Add to cart integration
   
2. **Week 2**: Cart & Basic Checkout
   - Build cart display
   - Cart item management
   - Basic checkout form
   
3. **Week 3**: Search Page
   - Search functionality
   - Filters and sorting
   - Pagination
   
4. **Week 4**: Category Pages
   - Category templates
   - Featured sections
   - Category navigation
   
5. **Week 5**: User Account Pages
   - Authentication integration
   - Profile management
   - Order history

---

**Note**: Each page should include error handling, loading states, and fallback to dummy data when real APIs are unavailable.
