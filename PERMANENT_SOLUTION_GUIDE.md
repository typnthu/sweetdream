# Permanent Solution: Frontend Fetching from Backend API

## What Was Changed

I've refactored the frontend to fetch product data from the backend API instead of using hardcoded mock data.

### Files Modified:

1. **`fe/src/app/page.tsx`** - Home page now fetches products from API
2. **`fe/src/app/products/page.tsx`** - Products listing page now fetches from API
3. **`fe/src/app/product/[id]/page.tsx`** - Product detail page now fetches from API

### Key Changes:

- ✅ Added `useState` and `useEffect` hooks to fetch data
- ✅ Added loading states
- ✅ Added error handling
- ✅ Using `getProducts()` and `getProduct()` from `@/lib/api`
- ✅ Proper TypeScript types from API module

## Step-by-Step Deployment

### Step 1: Commit and Push Changes

```bash
git add fe/src/app/page.tsx fe/src/app/products/page.tsx fe/src/app/product/[id]/page.tsx
git add scripts/seed-database.ps1 PERMANENT_SOLUTION_GUIDE.md
git commit -m "feat: refactor frontend to fetch from backend API"
git push origin dev
```

### Step 2: Wait for Deployment

The GitHub Actions workflow will automatically:
- Build new Docker images
- Push to ECR
- Deploy to ECS

**Time:** ~5-10 minutes

Monitor at: https://github.com/typnthu/sweetdream/actions

### Step 3: Seed the Database

Once deployment completes, you need to add product data to the database.

#### Option A: Using GitHub Actions (Recommended)

1. Go to: https://github.com/typnthu/sweetdream/actions
2. Select "Database Migration" workflow
3. Click "Run workflow"
4. Select branch: `dev`
5. Select action: `seed`
6. Click "Run workflow"

#### Option B: Using PowerShell Script

```powershell
# Run the seed script
.\scripts\seed-database.ps1
```

**Note:** This requires ECS Exec to be enabled. If it fails, use Option A.

#### Option C: Manual via AWS CLI

```powershell
# Get backend task ARN
$TASK_ARN = aws ecs list-tasks `
    --cluster sweetdream-cluster `
    --service-name sweetdream-service-backend `
    --desired-status RUNNING `
    --query 'taskArns[0]' `
    --output text

# Run seed command
aws ecs execute-command `
    --cluster sweetdream-cluster `
    --task $TASK_ARN `
    --container sweetdream-backend `
    --interactive `
    --command "npm run seed"
```

### Step 4: Verify

1. **Check if backend has data:**
   ```bash
   # View backend logs
   aws logs tail /ecs/sweetdream --follow --filter-pattern "backend"
   ```

2. **Test the application:**
   - Visit: http://sweetdream-alb-405793892.us-east-1.elb.amazonaws.com
   - You should see products displayed
   - Click on a product to see details

## How It Works Now

### Data Flow:

```
Frontend (Next.js)
    ↓
API Call (fetch)
    ↓
Backend (Express.js)
    ↓
Database (PostgreSQL RDS)
    ↓
Return JSON
    ↓
Frontend Displays
```

### API Endpoints Used:

- `GET /api/products` - Get all products
- `GET /api/products/:id` - Get single product
- `GET /api/categories` - Get all categories

### Frontend API Client:

Located in `fe/src/lib/api.ts`:

```typescript
// Fetch all products
const products = await getProducts();

// Fetch single product
const product = await getProduct(id);

// Fetch categories
const categories = await getCategories();
```

## Troubleshooting

### Issue: "Không thể tải sản phẩm"

**Cause:** Backend is not responding or database is empty

**Solution:**
1. Check backend logs:
   ```bash
   aws logs tail /ecs/sweetdream --follow --filter-pattern "backend"
   ```

2. Verify backend is running:
   ```bash
   aws ecs describe-services --cluster sweetdream-cluster --services sweetdream-service-backend
   ```

3. Seed the database (see Step 3 above)

### Issue: Products show but no images

**Cause:** Product images are stored in S3 but URLs might be incorrect

**Solution:**
1. Check product data in database
2. Upload images to S3 bucket: `sweetdream-products`
3. Update product image URLs in database

### Issue: CORS errors in browser console

**Cause:** Backend CORS configuration

**Solution:**
Backend is configured to allow requests from the frontend. Check `be/src/server.ts`:

```typescript
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true
}));
```

Make sure `FRONTEND_URL` environment variable is set correctly in ECS task definition.

## Benefits of This Solution

### ✅ Advantages:

1. **Single Source of Truth** - Data comes from database
2. **Real-time Updates** - Changes in database reflect immediately
3. **Scalable** - Can handle thousands of products
4. **Maintainable** - No need to update frontend code when products change
5. **Proper Architecture** - Separation of concerns

### ❌ Previous Issues (Now Fixed):

1. ~~Hardcoded data in frontend~~
2. ~~Need to redeploy frontend to update products~~
3. ~~Data duplication between frontend and backend~~
4. ~~No way to manage products dynamically~~

## Next Steps (Optional Improvements)

### 1. Add Caching

Implement caching to reduce API calls:

```typescript
// In frontend
const [products, setProducts] = useState<Product[]>([]);
const [lastFetch, setLastFetch] = useState<number>(0);

useEffect(() => {
  const now = Date.now();
  if (now - lastFetch > 5 * 60 * 1000) { // 5 minutes
    fetchProducts();
    setLastFetch(now);
  }
}, []);
```

### 2. Add Pagination

For better performance with many products:

```typescript
// Backend: Add pagination to API
app.get('/api/products', async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const skip = (page - 1) * limit;
  
  const products = await prisma.product.findMany({
    skip,
    take: limit,
    include: { category: true, sizes: true }
  });
  
  res.json(products);
});
```

### 3. Add Search and Filters

```typescript
// Backend: Add search endpoint
app.get('/api/products/search', async (req, res) => {
  const { q, category } = req.query;
  
  const products = await prisma.product.findMany({
    where: {
      AND: [
        q ? { name: { contains: q, mode: 'insensitive' } } : {},
        category ? { categoryId: parseInt(category) } : {}
      ]
    },
    include: { category: true, sizes: true }
  });
  
  res.json(products);
});
```

### 4. Add Admin Panel

Create an admin interface to manage products without touching code:

- Add/Edit/Delete products
- Upload images
- Manage categories
- View orders

## Monitoring

### Check Application Health:

```bash
# Frontend health
curl http://sweetdream-alb-405793892.us-east-1.elb.amazonaws.com/api/health

# Backend health (internal)
# Access via frontend proxy or ECS exec
```

### View Logs:

```bash
# All logs
aws logs tail /ecs/sweetdream --follow

# Backend only
aws logs tail /ecs/sweetdream --follow --filter-pattern "backend"

# Frontend only
aws logs tail /ecs/sweetdream --follow --filter-pattern "frontend"
```

### Check Database:

```bash
# Get database endpoint
cd terraform
terraform output db_endpoint

# Connect to database (from within VPC or via bastion)
psql -h <db-endpoint> -U dbadmin -d sweetdream
```

## Summary

Your application now follows proper architecture:

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ HTTP
       ↓
┌─────────────┐
│     ALB     │
└──────┬──────┘
       │
       ↓
┌─────────────┐      ┌─────────────┐
│  Frontend   │─────→│   Backend   │
│  (Next.js)  │ API  │  (Express)  │
└─────────────┘      └──────┬──────┘
                            │
                            ↓
                     ┌─────────────┐
                     │  PostgreSQL │
                     │     RDS     │
                     └─────────────┘
```

**Status:** ✅ Production-ready architecture implemented!

---

**Need help?** Check the troubleshooting section or review the logs.
