# Scenario 4 — S3 → SQS → Lambda (buffered / decoupled)

**Pattern:** S3 sends an object-created event to an SQS queue, and the Lambda polls the queue
(via an event source mapping) to process messages.

> ```
> S3 (object created, prefix "sqs/") ──▶ SQS queue ──▶ Lambda (polls the queue)
> ```

Best when you want to **buffer** bursts, **decouple** processing from arrival, get built-in
**retries**, or batch work. This completes the four S3 *Event Notification* destinations
(Lambda, SNS, SQS, EventBridge).

## Goal
Configure S3 so that uploading a file under the `sqs/` prefix sends a message to SQS, which the
Lambda then consumes.

## Prerequisites
- The demo stack is deployed.
- Relevant **stack outputs:** `BucketName`, `SqsQueueArn`, `SqsQueueUrl`, `LambdaFunctionName`.
- The stack has already: created the queue, granted S3 permission to send messages to it, and
  created the **SQS → Lambda event source mapping**. You only create the S3 → SQS notification.

> **Why the `sqs/` prefix?** Scenario 1 already registered an *object create* notification with
> **no** prefix. S3 rejects a second *object create* notification that overlaps it, so this
> scenario scopes its create notification to the `sqs/` prefix. The two coexist: uploads under
> `sqs/` go to SQS, everything else continues to go to the Scenario-1 Lambda notification.

## Steps
1. Open the **S3** console and select the bucket from the `BucketName` output.
2. Go to **Properties → Event notifications → Create event notification**.
3. Under *General configuration*:
   - **Event name:** `sqs-trigger`
   - **Prefix:** `sqs/`
   - Leave **Suffix** blank.
4. **Event types:** select **All object create events** (`s3:ObjectCreated:*`).
5. **Destination:** choose **SQS queue**, then select the queue matching the `SqsQueueArn` output.
6. Click **Save changes**.

## Test
1. Upload a file into the `sqs/` "folder" of the bucket (object key like `sqs/test.txt`).
   - In the console: open the bucket, **Create folder** named `sqs`, then upload a file into it.
2. Open the message-printer Lambda's **CloudWatch Logs**.

## Validation
- You should see **`LAMBDA TRIGGERED BY: SQS`**.
- The S3 event is carried inside the SQS record's **`body`** field, and the record's
  `eventSource` is `aws:sqs`.
- Uploading a file **outside** the `sqs/` prefix instead triggers `LAMBDA TRIGGERED BY: S3`
  (Scenario 1) — proving prefix-scoped routing.

## What you learned
SQS adds a durable buffer between S3 and your processing logic, with automatic retries and
batching. Unlike the other destinations, SQS → Lambda is a **poll-based** integration (an event
source mapping), which the stack created for you.
