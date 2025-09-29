import boto3
import datetime
import os
from botocore.exceptions import ClientError

ec2_client = boto3.client('ec2')
sns_client = boto3.client('sns')

RETENTION_DAYS = int(os.environ.get('RETENTION_DAYS', 0))
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

def lambda_handler(event, context):
    try:
        snapshots = ec2_client.describe_snapshots(OwnerIds=['self'])['Snapshots']
        current_time = datetime.datetime.now(datetime.timezone.utc)
        deleted_count = 0

        print(f"Found {len(snapshots)} snapshots. Retention: {RETENTION_DAYS} days")

        for snapshot in snapshots:
            snapshot_id = snapshot['SnapshotId']
            creation_date = snapshot['StartTime']
            age_days = (current_time - creation_date).days

            if age_days > RETENTION_DAYS and not is_snapshot_in_use(snapshot_id):
                print(f"Deleting snapshot {snapshot_id} (age: {age_days} days)")
                ec2_client.delete_snapshot(SnapshotId=snapshot_id)
                deleted_count += 1

        if deleted_count > 0:
            sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=f"Deleted {deleted_count} unused snapshots."
            )
            print(f"Deleted {deleted_count} snapshots. SNS notification sent.")
        else:
            print("No snapshots to delete.")

        return {'statusCode': 200, 'body': f'Processed {len(snapshots)} snapshots, deleted {deleted_count}.'}

    except ClientError as e:
        print(f"Error: {str(e)}")
        sns_client.publish(TopicArn=SNS_TOPIC_ARN, Message=f"Error: {str(e)}")
        raise

def is_snapshot_in_use(snapshot_id):
    # Check instances
    instances = ec2_client.describe_instances()['Reservations']
    for reservation in instances:
        for instance in reservation['Instances']:
            for mapping in instance.get('BlockDeviceMappings', []):
                if mapping.get('Ebs', {}).get('SnapshotId') == snapshot_id:
                    return True

    # Check AMIs
    images = ec2_client.describe_images(Owners=['self'])['Images']
    for image in images:
        for mapping in image.get('BlockDeviceMappings', []):
            if mapping.get('Ebs', {}).get('SnapshotId') == snapshot_id:
                return True

    return False
