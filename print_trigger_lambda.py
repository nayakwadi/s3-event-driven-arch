import json
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def detect_event_source(event):
    """
    Detect the source of the Lambda invocation
    Returns: 'S3', 'SNS', 'SQS', 'EventBridge (S3 Object Event)', or 'Unknown'
    """
    # Check for record-based events (S3, SNS, SQS)
    if 'Records' in event and len(event['Records']) > 0:
        first_record = event['Records'][0]

        # SNS events have 'Sns' key in the record
        if 'Sns' in first_record:
            return 'SNS'

        # SQS events have 'eventSource' = 'aws:sqs'
        # (the original S3 event is carried inside the record 'body')
        if first_record.get('eventSource') == 'aws:sqs':
            return 'SQS'

        # S3 events have 'eventSource' = 'aws:s3'
        if first_record.get('eventSource') == 'aws:s3':
            return 'S3'
    
    # Check for EventBridge event - but only S3 object events, not CloudTrail API calls
    # EventBridge events have 'source', 'detail-type', and 'detail' keys
    if 'source' in event and 'detail-type' in event and 'detail' in event:
        # Filter out CloudTrail API call events - only show actual S3 object events
        detail_type = event.get('detail-type', '')
        
        # S3 object events have detail-types like "Object Created", "Object Deleted", etc.
        # CloudTrail events have detail-type "AWS API Call via CloudTrail"
        if detail_type != 'AWS API Call via CloudTrail' and event.get('source') == 'aws.s3':
            return 'EventBridge (S3 Object Event)'
        
        # Don't report CloudTrail events as EventBridge to avoid confusion
        return 'Unknown'
    
    return 'Unknown'

def lambda_handler(event, context):
    """
    Simple message printer - shows raw event JSON in CloudWatch Logs
    Detects and logs the event source (S3, SNS, or EventBridge)
    Silently ignores CloudTrail API call events to avoid confusion
    """
    try:
        # Detect the event source
        event_source = detect_event_source(event)
        
        # Silently ignore CloudTrail events - don't log anything
        if event_source == 'Unknown':
            # Check if it's a CloudTrail event
            if 'detail-type' in event and event.get('detail-type') == 'AWS API Call via CloudTrail':
                # Return success but don't log anything
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': 'CloudTrail event ignored',
                        'eventSource': 'CloudTrail (ignored)'
                    })
                }
        
        # Log the event source prominently for valid events (using logger.info only)
        logger.info(f"========================================")
        logger.info(f"LAMBDA TRIGGERED BY: {event_source}")
        logger.info(f"========================================")
        logger.info("Event received")
        logger.info(json.dumps(event, indent=2, default=str))
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Event processed successfully',
                'eventSource': event_source
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing event: {str(e)}")
        raise
