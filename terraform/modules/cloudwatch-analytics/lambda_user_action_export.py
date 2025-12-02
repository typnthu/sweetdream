#!/usr/bin/env python3
"""
User Action Log Export Lambda
Filters and exports only user_action logs to S3 in JSON/CSV format
WITH DUPLICATE PREVENTION
"""

import boto3
import json
import os
import csv
import io
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Any
import time

# AWS clients
logs_client = boto3.client('logs')
s3_client = boto3.client('s3')

def handler(event, context):
    """
    Export user_action logs from CloudWatch to S3 in JSON/CSV format
    Exports from 00:00 to current time for today's date
    """
    log_group_name = os.environ['LOG_GROUP_NAME']
    s3_bucket = os.environ['S3_BUCKET']
    s3_prefix = os.environ.get('S3_PREFIX', 'user-actions')
    export_format = os.environ.get('EXPORT_FORMAT', 'json')  # json or csv
    
    # Vietnam timezone (UTC+7)
    vietnam_tz = timezone(timedelta(hours=7))
    
    # Calculate date range in Vietnam time
    now_vietnam = datetime.now(vietnam_tz)
    
    # Always export today's logs from 00:00 to current time
    target_date = now_vietnam
    start_date = target_date.replace(hour=0, minute=0, second=0, microsecond=0)
    end_date = now_vietnam  # Current time
    
    print(f"Processing logs from {log_group_name}")
    print(f"Time range: {start_date} to {end_date} (Vietnam time)")
    print(f"Export format: {export_format}")
    
    try:
        # Query CloudWatch Logs for user_action logs
        user_actions = query_user_action_logs(
            log_group_name, 
            start_date, 
            end_date
        )
        
        if not user_actions:
            message = f"No user_action logs found for {start_date.strftime('%Y-%m-%d')}"
            print(message)
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': message,
                    'date': start_date.strftime('%Y-%m-%d'),
                    'total_logs': 0
                })
            }
        
        print(f"Found {len(user_actions)} user_action logs")
        
        # Group logs by date (based on log timestamp)
        logs_by_date = group_logs_by_date(user_actions, vietnam_tz)
        
        # Export to S3
        exported_files = []
        for date_str, logs in logs_by_date.items():
            file_key = export_logs_to_s3(
                logs, 
                s3_bucket, 
                s3_prefix, 
                date_str, 
                export_format
            )
            exported_files.append(file_key)
            print(f"Exported {len(logs)} logs to {file_key}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Export completed successfully',
                'files_exported': exported_files,
                'total_logs': len(user_actions)
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': f'Error: {str(e)}'
        }

def query_user_action_logs(log_group_name: str, start_date: datetime, end_date: datetime) -> List[Dict[str, Any]]:
    """
    Query CloudWatch Logs for user_action logs using CloudWatch Insights
    """
    query = '''
    fields @timestamp, @message
    | filter @message like /\"category\":\\s*\"user_action\"/
    | sort @timestamp asc
    '''
    
    start_time = int(start_date.timestamp())
    end_time = int(end_date.timestamp())
    
    print(f"Starting CloudWatch Insights query...")
    
    # Start query
    response = logs_client.start_query(
        logGroupName=log_group_name,
        startTime=start_time,
        endTime=end_time,
        queryString=query
    )
    
    query_id = response['queryId']
    print(f"Query ID: {query_id}")
    
    # Wait for query to complete
    max_wait = 120  # seconds
    waited = 0
    
    while waited < max_wait:
        result = logs_client.get_query_results(queryId=query_id)
        status = result['status']
        
        if status == 'Complete':
            break
        elif status == 'Failed':
            raise Exception(f"Query failed: {result.get('statistics', {})}")
        
        time.sleep(2)
        waited += 2
    
    if status != 'Complete':
        raise Exception(f"Query timeout after {max_wait} seconds")
    
    # Process results
    user_actions = []
    for result_row in result['results']:
        timestamp_field = next((field for field in result_row if field['field'] == '@timestamp'), None)
        message_field = next((field for field in result_row if field['field'] == '@message'), None)
        
        if timestamp_field and message_field:
            try:
                # Parse the JSON log message
                log_data = json.loads(message_field['value'])
                
                # Verify it's a user_action log
                if log_data.get('category') == 'user_action':
                    log_data['@timestamp'] = timestamp_field['value']
                    user_actions.append(log_data)
                    
            except json.JSONDecodeError:
                # Skip invalid JSON
                continue
    
    return user_actions

def group_logs_by_date(logs: List[Dict[str, Any]], vietnam_tz: timezone) -> Dict[str, List[Dict[str, Any]]]:
    """
    Group logs by date based on their timestamp (converted to Vietnam time)
    """
    logs_by_date = {}
    
    for log in logs:
        # Parse timestamp
        timestamp_str = log.get('@timestamp', log.get('timestamp', ''))
        
        try:
            # Parse ISO timestamp
            if timestamp_str.endswith('Z'):
                timestamp = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
            else:
                timestamp = datetime.fromisoformat(timestamp_str)
            
            # Convert to Vietnam time
            vietnam_time = timestamp.astimezone(vietnam_tz)
            date_str = vietnam_time.strftime('%Y-%m-%d')
            
            if date_str not in logs_by_date:
                logs_by_date[date_str] = []
            
            logs_by_date[date_str].append(log)
            
        except (ValueError, TypeError) as e:
            print(f"Error parsing timestamp '{timestamp_str}': {e}")
            # Use 'unknown' date for unparseable timestamps
            if 'unknown' not in logs_by_date:
                logs_by_date['unknown'] = []
            logs_by_date['unknown'].append(log)
    
    return logs_by_date

def export_logs_to_s3(logs: List[Dict[str, Any]], bucket: str, prefix: str, date_str: str, format_type: str) -> str:
    """
    Export logs to S3 in specified format
    Overwrites existing file for the same day with cumulative data
    
    Strategy:
    - Export all logs from 00:00 to current time for today
    - Overwrite the file each time (no merging needed)
    - File path: s3://bucket/user-actions/2025/1/1/user_actions.json (for Jan 1st, 2025)
    """
    # Create S3 key with date structure: year/month/day/
    year, month, day = date_str.split('-')
    
    if format_type.lower() == 'csv':
        file_key = f"{prefix}/{year}/{month}/{day}/user_actions.csv"
        content_type = 'text/csv'
    else:
        file_key = f"{prefix}/{year}/{month}/{day}/user_actions.json"
        content_type = 'application/json'
    
    print(f"Exporting {len(logs)} logs to {file_key} (will overwrite if exists)")
    
    # Convert to format (no deduplication needed since we're overwriting)
    if format_type.lower() == 'csv':
        content = convert_to_csv(logs)
    else:
        content = convert_to_json(logs)
    
    # Upload to S3 (overwrites existing file)
    s3_client.put_object(
        Bucket=bucket,
        Key=file_key,
        Body=content,
        ContentType=content_type,
        ServerSideEncryption='AES256'
    )
    
    # Store export metadata for tracking
    store_export_metadata(bucket, prefix, date_str, len(logs))
    
    return file_key

def store_export_metadata(bucket: str, prefix: str, date_str: str, total_logs: int):
    """
    Store metadata about this export run for tracking
    """
    year, month, day = date_str.split('-')
    metadata_key = f"{prefix}/_metadata/{year}/{month}/{day}/export_runs.jsonl"
    
    export_run = {
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'date': date_str,
        'total_logs_exported': total_logs
    }
    
    # Append to JSONL file (each line is a JSON object)
    try:
        # Try to get existing metadata
        try:
            response = s3_client.get_object(Bucket=bucket, Key=metadata_key)
            existing_content = response['Body'].read().decode('utf-8')
        except s3_client.exceptions.NoSuchKey:
            existing_content = ''
        
        # Append new run
        new_content = existing_content + json.dumps(export_run) + '\n'
        
        s3_client.put_object(
            Bucket=bucket,
            Key=metadata_key,
            Body=new_content,
            ContentType='application/x-ndjson',
            ServerSideEncryption='AES256'
        )
        
        print(f"Stored export metadata: {export_run}")
        
    except Exception as e:
        print(f"Warning: Could not store metadata: {e}")

def convert_to_json(logs: List[Dict[str, Any]]) -> str:
    """
    Convert logs to JSON format
    """
    return json.dumps(logs, indent=2, ensure_ascii=False)

def convert_to_csv(logs: List[Dict[str, Any]]) -> str:
    """
    Convert logs to CSV format
    """
    if not logs:
        return ""
    
    output = io.StringIO()
    
    # Define CSV columns
    columns = [
        'timestamp', 'level', 'service', 'category', 'message', 
        'userId', 'userName', 'sessionId', 'metadata'
    ]
    
    writer = csv.DictWriter(output, fieldnames=columns, extrasaction='ignore')
    writer.writeheader()
    
    for log in logs:
        # Flatten the log for CSV
        csv_row = {
            'timestamp': log.get('@timestamp', log.get('timestamp', '')),
            'level': log.get('level', ''),
            'service': log.get('service', ''),
            'category': log.get('category', ''),
            'message': log.get('message', ''),
            'userId': log.get('userId', ''),
            'userName': log.get('userName', ''),
            'sessionId': log.get('sessionId', ''),
            'metadata': json.dumps(log.get('metadata', {})) if log.get('metadata') else ''
        }
        writer.writerow(csv_row)
    
    return output.getvalue()
