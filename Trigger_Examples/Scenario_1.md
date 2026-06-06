# Scenario 1 — S3 → Lambda (direct event notification)

**Pattern:** S3 sends an object-created event *directly* to the message-printer Lambda.

> ```
> S3 (object created) ──▶ Lambda (message-printer)
> ```

This is the simplest, lowest-latency way to react to an S3 event. Best for real-time,
lightweight integrations.

## Goal
Configure S3 to invoke the Lambda whenever a file is **uploaded** to the bucket.

## Prerequisites
- The demo stack is deployed (see the project [README](../README.md)).
- Note these **stack outputs** — you will need them throughout:
  - `BucketName` — the demo bucket
  - `LambdaFunctionName` — the message-printer Lambda
- The stack has already granted S3 permission to invoke the Lambda, so all you do here is
  create the notification.

## Steps
1. Open the **S3** console and select the bucket from the `BucketName` output.
2. Go to **Properties → Event notifications → Create event notification**.
3. Under *General configuration*:
   - **Event name:** `lambda-trigger`
   - Leave **Prefix** and **Suffix** blank.
4. **Event types:** select **All object create events** (`s3:ObjectCreated:*`).
5. **Destination:** choose **Lambda function**, then select the function from the
   `LambdaFunctionName` output.
6. Click **Save changes**.

## Test
1. Upload any test file to the bucket (e.g. one of the `S3_test_file_*.txt` files in this repo).
2. Open the Lambda's **CloudWatch Logs** (Lambda console → your function → **Monitor** tab →
   **View CloudWatch logs**, or use the `LogsConsoleLink` stack output).

## Validation
- You should see the message **`LAMBDA TRIGGERED BY: S3`** in the logs.
- The logged JSON contains object **metadata** (bucket name, object key, size, etc.) —
  **not** the content of the object itself.

## What you learned
S3 can invoke a Lambda directly with no intermediary. The event payload describes *what happened*,
and your function fetches the object separately if it needs the contents.
