#!/bin/bash

LOG_GROUP="/aws/lambda/snapshot_cleaner"
KEYWORD="Deleted snapshot"
REGION="ap-south-1"

echo "🔎 Validating logs for Lambda function: snapshot_cleaner..."

# 1. Check if log group exists
aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" --region $REGION --query "logGroups[].logGroupName" --output text | grep -q "$LOG_GROUP"

if [ $? -ne 0 ]; then
    echo "⚠️ Log group $LOG_GROUP not found. Creating it..."
    aws logs create-log-group --log-group-name "$LOG_GROUP" --region $REGION
    echo "✅ Created log group: $LOG_GROUP"
    echo "ℹ️ Run the Lambda at least once before re-checking logs."
    exit 0
fi

# 2. Get latest log stream
LOG_STREAM=$(aws logs describe-log-streams \
    --log-group-name "$LOG_GROUP" \
    --order-by LastEventTime \
    --descending \
    --max-items 1 \
    --region $REGION \
    --query "logStreams[0].logStreamName" \
    --output text)

if [ "$LOG_STREAM" == "None" ] || [ -z "$LOG_STREAM" ]; then
    echo "⚠️ No log streams found in $LOG_GROUP. Run the Lambda at least once."
    exit 0
fi

echo "📄 Checking logs in stream: $LOG_STREAM"

# 3. Fetch recent log events
LOG_OUTPUT=$(aws logs get-log-events \
    --log-group-name "$LOG_GROUP" \
    --log-stream-name "$LOG_STREAM" \
    --region $REGION \
    --limit 50 \
    --query "events[].message" \
    --output text)

# 4. Validate snapshot deletion keyword
if echo "$LOG_OUTPUT" | grep -q "$KEYWORD"; then
    echo "✅ Validation successful: Found snapshot deletion logs."
    echo "$LOG_OUTPUT" | grep "$KEYWORD"
else
    echo "❌ Validation failed: No snapshot deletion logs found."
    echo "🔎 Raw logs:"
    echo "$LOG_OUTPUT"
fi
