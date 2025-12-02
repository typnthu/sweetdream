# Manual CloudWatch Logs Export to S3

These scripts allow you to manually trigger the Lambda function to export CloudWatch logs to S3 **immediately**, instead of waiting for the scheduled daily export.

## What It Does

The Lambda function will:
1. Query CloudWatch Logs for user action logs from 00:00 to current time (today)
2. Export them to S3 in JSON format
3. Overwrite the file for today's date (cumulative export)
4. Store in simple date folders: `s3://bucket/user-actions/MM/DD/user_actions.json`

Example: Running at 5 AM on Jan 1st exports 00:00-05:00 to `user-actions/1/1/user_actions.json`
Running again at 9 AM overwrites with 00:00-09:00 data in the same file.

## Usage

### PowerShell (Windows)

```powershell
# Export today's backend logs (from 00:00 to now)
.\scripts\manual-export-logs.ps1 backend

# Export today's order service logs (from 00:00 to now)
.\scripts\manual-export-logs.ps1 order
```

### Bash (Linux/Mac)

```bash
# Export today's backend logs (from 00:00 to now)
./scripts/manual-export-logs.sh backend

# Export today's order service logs (from 00:00 to now)
./scripts/manual-export-logs.sh order
```

## Lambda Functions

- **Backend**: `sweetdream-service-backend-export-logs`
  - Exports from: `/ecs/sweetdream-sweetdream-backend`
  - Exports to: `s3://sweetdream-analytics-backend-dev/user-actions/MM/DD/user_actions.json`

- **Order Service**: `sweetdream-service-order-service-export-logs`
  - Exports from: `/ecs/sweetdream-sweetdream-order-service`
  - Exports to: `s3://sweetdream-analytics-order-dev/user-actions/MM/DD/user_actions.json`

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

- **Safe to run multiple times** - Each run overwrites today's file with cumulative data
- **Always exports today's logs** from 00:00 to current time
- **Scheduled at 9 AM Vietnam time** to capture full day's data
- Logs are stored in Vietnam timezone (UTC+7)
- File structure: `user-actions/1/1/user_actions.json` for January 1st
