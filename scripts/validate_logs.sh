#!/bin/bash

LOG_GROUP="/aws/lambda/snapshot_cleaner"
AWS_REGION="ap-south-1"

aws logs get-log-events --log-group-name $LOG_GROUP --log-stream-name "$(aws logs describe-log-streams --log-group-name $LOG_GROUP --order-by LastEventTime --descending --limit 1 --query 'logStreams[0].logStreamName' --output text)" --region $AWS_REGION | grep -q "Deleting"
if [ $? -eq 0 ]; then
  echo "Validation successful: Deletion log found."
else
  echo "Validation failed: No deletion log found."
  exit 1
fi