import boto3
import datetime
import os
from botocore.exceptions import ClientError

ec2_client = boto3.client('ec2')
sns_client = boto3.client('sns')
logger = boto3.client('logs')

RETENTION_DAYS = int(os.environ.get('RETENTION_DAYS', 7))
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

def lambda_handler(event, context):
    try:
        snapshots = ec2_client.describe_snapshots(OwnerIds=['self'])['Snapshots']
        current_time = datetime.datetime.now(datetime.timezone.utc)
        deleted_count = 0

        for snapshot in snapshots:
            snapshot_id = snapshot['SnapshotId']
            creation_date = snapshot['StartTime']
            age_days = (current_time - creation_date).days

            if age_days > RETENTION_DAYS and not is_snapshot_in_use(snapshot_id):
                logger.put_log_events(
                    logGroupName='/aws/lambda/snapshot_cleaner',
                    logStreamName=context.log_stream_name,
                    logEvents=[{'timestamp': int(current_time.timestamp() * 1000), 'message': f'Deleting {snapshot_id} (age: {age_days} days)'}]
                )
                ec2_client.delete_snapshot(SnapshotId=snapshot_id)
                deleted_count += 1

        if deleted_count > 0:
            sns_client.publish(TopicArn=SNS_TOPIC_ARN, Message=f'Deleted {deleted_count} unused snapshots.')
        return {'statusCode': 200, 'body': f'Processed {len(snapshots)}, deleted {deleted_count}.'}
    except ClientError as e:
        logger.put_log_events(
            logGroupName='/aws/lambda/snapshot_cleaner',
            logStreamName=context.log_stream_name,
            logEvents=[{'timestamp': int(current_time.timestamp() * 1000), 'message': f'Error: {str(e)}'}]
        )
        sns_client.publish(TopicArn=SNS_TOPIC_ARN, Message=f'Error: {str(e)}.')
        raise

def is_snapshot_in_use(snapshot_id):
    instances = ec2_client.describe_instances()['Reservations']
    for reservation in instances:
        for instance in reservation['Instances']:
            if 'BlockDeviceMappings' in instance:
                for mapping in instance['BlockDeviceMappings']:
                    if 'Ebs' in mapping and mapping['Ebs'].get('SnapshotId') == snapshot_id:
                        return True
    images = ec2_client.describe_images(Owners=['self'])['Images']
    for image in images:
        if 'BlockDeviceMappings' in image and any(mapping.get('Ebs', {}).get('SnapshotId') == snapshot_id for mapping in image['BlockDeviceMappings']):
            return True
    return False