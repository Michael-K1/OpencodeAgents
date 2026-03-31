---
name: lambda-ts-conventions
description: TypeScript Lambda project conventions extracted from real production codebases. Load this skill before writing any TypeScript Lambda code.
---

# TypeScript Lambda Project Conventions

These conventions are derived from production TypeScript Lambda codebases. **Follow these patterns exactly** when working on TypeScript Lambda projects. If a project has its own AGENTS.md or conventions file, defer to those for project-specific overrides.

---

## 1. Project Structure

```
src/
  @types/            # TypeScript type definitions and type guards
  functions/         # Business logic organized by AWS service domain
    utils/           # AWS service wrappers (singleton clients, retry logic)
    DynamoDB/        # DynamoDB-specific business logic
    S3/              # S3-specific business logic
  lambda/            # Lambda handler entry points (one file per handler)
test/
  testUtils/         # Test utilities: mock factories, setup helpers, assertion helpers
  *.test.mts         # Test files (flat or nested matching source structure)
cloudformation/
  template/          # CloudFormation templates
  conf/              # Per-environment configuration JSON files
    dev/
    test/
    qa/
    prod/
```

**Rules:**
- Lambda handlers live in `src/lambda/` — one file per handler
- Business logic lives in `src/functions/` — organized by domain, NOT by Lambda
- AWS service wrappers live in `src/functions/utils/`
- Types live in `src/@types/`
- Never put business logic in the handler file — the handler only orchestrates

---

## 2. File Extensions and Module System

- **Source files**: `.mts` extension (TypeScript ESM)
- **Import paths**: use `.mjs` extension in imports (TypeScript resolves `.mts` → `.mjs`)
- **Package type**: `"type": "module"` in package.json
- **Module**: ES2022
- **Module resolution**: `bundler`
- **Target**: ES2022

**Path aliases** (from tsconfig.json):
```typescript
import type { FunnelType } from '@/@types/DynamoDB.mjs'     // @/* → src/*
import { getAllOCRKeys } from 'functions/DynamoDB/OCRKeys.mjs' // functions/* → src/functions/*
import type { OCRKeys } from 'types/DynamoDB.mjs'            // types/* → src/@types/*
```

---

## 3. Lambda Handler Pattern

Every Lambda handler follows this exact structure:

```typescript
// 1. Type imports first (top-level type imports)
import type { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda'
import type { SomeType } from '@/@types/SomeType.mjs'

// 2. Value imports
import { APIGWMiddifier } from 'functions/utils/middy.mjs'
import { someBusinessFunction } from 'functions/domain/module.mjs'
import { inspectObject } from 'functions/utils/general.mjs'

// 3. Base handler — contains all logic
const baseHandler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
    // Extract typed parameters from event
    const { param } = event.body as unknown as RequestType
    const { pathParam } = event.pathParameters as { pathParam: string }

    try {
        const result = await someBusinessFunction(param)
        return {
            statusCode: 200,
            body: JSON.stringify(result)
        }
    } catch (error) {
        const err = error as Error
        console.error('[Context] Error description:', inspectObject(err))
        return {
            statusCode: 500,
            body: JSON.stringify({
                error: 'Human-readable error message',
                details: err.message
            })
        }
    }
}

// 4. Export middleware-wrapped handler
export const handler = APIGWMiddifier(baseHandler)
```

**Key rules:**
- `baseHandler` is a `const`, not `function` declaration
- Always type the event: `APIGatewayProxyEvent`, `SQSEvent`, etc.
- Always type the return: `Promise<APIGatewayProxyResult>`, `Promise<void>`, etc.
- Body parsing: use `event.body as unknown as RequestType` (middy parses JSON)
- Path parameters: cast with `event.pathParameters as { name: type }`
- Always wrap with middleware: `APIGWMiddifier` for API Gateway, `SQSMiddifier` for SQS
- Error responses include both `error` (human message) and `details` (Error.message)

---

## 4. Middleware (Middy v6)

Two middleware wrappers in `src/functions/utils/middy.mts`:

### APIGWMiddifier (for API Gateway handlers)
```typescript
export const APIGWMiddifier = (
    baseHandler: (event: APIGatewayProxyEvent, context?: Context) => Promise<APIGatewayProxyResult>
) =>
    middy<APIGatewayProxyEvent, APIGatewayProxyResult>()
        .use([
            httpHeaderNormalizer(),
            httpJsonBodyParser({ disableContentTypeError: true }),
            inputOutputLogger({ omitPaths: ['password', 'Password'], mask: '***MiddyOmitted***' }),
            httpCors({ credentials: true, origins: ['*'] }),
            httpResponseSerializer({
                serializers: [{ regex: /^application\/json$/, serializer: ({ body }) => body }],
                defaultContentType: 'application/json'
            }),
            httpErrorHandler(),
            errorLogger()
        ])
        .handler(baseHandler)
```

### SQSMiddifier (for SQS handlers)
```typescript
export const SQSMiddifier = (baseHandler: (event: SQSEvent) => Promise<void>) =>
    middy<SQSEvent, void>()
        .use([
            inputOutputLogger({ omitPaths: ['password', 'Password'], mask: '***MiddyOmitted***' })
        ])
        .handler(baseHandler)
```

**Rules:**
- Always use the appropriate Middifier — never export a raw handler
- If you need a new event source, create a new Middifier in `middy.mts`
- Sensitive fields in logging: mask passwords and credentials

---

## 5. AWS SDK v3 Patterns

### Singleton Client Pattern
```typescript
let mainClient: S3Client

const getClient = () => {
    if (!mainClient) mainClient = new S3Client({ region: 'eu-central-1' })
    return mainClient
}
```

### Service Wrapper Functions
```typescript
export const getObject = async (param: GetObjectCommandInput, optClient?: S3Client) => {
    const client = optClient ? optClient : getClient()
    console.log('[S3] GET request with params:', inspectObject(param))
    try {
        const response = await client.send(new GetObjectCommand(param))
        console.log('[S3] File retrieved:', inspectObject(response))
        return response
    } catch (error) {
        console.error('[S3] Error:', inspectObject(error))
        throw error
    }
}
```

**Rules:**
- Every SDK client uses singleton pattern with lazy initialization
- Always accept optional client parameter for testability
- Always log before and after SDK calls using `inspectObject()`
- Log prefix pattern: `[ServiceName]` (e.g., `[S3]`, `[DynamoDB]`, `[Bedrock]`)
- Let errors propagate to the handler (throw, don't swallow)

### DynamoDB Generic Request Pattern
```typescript
const genericDynamoRequest = async <T, U>(
    scope: DynamoScopes,
    params: T,
    retries = 0,
    dynamoConfig: DynamoDBClientConfig = { maxAttempts: 3 },
    marshallConfig: TranslateConfig
): Promise<U> => {
    const client = DynamoDBDocumentClient.from(new DynamoDBClient(dynamoConfig), marshallConfig)
    try {
        const response = await client.send(commandDict[scope](params) as Command<...>)
        return response as unknown as U
    } catch (error) {
        if (retries < 3) {
            retries++
            await sleep(300 * retries)
            return await genericDynamoRequest(scope, params, retries, dynamoConfig, marshallConfig)
        }
        throw new Error(`[DynamoDB] Unable to perform ${scope}`)
    } finally {
        bareBonesClient.destroy()
        client.destroy()
    }
}
```

**DynamoDB conventions:**
- Use `DynamoDBDocumentClient` (marshalled), not raw `DynamoDBClient`
- Generic typed request function with command dictionary
- Built-in retry with exponential backoff (300ms × retry number)
- Always destroy clients in `finally` block
- Batch operations handle unprocessed items with individual fallback

---

## 6. Type System

### Type Definitions (`src/@types/`)
```typescript
// Enums for constrained values
export enum KeyType {
    COMMON = 'common',
    POWER = 'power',
    GAS = 'gas'
}

// Domain types with JSDoc comments on key fields
export type OCRKeys = {
    keyId: string       //! Partition key
    keyType: KeyType    //? Sort Key
    friendlyName: string
    dataType: unknown
    description: string
    active: boolean
}
```

### Type Guards (`src/@types/typeChecks.mts`)
```typescript
export const isValidNumber = (value: unknown): value is number => {
    return !isNil(value) && isFinite(+value)
}

export const isValidOCRRecognitionResponse = (data: unknown): data is OCRRecognitionResponse => {
    if (isEmpty(data) || !isObjectLike(data)) return false
    const typedData = data as Partial<OCRRecognitionResponse>
    if (!typedData.common || isEmpty(typedData.common)) return false
    return true
}
```

**Rules:**
- Use `type` for object shapes, `enum` for constrained value sets
- Type guard functions return `value is Type` predicates
- Use `//!` for partition keys, `//?` for sort keys in DynamoDB types
- Use `lodash-es` utilities for type checking (`isNil`, `isEmpty`, `isString`, etc.)
- Import types with `import type` — always top-level, never inline

---

## 7. Import Order

ESLint enforces this strict import order:

```typescript
// 1. Type imports
import type { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda'
import type { OCRRecognitionRequest } from '@/@types/http.mjs'

// 2. Built-in modules
import util from 'node:util'

// 3. External packages
import { isNil } from 'lodash-es'
import { DateTime } from 'luxon'

// 4. Internal modules (path aliases)
import { APIGWMiddifier } from 'functions/utils/middy.mjs'
import { getS3Uri } from 'functions/utils/s3.mjs'

// 5. Parent/sibling modules
import { retrieveActiveArtifact } from '@/functions/S3/OCR-BE.mjs'
```

Enforced by `eslint-plugin-import` with `"import/consistent-type-specifier-style": ["error", "prefer-top-level"]`.

---

## 8. Error Handling

```typescript
// In Lambda handlers:
try {
    const result = await businessFunction()
    return { statusCode: 200, body: JSON.stringify(result) }
} catch (error) {
    const err = error as Error
    console.error('[Context] Error description:', inspectObject(err))
    return {
        statusCode: 500,
        body: JSON.stringify({
            error: 'Human-readable error message',
            details: err.message
        })
    }
}

// In utility functions:
try {
    const response = await client.send(command)
    return response
} catch (error) {
    console.error('[ServiceName] Error:', inspectObject(error))
    throw error  // Propagate to handler
}
```

**Rules:**
- Handlers catch and return HTTP error responses
- Utility functions catch, log, and re-throw
- Always use `inspectObject()` for error logging (uses `util.inspect`)
- Error response shape: `{ error: string, details: string }`
- Cast errors: `const err = error as Error`

---

## 9. Logging

### Powertools Logger (Preferred)

For new code, use `@aws-lambda-powertools/logger` for structured JSON logging. See **Section 15** for full patterns and examples.

```typescript
import { Logger } from '@aws-lambda-powertools/logger'

const logger = new Logger({ serviceName: 'my-service' })

logger.info('Processing request', { orderId, customerId })
logger.error('Failed to process', { error: err.message, orderId })
```

### Legacy Pattern (console.log + inspectObject)

Existing codebases may use `console.log` with `inspectObject()` — this is acceptable for consistency within legacy projects but should not be used in new projects.

```typescript
import { inspectObject } from 'functions/utils/general.mjs'

// inspectObject wraps util.inspect for deep object logging
export const inspectObject = (obj: unknown) => util.inspect(obj, false, null)

// Usage patterns:
console.log('[S3] GET request with params:', inspectObject(param))
console.error('[DynamoDB] Error received:', inspectObject(error))
console.warn('[PaginatedScan] No items found in table', tableName)
```

**Rules:**
- **New projects**: Use Powertools Logger — structured JSON, correlation IDs, log levels, no manual formatting
- **Legacy projects**: Use `console.log` + `inspectObject()` for consistency with existing code
- Always prefix logs with `[Context]` in square brackets (legacy pattern)
- Use `inspectObject()` for any object logging in legacy code (avoids `[Object object]`)
- Log before AND after AWS SDK calls
- Use `console.error` for errors, `console.warn` for warnings, `console.log` for info (legacy)
- Middy `inputOutputLogger` handles input/output logging automatically (legacy); Powertools `injectLambdaContext` with `logEvent: true` replaces this

---

## 10. Testing (Vitest)

### Configuration
```typescript
// vitest.config.ts
export default defineConfig({
    test: {
        globals: true,              // No need to import describe, it, expect
        environment: 'node',
        include: ['test/**/*.test.mts', 'test/**/*.test.ts'],
        coverage: { reporter: ['text', 'html'], reportsDirectory: 'coverage-vitest' },
    },
    resolve: {
        alias: {
            '@': path.resolve(__dirname, './src'),
            functions: path.resolve(__dirname, './src/functions'),
            '@types': path.resolve(__dirname, './src/@types'),
        },
    },
})
```

### Test Structure
```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { createMockKey } from './testUtils/mockFactory.mts'
import { setupOCRTests, createDynamoDBResponses } from './testUtils/setup.mts'
import * as dynamoDBUtils from '../src/functions/utils/dynamodb.mjs'
import * as moduleUnderTest from '../src/functions/DynamoDB/OCRKeys.mts'

const tableName = 'test-table'
const mockItem = createMockKey({ keyId: 'key-1', active: true })

beforeEach(() => {
    process.env.TABLE_NAME = tableName
    vi.resetAllMocks()
})

afterEach(() => {
    vi.restoreAllMocks()
})

describe('Module Name', () => {
    it('does something specific', async () => {
        const dynamoResponses = createDynamoDBResponses()
        const scanSpy = vi.spyOn(dynamoDBUtils, 'scanDynamoTable')
            .mockResolvedValueOnce(dynamoResponses.singleItemResponse(mockItem))

        const result = await moduleUnderTest.getAllItems()
        expect(scanSpy).toHaveBeenCalled()
        expect(result).toEqual([mockItem])
    })
})
```

### Test Utilities Pattern
- **mockFactory.mts**: `createMockItem()` factories with `Partial<Type>` overrides
- **setup.mts**: `setupOCRTests({ setupEnv, mockDateTime })` lifecycle helper
- **assertions.mts**: `assertDynamoDBOperation()` reusable assertion helpers
- **createDynamoDBResponses()**: Factory for mock DynamoDB responses

**Rules:**
- Use `vi.spyOn()` for mocking utility functions, `vi.mock()` for modules
- Mock AWS SDK clients completely — never make real AWS calls
- Use factory functions for mock data — never inline mock objects
- Test file naming: `<module>.test.mts`
- Environment setup/teardown in `beforeEach`/`afterEach`

---

## 11. Code Style

### Prettier
```json
{
    "trailingComma": "none",
    "printWidth": 120,
    "tabWidth": 4,
    "semi": false,
    "singleQuote": true
}
```

### ESLint Key Rules
- `@typescript-eslint/no-unused-vars`: error
- `@typescript-eslint/no-explicit-any`: warn
- `sonarjs/cognitive-complexity`: warn
- `import/order`: enforced with type-first grouping
- `import/consistent-type-specifier-style`: prefer top-level

### Git Hooks (Husky + lint-staged)
- **Pre-commit**: runs `prettier --write` → `eslint --cache --fix` → `tsc --noEmit` on staged `.mts` files
- **Commit-msg**: validates conventional commits via commitlint

---

## 12. Build (esbuild)

```javascript
// esbuild.config.mjs
const entries = readdirSync('src/lambda')
    .filter((file) => file.endsWith('.mts'))
    .map((file) => ({
        entryPoints: [`src/lambda/${file}`],
        outfile: `build/${file.split('.')[0]}/${file.replace(/\.mts$/, '.mjs')}`,
    }))

await Promise.all(entries.map((entry) =>
    build({
        ...entry,
        platform: 'node',
        target: 'node24',
        format: 'esm',
        packages: 'external',   // Dependencies come from Lambda layer
        sourcemap: true,
        bundle: true,
        outExtension: { '.js': '.mjs' },
    })
))
```

**Rules:**
- Auto-discovers handlers from `src/lambda/` — add a new `.mts` file and it builds automatically
- Each handler bundles into its own directory: `build/<handlerName>/<handlerName>.mjs`
- Dependencies are external (loaded from Lambda layer, not bundled)
- Node 24 target, ESM format
- Source maps enabled for debugging
- **Tracer ESM compatibility**: When using `@aws-lambda-powertools/tracer`, add esbuild `banner` option: `import { createRequire } from 'module';const require = createRequire(import.meta.url);` — required because `aws-xray-sdk` is CommonJS

---

## 13. Dependencies

### Runtime (in Lambda layer)
- `@aws-sdk/client-*` v3 — AWS service clients
- `@aws-sdk/lib-dynamodb` — DynamoDB Document Client
- `@aws-sdk/s3-request-presigner` — S3 presigned URLs
- `@aws-lambda-powertools/logger` — Structured JSON logging
- `@aws-lambda-powertools/tracer` — X-Ray tracing
- `@aws-lambda-powertools/metrics` — CloudWatch EMF metrics
- `@aws-lambda-powertools/parameters` — Cached parameter fetching (SSM, Secrets Manager, AppConfig)
- `@aws-lambda-powertools/idempotency` — DynamoDB-backed idempotency
- `@aws-lambda-powertools/batch` — Partial failure handling (SQS, Kinesis, DynamoDB Streams)
- `@aws-lambda-powertools/parser` — Zod-based event parsing
- `@middy/core` v6 + middleware packages
- `lodash-es` — utility functions (prefer over manual implementations)
- `luxon` — date/time handling (never use raw Date)
- `uuid` — ID generation

### Dev
- `typescript` 5.x with strict mode
- `vitest` 3.x with `@vitest/ui`
- `esbuild` — bundler
- `eslint` 9.x with flat config (`.mts`)
- `prettier` 3.x
- `husky` + `lint-staged` + `commitlint`
- `@types/aws-lambda` — Lambda event types

---

## 14. Environment and Node Version

- **Node.js**: 24.x (pinned via Volta)
- **npm**: 11.x (pinned via Volta)
- **Runtime**: `nodejs24.x` Lambda runtime
- **Region**: `eu-central-1` (default in SDK clients)

---

## 15. AWS Lambda Powertools for TypeScript

Powertools provides a suite of utilities that implement AWS best practices for Lambda functions. All utilities use **Middy v6 middleware** pattern and compose natively with the existing Middifier architecture.

### Core Packages

| Package | Purpose | Middy Middleware |
|---------|---------|-----------------|
| `@aws-lambda-powertools/logger` | Structured JSON logging | `injectLambdaContext` |
| `@aws-lambda-powertools/tracer` | X-Ray tracing | `captureLambdaHandler` |
| `@aws-lambda-powertools/metrics` | CloudWatch EMF metrics | `logMetrics` |
| `@aws-lambda-powertools/parameters` | SSM/Secrets/AppConfig caching | N/A (direct calls) |
| `@aws-lambda-powertools/idempotency` | DynamoDB-backed idempotency | `makeHandlerIdempotent` |
| `@aws-lambda-powertools/batch` | Partial failure handling | N/A (function call) |
| `@aws-lambda-powertools/parser` | Zod-based event parsing | N/A (used with batch) |

### Environment Variables

Set these in your Lambda function configuration (CloudFormation, SAM, Serverless, Terraform):

```yaml
Environment:
  Variables:
    POWERTOOLS_SERVICE_NAME: my-service        # Required — shared across all utilities
    POWERTOOLS_LOG_LEVEL: INFO                 # DEBUG, INFO, WARN, ERROR, CRITICAL, SILENT
    POWERTOOLS_METRICS_NAMESPACE: MyApp        # CloudWatch metrics namespace
    POWERTOOLS_DEV: "false"                    # Pretty-print logs in dev (set "true" locally)
    POWERTOOLS_TRACE_ENABLED: "true"           # Enable/disable X-Ray tracing
```

### Logger

Replaces `console.log` + `inspectObject()` with structured JSON output including correlation IDs, Lambda context, and log levels.

```typescript
import { Logger } from '@aws-lambda-powertools/logger'
import { injectLambdaContext } from '@aws-lambda-powertools/logger/middleware'

// Module-scope — persists across warm invocations
const logger = new Logger({ serviceName: 'my-service' })

// In Middifier chain:
middy<APIGatewayProxyEvent, APIGatewayProxyResult>()
    .use(injectLambdaContext(logger, { logEvent: true }))
    // ... other middleware
    .handler(baseHandler)

// Usage in handler/business logic:
logger.info('Processing request', { orderId, customerId })
logger.error('Failed to process', { error: err.message, orderId })
logger.warn('Approaching rate limit', { currentRate, threshold })
logger.debug('DynamoDB response', { response })

// Child loggers for service modules:
const childLogger = logger.createChild({ persistentLogAttributes: { module: 'dynamodb' } })

// Log buffering — buffer DEBUG/INFO logs, flush on error:
const logger = new Logger({ logLevel: 'WARN', logBuffering: { enabled: true, flushOnErrorLog: true } })
logger.debug('This is buffered and only flushed if an error occurs')
logger.error('Error occurred!') // Flushes all buffered logs

// Correlation IDs — automatically injected from event headers (x-correlation-id):
logger.info('Request received') // Includes correlation_id in structured output
```

**Logger rules:**
- Instantiate at module scope, never inside the handler
- Use `injectLambdaContext` middleware to add Lambda context to all logs
- Use `logEvent: true` in non-production for debugging (replaces `inputOutputLogger`)
- Use child loggers in service modules with `persistentLogAttributes`
- Use log buffering in production to reduce log volume while preserving debug info on errors

### Tracer

Instruments Lambda functions and AWS SDK clients with X-Ray tracing.

```typescript
import { Tracer } from '@aws-lambda-powertools/tracer'
import { captureLambdaHandler } from '@aws-lambda-powertools/tracer/middleware'

// Module-scope
const tracer = new Tracer({ serviceName: 'my-service' })

// Patch AWS SDK v3 clients for automatic trace capture:
import { S3Client } from '@aws-sdk/client-s3'
const s3Client = tracer.captureAWSv3Client(new S3Client({ region: 'eu-central-1' }))

// In Middifier chain:
middy<APIGatewayProxyEvent, APIGatewayProxyResult>()
    .use(captureLambdaHandler(tracer))
    // ... other middleware
    .handler(baseHandler)

// Manual subsegments for custom tracing:
const subsegment = tracer.getSegment()?.addNewSubsegment('## processOrder')
try {
    const result = await processOrder(orderId)
    subsegment?.addAnnotation('orderId', orderId)
    subsegment?.addMetadata('result', result)
    return result
} catch (error) {
    subsegment?.addError(error as Error)
    throw error
} finally {
    subsegment?.close()
}
```

**Tracer rules:**
- Instantiate at module scope, never inside the handler
- Use `captureAWSv3Client()` to patch SDK clients — do not import `aws-xray-sdk` directly
- Use annotations for filterable data (strings, numbers, booleans only)
- Use metadata for non-filterable rich data (objects, arrays)
- **ESM compatibility**: Add esbuild banner for `aws-xray-sdk` CommonJS: `import { createRequire } from 'module';const require = createRequire(import.meta.url);`

### Metrics

Publishes CloudWatch metrics using Embedded Metric Format (EMF) — zero-cost metric publishing.

```typescript
import { Metrics, MetricUnit } from '@aws-lambda-powertools/metrics'
import { logMetrics } from '@aws-lambda-powertools/metrics/middleware'

// Module-scope
const metrics = new Metrics({
    namespace: 'MyApp',
    serviceName: 'my-service',
    defaultDimensions: { environment: process.env.STAGE ?? 'dev' }
})

// In Middifier chain:
middy<APIGatewayProxyEvent, APIGatewayProxyResult>()
    .use(logMetrics(metrics, { captureColdStartMetric: true }))
    // ... other middleware
    .handler(baseHandler)

// Usage in handler/business logic:
metrics.addMetric('OrderProcessed', MetricUnit.Count, 1)
metrics.addMetric('ProcessingTime', MetricUnit.Milliseconds, elapsed)
metrics.addDimension('PaymentMethod', 'credit_card')

// High-resolution metrics (1-second resolution):
metrics.addMetric('ApiLatency', MetricUnit.Milliseconds, latency)
```

**Metrics rules:**
- Instantiate at module scope, never inside the handler
- Use `logMetrics` middleware — it handles flushing metrics at the end of each invocation
- Always set `captureColdStartMetric: true` for operational visibility
- Use `defaultDimensions` for environment/stage — avoids repetition
- Dimensions are limited to 29 per metric (CloudWatch limit)

### Parameters

Cached parameter fetching from SSM Parameter Store, Secrets Manager, AppConfig, and DynamoDB.

```typescript
import { getParameter, getParameters } from '@aws-lambda-powertools/parameters/ssm'
import { getSecret } from '@aws-lambda-powertools/parameters/secrets'
import { getAppConfig } from '@aws-lambda-powertools/parameters/appconfig'

// SSM Parameter Store — cached for 5 seconds by default:
const apiEndpoint = await getParameter('/my-app/api-endpoint')
const dbConfig = await getParameter('/my-app/db-config', { transform: 'json' })

// Fetch multiple parameters by path:
const allParams = await getParameters('/my-app/')

// Secrets Manager:
const dbPassword = await getSecret('my-app/db-password')
const apiKey = await getSecret('my-app/api-key', { transform: 'json' })

// AppConfig:
const featureFlags = await getAppConfig('my-app', 'production', 'feature-flags', {
    transform: 'json'
})

// Cache control:
const fresh = await getParameter('/my-app/config', { forceFetch: true })
const longCache = await getParameter('/my-app/config', { maxAge: 300 }) // 5 minutes
```

**Parameters rules:**
- Default cache TTL is 5 seconds — override with `maxAge` for stable values
- Use `forceFetch: true` only when you need the absolute latest value
- Use `transform: 'json'` for structured values stored as JSON strings
- Fetch at handler invocation time, not at module scope (values change at runtime)

### Idempotency

DynamoDB-backed idempotency to prevent duplicate processing of the same event.

```typescript
import { IdempotencyConfig } from '@aws-lambda-powertools/idempotency'
import { makeHandlerIdempotent } from '@aws-lambda-powertools/idempotency/middleware'
import { DynamoDBPersistenceLayer } from '@aws-lambda-powertools/idempotency/dynamodb'

// Module-scope
const persistenceStore = new DynamoDBPersistenceLayer({
    tableName: process.env.IDEMPOTENCY_TABLE ?? 'idempotency-table'
})
const idempotencyConfig = new IdempotencyConfig({
    eventKeyJmesPath: 'body.orderId',  // Extract idempotency key from event
    expiresAfterSeconds: 3600          // 1-hour TTL (default)
})

// In Middifier chain:
middy<APIGatewayProxyEvent, APIGatewayProxyResult>()
    .use(makeHandlerIdempotent({ persistenceStore, config: idempotencyConfig }))
    // ... other middleware
    .handler(baseHandler)
```

**Idempotency rules:**
- Use `eventKeyJmesPath` to extract only the relevant fields from the event for the idempotency key
- Set `expiresAfterSeconds` based on your business requirements (default: 3600)
- The DynamoDB table needs `id` (String) as partition key — create via IaC
- Idempotency works per-function — different handlers should use different table or key expressions
- Place `makeHandlerIdempotent` middleware **after** parsing/validation middleware so the event is already parsed

### Batch Processing

Partial failure handling for SQS, Kinesis, and DynamoDB Streams — reports individual item failures instead of failing the entire batch.

```typescript
import { processPartialResponse, SqsFifoPartialProcessor } from '@aws-lambda-powertools/batch'
import type { SQSHandler, SQSRecord } from 'aws-lambda'

// Standard SQS:
import { BatchProcessor, EventType } from '@aws-lambda-powertools/batch'

const processor = new BatchProcessor(EventType.SQS)

const recordHandler = async (record: SQSRecord): Promise<void> => {
    const payload = JSON.parse(record.body) as OrderEvent
    await processOrder(payload)
}

const baseHandler: SQSHandler = async (event, context) => {
    return processPartialResponse(event, recordHandler, processor, { context })
}

export const handler = SQSMiddifier(baseHandler)

// SQS FIFO — preserves message group ordering:
const fifoProcessor = new SqsFifoPartialProcessor()

const fifoHandler: SQSHandler = async (event, context) => {
    return processPartialResponse(event, recordHandler, fifoProcessor, { context })
}
```

**Batch rules:**
- Always use `processPartialResponse` — never manually iterate SQS/Kinesis records
- For FIFO queues, use `SqsFifoPartialProcessor` to preserve message group ordering
- Set `ReportBatchItemFailures` in the Lambda event source mapping configuration
- The processor returns `batchItemFailures` response automatically
- Test with both successful and failing records to verify partial failure behavior

### Composing Powertools with Existing Middifiers

Powertools middleware composes natively with Middy v6. Update Middifiers to include Powertools:

```typescript
import middy from '@middy/core'
import httpHeaderNormalizer from '@middy/http-header-normalizer'
import httpJsonBodyParser from '@middy/http-json-body-parser'
import httpCors from '@middy/http-cors'
import httpResponseSerializer from '@middy/http-response-serializer'
import httpErrorHandler from '@middy/http-error-handler'
import errorLogger from '@middy/error-logger'
import inputOutputLogger from '@middy/input-output-logger'

import type { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda'

import { Logger } from '@aws-lambda-powertools/logger'
import { injectLambdaContext } from '@aws-lambda-powertools/logger/middleware'
import { Tracer } from '@aws-lambda-powertools/tracer'
import { captureLambdaHandler } from '@aws-lambda-powertools/tracer/middleware'
import { Metrics } from '@aws-lambda-powertools/metrics'
import { logMetrics } from '@aws-lambda-powertools/metrics/middleware'

// Shared instances — module-scope
const logger = new Logger()
const tracer = new Tracer()
const metrics = new Metrics()

export const APIGWMiddifier = (
    baseHandler: (event: APIGatewayProxyEvent, context?: Context) => Promise<APIGatewayProxyResult>
) =>
    middy<APIGatewayProxyEvent, APIGatewayProxyResult>()
        .use(injectLambdaContext(logger, { logEvent: true }))
        .use(captureLambdaHandler(tracer))
        .use(logMetrics(metrics, { captureColdStartMetric: true }))
        .use([
            httpHeaderNormalizer(),
            httpJsonBodyParser({ disableContentTypeError: true }),
            httpCors({ credentials: true, origins: ['*'] }),
            httpResponseSerializer({
                serializers: [{ regex: /^application\/json$/, serializer: ({ body }) => body }],
                defaultContentType: 'application/json'
            }),
            httpErrorHandler(),
            errorLogger()
        ])
        .handler(baseHandler)
```

**Composition rules:**
- Powertools middleware goes **first** in the chain (before HTTP middleware)
- Order: `injectLambdaContext` → `captureLambdaHandler` → `logMetrics` → existing middleware
- Powertools `injectLambdaContext` with `logEvent: true` replaces `inputOutputLogger` for API Gateway handlers — remove `inputOutputLogger` to avoid duplicate logging
- For SQS handlers, keep `inputOutputLogger` alongside Powertools if you need raw event logging

### Testing with Powertools

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest'

// Mock Powertools before importing handler
vi.mock('@aws-lambda-powertools/logger', () => ({
    Logger: vi.fn().mockImplementation(() => ({
        info: vi.fn(),
        error: vi.fn(),
        warn: vi.fn(),
        debug: vi.fn(),
        createChild: vi.fn().mockReturnThis(),
        addContext: vi.fn()
    }))
}))

vi.mock('@aws-lambda-powertools/tracer', () => ({
    Tracer: vi.fn().mockImplementation(() => ({
        getSegment: vi.fn(),
        captureAWSv3Client: vi.fn((client) => client),
        addAnnotation: vi.fn(),
        addMetadata: vi.fn()
    }))
}))

vi.mock('@aws-lambda-powertools/metrics', () => ({
    Metrics: vi.fn().mockImplementation(() => ({
        addMetric: vi.fn(),
        addDimension: vi.fn(),
        publishStoredMetrics: vi.fn()
    })),
    MetricUnit: { Count: 'Count', Milliseconds: 'Milliseconds' }
}))

// Mock Powertools middleware as passthrough
vi.mock('@aws-lambda-powertools/logger/middleware', () => ({
    injectLambdaContext: vi.fn().mockReturnValue({ before: vi.fn(), after: vi.fn() })
}))
vi.mock('@aws-lambda-powertools/tracer/middleware', () => ({
    captureLambdaHandler: vi.fn().mockReturnValue({ before: vi.fn(), after: vi.fn() })
}))
vi.mock('@aws-lambda-powertools/metrics/middleware', () => ({
    logMetrics: vi.fn().mockReturnValue({ before: vi.fn(), after: vi.fn() })
}))
```

**Testing rules:**
- Mock Powertools utilities before importing the handler module
- Mock middleware as passthrough objects with `before`/`after` functions
- Use `captureAWSv3Client` mock that returns the original client (pass-through)
- Verify logger calls for important log statements (`logger.info`, `logger.error`)
- Never rely on Powertools behavior in unit tests — test your business logic, not the framework

---

## 16. CloudFormation Conventions

- Template in `cloudformation/template/infrastructure.yaml`
- Per-environment config in `cloudformation/conf/<env>/infrastructure_configuration.json`
- Environments: dev, test, qa, perf, train, prod
- `IsNotProduction` condition restricts write operations in prod
- Lambda functions use shared execution role
- Dependencies deployed as Lambda layers (`layers/nodejs/`)
