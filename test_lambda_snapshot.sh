#!/bin/bash

REGION="ap-south-1"
LOG_SCRIPT="./validate_logs.sh"

echo "⏳ Step 1: Create a small test volume..."
VOLUME_ID=$(aws ec2 create-volume \
    --availability-zone ap-south-1a \
    --size 1 \
    --volume-type gp2 \
    --region $REGION \
    --query 'VolumeId' \
    --output text)
echo "✅ Created Volume: $VOLUME_ID"

echo "⏳ Step 2: Create a snapshot for this volume..."
SNAPSHOT_ID=$(aws ec2 create-snapshot \
    --volume-id $VOLUME_ID \
    --description "Test snapshot for Lambda deletion" \
    --region $REGION \
    --query 'SnapshotId' \
    --output text)
echo "✅ Created Snapshot: $SNAPSHOT_ID (pending)"

# Wait until snapshot is completed
echo "⏳ Step 3: Waiting for snapshot to complete..."
aws ec2 wait snapshot-completed --snapshot-ids $SNAPSHOT_ID --region $REGION
echo "✅ Snapshot $SNAPSHOT_ID is now completed."

echo "⏳ Step 4: Invoke Lambda function to clean snapshots..."
aws lambda invoke \
    --function-name snapshot_cleaner \
    --region $REGION \
    lambda_response.json
echo "✅ Lambda invoked. Check lambda_response.json for output."

echo "⏳ Step 5: Validate Lambda logs..."
$LOG_SCRIPT

echo "⏳ Step 6: Confirm snapshot deletion..."
aws ec2 describe-snapshots \
    --snapshot-ids $SNAPSHOT_ID \
    --region $REGION \
    --query 'Snapshots[0].{SnapshotId:SnapshotId,State:State}' \
    --output table

echo "✅ Test completed!"
