import json
import boto3
import logging
from datetime import datetime
import time

# Initialize CloudWatch Logs client
logs = boto3.client('logs', region_name='eu-west-1')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def create_log_group_and_stream(log_group_name, log_stream_name):
    """Creates a log group and log stream if they do not exist."""
    try:
        # Check if the log group exists
        response = logs.describe_log_groups(logGroupNamePrefix=log_group_name)
        if not any(group['logGroupName'] == log_group_name for group in response['logGroups']):
            # Create log group if it doesn't exist
            logs.create_log_group(logGroupName=log_group_name)
            logger.info(f"Created log group: {log_group_name}")
        else:
            logger.info(f"Log group {log_group_name} already exists.")
        
    except Exception as e:
        logger.error(f"Error checking or creating log group {log_group_name}: {e}")
        raise e

    try:
        # Check if the log stream exists
        response = logs.describe_log_streams(logGroupName=log_group_name, logStreamNamePrefix=log_stream_name)
        if not any(stream['logStreamName'] == log_stream_name for stream in response['logStreams']):
            # Create log stream if it doesn't exist
            logs.create_log_stream(logGroupName=log_group_name, logStreamName=log_stream_name)
            logger.info(f"Created log stream: {log_stream_name}")
        else:
            logger.info(f"Log stream {log_stream_name} already exists.")
    except Exception as e:
        logger.error(f"Error checking or creating log stream {log_stream_name}: {e}")
        raise e

    # Wait a few seconds to log stream is ready
    time.sleep(2)

def lambda_handler(event, context):
    build_number = event.get('build_number', 'unknown')
    test_type = event.get('test_type', 'unknown')  # SAST, DAST, or DepCheck

    vulnerabilities = event.get('results', [])

    findings = []

    for vulnerability in vulnerabilities:
        current_time = datetime.utcnow().isoformat() + "Z"
        fix = vulnerability['extra'].get('fix', 'No fix provided') 
        finding = {
            'SchemaVersion': '2018-10-08', 
            'Id': f"{vulnerability['check_id']}-{vulnerability['path']}",
            'Title': vulnerability['check_id'],
            'Description': vulnerability['extra']['message'],
            'GeneratorId': vulnerability['check_id'],
            'Severity': {
                'Label': vulnerability['extra']['severity']  
            },
            'Resources': [
                {
                    'Type': 'Wagtail',
                    'Id': vulnerability['path']
                }
            ],
            'CreatedAt': current_time,  
            'UpdatedAt': current_time,
            'ProductFields': {
                'SemgrepRule': vulnerability['check_id']
            },
            'Remediation': {
                'Recommendation': {
                    'Text': fix
                }
            },
            'SourceUrl': vulnerability['extra']['metadata']['source'],
            'TestType': test_type, 
            'BuildNumber': build_number,
        }

        findings.append(finding)

    # log the total number of findings
    logger.info(f"Total findings: {len(findings)}")

    try:
        # Define log group and stream names
        log_group_name = 'SecurityTestingLogs'  
        log_stream_name = f"{test_type}/{build_number}" 

        # Create log group and log stream if they don't exist
        create_log_group_and_stream(log_group_name, log_stream_name)

        # Log each finding to CloudWatch
        for finding in findings:
            response = logs.put_log_events(
                logGroupName=log_group_name,  
                logStreamName=log_stream_name,  
                logEvents=[
                    {
                        'timestamp': int(datetime.utcnow().timestamp() * 1000), 
                        'message': json.dumps(finding) 
                    }
                ]
            )
            logger.info(f"Successfully sent finding to CloudWatch Logs: {response}")

    except Exception as e:
        logger.error(f"Error sending findings to CloudWatch Logs: {e}")
        raise e
