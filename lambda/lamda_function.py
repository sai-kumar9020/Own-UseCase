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

#  If you were cleaning an S3 directory
    s3_bucket_name = os.environ.get('S3_BUCKET_NAME')
    s3_prefix = os.environ.get('S3_PREFIX')
    if s3_bucket_name and s3_prefix:
         s3_client = boto3.client('s3')
         response = s3_client.list_objects_v2(Bucket=s3_bucket_name, Prefix=s3_prefix)
         if 'Contents' in response:
             for obj in response['Contents']:
                 print(f"Deleting s3://{s3_bucket_name}/{obj['Key']}")
                 s3_client.delete_object(Bucket=s3_bucket_name, Key=obj['Key'])
         else:
             print(f"No objects found in s3://{s3_bucket_name}/{s3_prefix}")
     else:
         print("S3_BUCKET_NAME or S3_PREFIX not set, skipping S3 cleanup.")


    return {
        'statusCode': 200,
        'body': json.dumps(message)
    }