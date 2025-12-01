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
import hashlib
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Any, Optional
import time

# AWS clients
logs_client = boto3.client('logs')
s3_client = boto3.client('s3')

def handler(event, context):
    """
    Export user_action logs from CloudWatch to S3 in JSON/CSV format
    """
    log_group_name = os.environ['LOG_GROUP_NAME']
    s3_bucket = os.environ['S3_BUCKET']
    s3_prefix = os.environ.get('S3_PREFIX', 'user-actions')
    export_format = os.environ.get('EXPORT_FORMAT', 'json')  # json or csv
    
    # Vietnam timezone (UTC+7)
    vietnam_tz = timezone(timedelta(hours=7))
    
    # Allow manual override for testing (export today's logs)
    test_mode = event.get('test_mode', False)
    
    # Calculate date range in Vietnam time
    now_vietnam = datetime.now(vietnam_tz)
    
    if test_mode:
        # For testing: export today's logs
        target_date = now_vietnam
        print("TEST MODE: Exporting today's logs")
    else:
        # Normal mode: export yesterday's logs
        target_date = now_vietnam - timedelta(days=1)
    
    start_date = target_date.replace(hour=0, minute=0, second=0, microsecond=0)
    end_date = target_date.replace(hour=23, minute=59, second=59, microsecond=999999)
    
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
    Export logs to S3 in specified format with duplicate prevention
    
    Strategy:
    1. Check if file exists and merge with existing data
    2. Use log IDs to deduplicate (timestamp + userId + message + metadata hash)
    3. Store metadata about export runs
    """
    # Create S3 key
    year, month, day = date_str.split('-')
    
    if format_type.lower() == 'csv':
        file_key = f"{prefix}/year={year}/month={month}/day={day}/user_actions.csv"
        content_type = 'text/csv'
    else:
        file_key = f"{prefix}/year={year}/month={month}/day={day}/user_actions.json"
        content_type = 'application/json'
    
    # Add unique IDs to logs for deduplication
    logs_with_ids = add_unique_ids(logs)
    
    # Check if file already exists and merge
    existing_logs = get_existing_logs(bucket, file_key, format_type)
    
    if existing_logs:
        print(f"Found existing file with {len(existing_logs)} logs. Merging...")
        merged_logs = merge_and_deduplicate(existing_logs, logs_with_ids)
        print(f"After deduplication: {len(merged_logs)} logs (removed {len(existing_logs) + len(logs_with_ids) - len(merged_logs)} duplicates)")
    else:
        merged_logs = logs_with_ids
        print(f"No existing file. Creating new with {len(merged_logs)} logs")
    
    # Convert to format
    if format_type.lower() == 'csv':
        content = convert_to_csv(merged_logs)
    else:
        content = convert_to_json(merged_logs)
    
    # Upload to S3
    s3_client.put_object(
        Bucket=bucket,
        Key=file_key,
        Body=content,
        ContentType=content_type,
        ServerSideEncryption='AES256'
    )
    
    # Store export metadata for tracking
    store_export_metadata(bucket, prefix, date_str, len(merged_logs), len(logs_with_ids))
    
    return file_key

def add_unique_ids(logs: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Add unique ID to each log based on its content
    ID = hash(timestamp + userId + message + metadata)
    """
    logs_with_ids = []
    
    for log in logs:
        # Create unique identifier from log content
        id_components = [
            str(log.get('@timestamp', log.get('timestamp', ''))),
            str(log.get('userId', '')),
            str(log.get('message', '')),
            json.dumps(log.get('metadata', {}), sort_keys=True)
        ]
        
        unique_string = '|'.join(id_components)
        log_id = hashlib.sha256(unique_string.encode()).hexdigest()[:16]
        
        log_copy = log.copy()
        log_copy['_log_id'] = log_id
        logs_with_ids.append(log_copy)
    
    return logs_with_ids

def get_existing_logs(bucket: str, file_key: str, format_type: str) -> Optional[List[Dict[str, Any]]]:
    """
    Get existing logs from S3 if file exists
    """
    try:
        response = s3_client.get_object(Bucket=bucket, Key=file_key)
        content = response['Body'].read().decode('utf-8')
        
        if format_type.lower() == 'csv':
            return parse_csv_logs(content)
        else:
            return json.loads(content)
            
    except s3_client.exceptions.NoSuchKey:
        return None
    except Exception as e:
        print(f"Error reading existing file: {e}")
        return None

def parse_csv_logs(csv_content: str) -> List[Dict[str, Any]]:
    """
    Parse CSV content back to log dictionaries
    """
    logs = []
    reader = csv.DictReader(io.StringIO(csv_content))
    
    for row in reader:
        log = {
            '@timestamp': row.get('timestamp', ''),
            'level': row.get('level', ''),
            'service': row.get('service', ''),
            'category': row.get('category', ''),
            'message': row.get('message', ''),
            'userId': int(row['userId']) if row.get('userId') and row['userId'].isdigit() else None,
            'userName': row.get('userName', ''),
            'sessionId': row.get('sessionId', ''),
            '_log_id': row.get('_log_id', '')
        }
        
        # Parse metadata JSON
        if row.get('metadata'):
            try:
                log['metadata'] = json.loads(row['metadata'])
            except json.JSONDecodeError:
                log['metadata'] = {}
        
        logs.append(log)
    
    return logs

def merge_and_deduplicate(existing_logs: List[Dict[str, Any]], new_logs: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Merge existing and new logs, removing duplicates based on _log_id
    """
    # Create a dictionary with log_id as key
    merged = {}
    
    # Add existing logs
    for log in existing_logs:
        log_id = log.get('_log_id')
        if log_id:
            merged[log_id] = log
    
    # Add new logs (will overwrite if duplicate)
    for log in new_logs:
        log_id = log.get('_log_id')
        if log_id:
            merged[log_id] = log
    
    # Convert back to list and sort by timestamp
    result = list(merged.values())
    result.sort(key=lambda x: x.get('@timestamp', x.get('timestamp', '')))
    
    return result

def store_export_metadata(bucket: str, prefix: str, date_str: str, total_logs: int, new_logs: int):
    """
    Store metadata about this export run for tracking
    """
    year, month, day = date_str.split('-')
    metadata_key = f"{prefix}/_metadata/year={year}/month={month}/day={day}/export_runs.jsonl"
    
    export_run = {
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'date': date_str,
        'total_logs_in_file': total_logs,
        'new_logs_processed': new_logs,
        'duplicates_removed': new_logs - (total_logs - get_previous_total(bucket, metadata_key))
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

def get_previous_total(bucket: str, metadata_key: str) -> int:
    """
    Get the total logs from the previous export run
    """
    try:
        response = s3_client.get_object(Bucket=bucket, Key=metadata_key)
        content = response['Body'].read().decode('utf-8')
        lines = content.strip().split('\n')
        
        if lines and lines[-1]:
            last_run = json.loads(lines[-1])
            return last_run.get('total_logs_in_file', 0)
    except:
        pass
    
    return 0

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
    
    # Define CSV columns (include _log_id for deduplication)
    columns = [
        '_log_id', 'timestamp', 'level', 'service', 'category', 'message', 
        'userId', 'userName', 'sessionId', 'metadata'
    ]
    
    writer = csv.DictWriter(output, fieldnames=columns, extrasaction='ignore')
    writer.writeheader()
    
    for log in logs:
        # Flatten the log for CSV
        csv_row = {
            '_log_id': log.get('_log_id', ''),
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
