#!/bin/bash

LOG_GROUP="/aws/lambda/snapshot_cleaner"
KEYWORD="Deleting"
REGION="ap-south-1"
MAX_WAIT=30  # Max seconds to wait for logs

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

# 2. Wait until log stream appears
WAITED=0
LOG_STREAM=""
while [ $WAITED -lt $MAX_WAIT ]; do
    LOG_STREAM=$(aws logs describe-log-streams \
        --log-group-name "$LOG_GROUP" \
        --order-by LastEventTime \
        --descending \
        --limit 1 \
        --region $REGION \
        --query "logStreams[0].logStreamName" \
        --output text)
    if [ "$LOG_STREAM" != "None" ] && [ -n "$LOG_STREAM" ]; then
        break
    fi
    sleep 2
    WAITED=$((WAITED+2))
done

if [ -z "$LOG_STREAM" ] || [ "$LOG_STREAM" == "None" ]; then
    echo "❌ No log streams found in $LOG_GROUP. Run the Lambda at least once."
    exit 1
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
