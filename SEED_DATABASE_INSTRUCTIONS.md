# How to Seed the Database

Since the PowerShell scripts are having issues, here's the simplest way to seed your database:

## Option 1: Manual AWS CLI Commands (Recommended)

Run these commands one by one:

```bash
# Step 1: Run the seed task
aws ecs run-task \
  --cluster sweetdream-cluster \
  --task-definition sweetdream-task-backend \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-0ce405ecbec7fad55,subnet-0d9e0a6a06fc0ff92],securityGroups=[sg-0825ffdfb0ccf0058],assignPublicIp=DISABLED}" \
  --overrides '{"containerOverrides":[{"name":"sweetdream-backend","command":["npm","run","seed:prod"]}]}'
```

This will start a one-time task that runs the seed command. Wait 2-3 minutes for it to complete.

```bash
# Step 2: Check the logs to verify it worked
aws logs tail /ecs/sweetdream --since 5m --filter-pattern "seed"
```

Look for messages like:
- "✅ Created: [product name]"
- "✅ Success: X products"
- "✅ Database seeded successfully!"

## Option 2: Use GitHub Actions (Easiest)

1. **First, commit and push your frontend changes:**
   ```bash
   git add .
   git commit -m "feat: refactor frontend to fetch from backend API"
   git push origin dev
   ```

2. **Wait for deployment to complete** (~5-10 minutes)
   - Monitor at: https://github.com/typnthu/sweetdream/actions

3. **Run the seed workflow:**
   - Go to: https://github.com/typnthu/sweetdream/actions
   - Click on "Database Migration" workflow
   - Click "Run workflow" button
   - Select:
     - Branch: `dev`
     - Environment: `development`
     - Migration type: `seed`
   - Click "Run workflow"

4. **Wait for completion** (~2-3 minutes)

## Option 3: Connect to Database Directly

If you have database access, you can run the seed script locally:

```bash
# Set database connection
$env:DATABASE_URL="postgresql://dbadmin:admin123!@<your-db-endpoint>:5432/sweetdream"

# Run seed
cd be
npm run seed
```

**Note:** You'll need to get the database endpoint from Terraform:
```bash
cd terraform
terraform output db_endpoint
```

## Verification

After seeding, verify it worked:

### 1. Check the application:
Visit: http://sweetdream-alb-405793892.us-east-1.elb.amazonaws.com

You should see products displayed!

### 2. Check logs:
```bash
aws logs tail /ecs/sweetdream --since 10m --filter-pattern "backend"
```

### 3. Check database (if you have access):
```sql
SELECT COUNT(*) FROM "Product";
SELECT COUNT(*) FROM "Category";
```

Should show:
- Products: 16
- Categories: 4

## Troubleshooting

### Issue: Task fails to start

**Solution:** Check if the task definition exists:
```bash
aws ecs describe-task-definition --task-definition sweetdream-task-backend
```

### Issue: Seed command fails

**Possible causes:**
1. Database connection issue
2. Product JSON files missing
3. Prisma client not generated

**Check logs:**
```bash
aws logs tail /ecs/sweetdream --follow --filter-pattern "ERROR"
```

### Issue: Products still not showing

**Possible causes:**
1. Database not seeded yet
2. Backend not connecting to database
3. Frontend not fetching from backend

**Debug steps:**
1. Check backend logs for database connection
2. Test backend API directly (if possible)
3. Check browser console for API errors

## Alternative: Use Sample Data

If seeding continues to fail, you can keep using the sample data I added to `fe/src/products/index.ts`. 

The application will work with this data, but:
- Products won't persist
- Can't add/edit products dynamically
- Images won't load (using placeholder)

## Next Steps After Seeding

Once database is seeded:

1. **Test the application** - Browse products, view details
2. **Check images** - Upload product images to S3 if needed
3. **Test orders** - Try placing an order
4. **Monitor** - Watch logs for any errors

---

**Recommended:** Use Option 2 (GitHub Actions) as it's the most reliable method.
