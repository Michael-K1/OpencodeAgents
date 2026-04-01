---
name: lambda-delegation
description: >
  Lambda handler delegation reference for IaC and developer agents. Provides
  the standard delegation protocol for routing Lambda handler code tasks to the
  correct language-specific expert agent (TypeScript, Python, Go). Load this
  skill when a task involves writing or modifying Lambda handler code.
---

# Lambda Handler Delegation Protocol

When a task involves writing, modifying, or reviewing Lambda handler code, **delegate to the appropriate language-specific Lambda expert** via the Task tool. Do NOT write handler code yourself — the Lambda experts have deep knowledge of runtime-specific patterns, middleware, testing frameworks, and project conventions.

## Lambda Expert Agents

| Language | Agent | Key Technologies |
|----------|-------|-----------------|
| TypeScript / Node.js | `@lambda-ts-expert` | Node.js 24, ESM, Middy v6, AWS Lambda Powertools for TypeScript, AWS SDK v3, Vitest |
| Python | `@lambda-python-expert` | boto3, AWS Lambda Powertools for Python, pydantic, pytest |
| Go | `@lambda-go-expert` | aws-lambda-go, AWS SDK for Go v2, standard testing + testify |

## What to Provide the Lambda Expert

When delegating, always include this context so the expert can produce correct, production-ready code:

1. **Event source** — What triggers the function? (API Gateway, SQS, S3, EventBridge, DynamoDB Streams, Schedule, etc.)
2. **Environment variables** — What environment variables are defined in the infrastructure resource?
3. **IAM permissions** — What does the function's execution role allow? (policy statements, SAM policy templates, managed policies)
4. **Business logic requirements** — What should the handler do? Be specific about inputs, outputs, and error handling.
5. **Existing handler patterns** — Are there existing handlers in the project? The expert should match their style.

## When to Delegate vs. Write Directly

**Always delegate** when:
- Writing a new Lambda handler from scratch
- Adding business logic to an existing handler
- Writing or updating tests for a handler
- Refactoring handler code (middleware, error handling, logging)
- Integrating AWS Lambda Powertools (Logger, Tracer, Metrics, etc.)

**Exception — write directly** when:
- The handler is a trivial inline function (e.g., CloudFormation custom resource `cfnresponse` handler in a `ZipFile` property, under ~20 lines)
- You are only changing infrastructure configuration (environment variables, memory, timeout) and NOT the handler code itself

## Parallel Delegation

When a task requires **both** infrastructure changes and handler code, delegate in parallel:
1. Write the infrastructure changes yourself (or delegate to the IaC agent)
2. **Simultaneously** use the Task tool to invoke the Lambda expert for the handler code

This is faster than sequential delegation and the two workstreams are independent.
