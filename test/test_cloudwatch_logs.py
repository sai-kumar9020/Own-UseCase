import os
import time
import boto3
import pytest

# Environment variables from CI/CD pipeline
LAMBDA_FUNCTION_NAME = "my-scheduled-app-scheduled-function"
LAMBDA_LOG_GROUP_NAME = "/aws/lambda/my-scheduled-app-scheduled-function"
@pytest.fixture(scope="module")
def lambda_client():
    return boto3.client('lambda', region_name=os.environ.get('AWS_REGION', 'us-east-1'))

@pytest.fixture(scope="module")
def logs_client():
    return boto3.client('logs', region_name=os.environ.get('AWS_REGION', 'us-east-1'))

def test_lambda_invocation_and_logs(lambda_client, logs_client):
    if not LAMBDA_FUNCTION_NAME or not LAMBDA_LOG_GROUP_NAME:
        pytest.skip("LAMBDA_FUNCTION_NAME or LAMBDA_LOG_GROUP_NAME not set. Skipping test.")

    # 1. Invoke the Lambda function
    print(f"Invoking Lambda function: {LAMBDA_FUNCTION_NAME}")
    try:
        response = lambda_client.invoke(
            FunctionName=LAMBDA_FUNCTION_NAME,
            InvocationType='RequestResponse', # Synchronous invocation
            Payload='{}' # Empty payload for this simple test
        )
        payload = response['Payload'].read().decode('utf-8')
        print(f"Lambda invocation response: {payload}")
        assert response['StatusCode'] == 200, f"Lambda invocation failed with status {response['StatusCode']}"
    except Exception as e:
        pytest.fail(f"Error invoking Lambda: {e}")

    # Give Lambda a moment to write logs
    time.sleep(5)

    # 2. Check CloudWatch Logs for the expected output
    print(f"Checking logs in CloudWatch Log Group: {LAMBDA_LOG_GROUP_NAME}")
    try:
        # Get the latest log stream
        response = logs_client.describe_log_streams(
            logGroupName=LAMBDA_LOG_GROUP_NAME,
            orderBy='LastEventTime',
            descending=True,
            limit=1
        )
        log_streams = response.get('logStreams')

        assert log_streams, "No log streams found for the Lambda function."
        latest_log_stream_name = log_streams[0]['logStreamName']
        print(f"Latest log stream: {latest_log_stream_name}")

        # Fetch log events from the latest stream
        log_events_found = False
        start_time_millis = int((time.time() - 30) * 1000) # Look back 30 seconds
        for _ in range(5): # Retry a few times if logs aren't immediately available
            events_response = logs_client.get_log_events(
                logGroupName=LAMBDA_LOG_GROUP_NAME,
                logStreamName=latest_log_stream_name,
                startTime=start_time_millis,
                startFromHead=False
            )
            log_events = events_response.get('events', [])
            if log_events:
                for event in log_events:
                    print(f"Log event: {event['message']}")
                    if "Lambda function triggered at:" in event['message']:
                        log_events_found = True
                        break
            if log_events_found:
                break
            time.sleep(2) # Wait a bit before retrying

        assert log_events_found, "Expected log message 'Lambda function triggered at:' not found in CloudWatch Logs."

    except Exception as e:
        pytest.fail(f"Error checking CloudWatch Logs: {e}")
