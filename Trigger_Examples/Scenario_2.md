# Scenario 2 — S3 → SNS → Lambda (fan-out)

**Pattern:** S3 publishes an object-removed event to an SNS topic, which fans out to the
message-printer Lambda (and could fan out to many other subscribers).

> ```
> S3 (object removed) ──▶ SNS topic ──▶ Lambda (message-printer)
>                                   └──▶ (any other subscribers...)
> ```

Best when **multiple** consumers need the same event, or you want to decouple producers from
consumers.

## Goal
Configure S3 so that **deleting** a file publishes to SNS, which in turn triggers the Lambda.

## Prerequisites
- The demo stack is deployed.
- Relevant **stack outputs:** `BucketName`, `SnsTopicArn`, `LambdaFunctionName`.
- The stack has already: created the topic, subscribed the Lambda to it, granted SNS permission
  to invoke the Lambda, and granted S3 permission to publish to the topic. You only create the
  S3 → SNS notification.

> **Why a different event type than Scenario 1?** S3 will not let two notifications overlap on
> the same event type **and** the same prefix/suffix. Scenario 1 uses *object create* events;
> this scenario uses *object removal* events, so they coexist cleanly.

## Steps
1. Open the **S3** console and select the bucket from the `BucketName` output.
2. Go to **Properties → Event notifications → Create event notification**.
3. Under *General configuration*:
   - **Event name:** `sns-trigger`
   - Leave **Prefix** and **Suffix** blank.
4. **Event types:** select **All object removal events** (`s3:ObjectRemoved:*`).
5. **Destination:** choose **SNS topic**, then select the topic matching the `SnsTopicArn` output.
6. Click **Save changes**.

## Test
1. **Delete** a file you previously uploaded to the bucket.
2. Open the message-printer Lambda's **CloudWatch Logs**.

## Validation
- You should see **`LAMBDA TRIGGERED BY: SNS`**.
- This confirms the chain: S3 published the delete event to SNS, and SNS invoked the Lambda.
  The S3 event is carried *inside* the SNS message envelope (look for the `Sns` block in the JSON).

## What you learned
SNS decouples the producer (S3) from consumers and supports **fan-out** to many subscribers.
The Lambda now receives an SNS-shaped event that wraps the original S3 event.
