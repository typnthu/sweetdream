# Manual CloudWatch Logs Export to S3

These scripts allow you to manually trigger the Lambda function to export CloudWatch logs to S3 **immediately**, instead of waiting for the scheduled daily export.

## What It Does

The Lambda function will:
1. Query CloudWatch Logs for user action logs
2. Export them to S3 in JSON format
3. Deduplicate any existing logs (safe to run multiple times)
4. Store in partitioned folders: `s3://bucket/user-actions/year=YYYY/month=MM/day=DD/`

## Usage

### PowerShell (Windows)

```powershell
# Export today's backend logs (for testing)
.\scripts\manual-export-logs.ps1 backend test

# Export yesterday's backend logs (normal mode)
.\scripts\manual-export-logs.ps1 backend production

# Export today's order service logs
.\scripts\manual-export-logs.ps1 order test

# Export yesterday's order service logs
.\scripts\manual-export-logs.ps1 order production
```

### Bash (Linux/Mac)

```bash
# Export today's backend logs (for testing)
./scripts/manual-export-logs.sh backend test

# Export yesterday's backend logs (normal mode)
./scripts/manual-export-logs.sh backend production

# Export today's order service logs
./scripts/manual-export-logs.sh order test

# Export yesterday's order service logs
./scripts/manual-export-logs.sh order production
```

## Lambda Functions

- **Backend**: `sweetdream-service-backend-export-logs`
  - Exports from: `/ecs/sweetdream-sweetdream-backend`
  - Exports to: `s3://sweetdream-analytics-backend-dev/user-actions/`

- **Order Service**: `sweetdream-service-order-service-export-logs`
  - Exports from: `/ecs/sweetdream-sweetdream-order-service`
  - Exports to: `s3://sweetdream-analytics-order-dev/user-actions/`

## Requirements

- AWS CLI installed and configured
- Permissions to invoke Lambda functions
- The Lambda functions must be deployed via Terraform first

## Output

The script will show:
- Number of logs found
- Number of logs exported
- S3 file path where logs were saved
- Any duplicates removed

## Notes

- **Safe to run multiple times** - The Lambda has built-in deduplication
- **Test mode** exports today's logs (useful for immediate testing)
- **Production mode** exports yesterday's logs (normal daily operation)
- Logs are stored in Vietnam timezone (UTC+7)
