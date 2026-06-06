# Scenario 3 — S3 → EventBridge → Lambda (advanced routing)

**Pattern:** S3 sends events to the **default EventBridge bus**, and an EventBridge rule routes
matching events to the message-printer Lambda.

> ```
> S3 (all events) ──▶ EventBridge (default bus) ──▶ rule (source = aws.s3) ──▶ Lambda
> ```

Best for **complex routing and filtering** — one bus, many rules, content-based patterns, and
targets beyond Lambda (Step Functions, SQS, API destinations, etc.).

## Goal
Turn on S3 → EventBridge for the bucket and observe the Lambda being triggered via EventBridge.

## Prerequisites
- The demo stack is deployed.
- Relevant **stack outputs:** `BucketName`, `LambdaFunctionName`.
- The stack has already created an EventBridge rule on the **default** bus that matches
  `source: aws.s3` and targets the Lambda (plus the invoke permission). You only flip the
  S3 → EventBridge toggle.

> 📍 **Note on filtering:** Unlike the Lambda / SNS / SQS destinations, the S3 → EventBridge
> integration has **no prefix/suffix or event-type selector**. Turning it on sends **all** S3
> events for the bucket to EventBridge. Any filtering must be done in the **EventBridge rule's
> event pattern**, not at S3.

## Steps
1. Open the **S3** console and select the bucket from the `BucketName` output.
2. Go to **Properties → Amazon EventBridge → Edit**.
3. Set **Send notifications to Amazon EventBridge for all events in this bucket** to **On**.
4. Click **Save changes**.

## Test
1. Upload another file to the bucket.
2. Open the message-printer Lambda's **CloudWatch Logs**.

## Validation
- You will typically see **two** log entries for a single upload:
  1. `LAMBDA TRIGGERED BY: S3` — from the direct notification you set up in **Scenario 1**.
  2. `LAMBDA TRIGGERED BY: EventBridge (S3 Object Event)` — the same upload, now also delivered
     via EventBridge.
- The EventBridge variant is recognizable by the **`detail-type`** field in the JSON
  (e.g. `Object Created`).

## What you learned
EventBridge is the most flexible option: a single event can drive many rules and targets, with
rich, content-based pattern matching. The trade-off is that filtering happens in the rule, not
at the S3 source.
