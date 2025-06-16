import os
import json
import datetime
import boto3

def lambda_handler(event, context):
    """
    Lambda function to demonstrate scheduled execution.
    In a real scenario, this would clean an S3 directory or perform other tasks.
    """
    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    message = f"Lambda function triggered at: {current_time}. Event: {json.dumps(event)}"
    print(message)

    return {
        'statusCode': 200,
        'body': json.dumps(message)
    }