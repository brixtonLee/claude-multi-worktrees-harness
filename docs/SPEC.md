# Project Specification — Hawkeye Alert Collector API

> **This is the source of truth.** When implementation diverges from this doc,
> this doc wins unless explicitly updated. Claude: re-read this file before
> starting any new task and after every 3 completed subtasks.

---

## Project Overview

VSH Alert Collector API is a .NET 10 ASP.NET Core Web API that serves as the central hub for alert event collection, processing, and management. It provides REST endpoints for managing alert rules, severity rules, suppression rules, notification channels, and alert instances.

---

## Architecture

### Solution Structure (Clean Architecture)

The solution follows Clean Architecture with four layers:

1. **VSH.AlertCollectorAPI** (API Layer)
   - ASP.NET Core Minimal APIs entry point
   - Endpoint groups in `Endpoints/` directory
   - Middleware (global exception handling, CORS)
   - Dependency injection setup
   - Program.cs with startup logic

2. **VSH.AlertCollectorAPI.Application** (Application Layer)
   - `FormModels/` - Request DTOs with validation
   - `Dtos/` - Response DTOs (sealed records)
   - `Dtos/Internal/` - Projection DTOs for performance optimization
   - `Interfaces/` - Service and repository interfaces
   - Minimal business logic (validation and orchestration only)

3. **VSH.AlertCollectorAPI.Infrastructure** (Infrastructure Layer)
   - `Databases/Persistence/` - EF Core DbContext
   - `Databases/Repositories/` - Repository implementations
   - `Services/` - Service implementations
   - `Background/` - Background services (auto-resolution, health checks)
   - `StartUp/` - Dependency injection configuration

4. **VSH.AlertCollectorAPI.Domain** (Domain Layer)
   - `Entities/` - Core business entities
   - `Enums/` - Domain enums with custom attributes
   - No external dependencies (except essential types)

### Key Patterns

#### Repository Pattern
- **Repositories** handle ONLY data model changes (CRUD operations)
- Repositories should NOT contain business logic or orchestration
- Each repository implements a specific entity interface (e.g., `IAlertEventRepository`)
- Repository interfaces defined in `Application/Interfaces/Repositories/`
- Implementations in `Infrastructure/Databases/Repositories/`

#### Unit of Work Pattern
- **IUnitOfWork** provides ONLY transaction management methods:
  - `SaveChangesAsync()` - Persist changes to database
  - `BeginTransactionAsync()` - Start a transaction
  - `CommitTransactionAsync()` - Commit transaction
  - `RollbackTransactionAsync()` - Rollback transaction
- **DO NOT** expose repository properties through IUnitOfWork
- Repositories are injected directly into services/use cases/handlers

#### Service Pattern
- **Orchestration layer** - Services contain business logic
- Inject `IUnitOfWork` for transaction management
- Inject individual `IRepository` interfaces as needed
- Example:
  ```csharp
  public class AlertEventService
  {
      private readonly IUnitOfWork _unitOfWork;
      private readonly IAlertEventRepository _eventRepo;
      private readonly IAlertRuleRepository _ruleRepo;

      public AlertEventService(
          IUnitOfWork unitOfWork,
          IAlertEventRepository eventRepo,
          IAlertRuleRepository ruleRepo)
      {
          _unitOfWork = unitOfWork;
          _eventRepo = eventRepo;
          _ruleRepo = ruleRepo;
      }

      public async Task ProcessAsync(...)
      {
          await _unitOfWork.BeginTransactionAsync();
          try
          {
              // Business logic using repositories
              await _unitOfWork.SaveChangesAsync();
              await _unitOfWork.CommitTransactionAsync();
          }
          catch
          {
              await _unitOfWork.RollbackTransactionAsync();
              throw;
          }
      }
  }
  ```

#### Endpoint Pattern (Minimal APIs)
All endpoints use **extension methods** in `Endpoints/` directory:
- `MapAlertEventEndpoints()` - Alert event CRUD and filtering
- `MapAlertRuleEndpoints()` - Alert rule management
- `MapSeverityRuleEndpoints()` - Severity rule management
- `MapSuppressionRuleEndpoints()` - Suppression rule management
- `MapAlertInstanceEndpoints()` - Alert instance queries
- `MapNotificationChannelEndpoints()` - Notification channel management
- `MapNotificationLogEndpoints()` - Notification log queries
- `MapWebSocketEndpoints()` - Real-time WebSocket subscriptions
- `MapSummarizationEndpoints()` - Alert event summarization

---

## Technology Stack

- **.NET 10** (SDK 10.0.100)
- **ASP.NET Core** - Minimal APIs
- **Entity Framework Core 10** - ORM
- **PostgreSQL with TimescaleDB** - Time-series database
- **Serilog** - Structured logging (console + file in Development)
- **Swagger/OpenAPI** - API documentation (Development only)

---

## Database Configuration

### Connection Strings
Configure in `appsettings.json` or environment variables:
```json
{
  "ConnectionStrings": {
    "AlertDatabase": "Host=postgres;Port=5432;Database=hawkeye_alerts;Username=admin;Password=postgres"
  }
}
```

### Auto-Migration
Controlled by `Database:AutoMigrate` setting (default: true):
```json
{
  "Database": {
    "AutoMigrate": true
  }
}
```

### Important Database Features
- **TimescaleDB** extension for time-series data on `alert_events` table
- **PostgreSQL NOTIFY trigger** on `alert_events` table fires on insert (handled by separate listener service)
- **Unique constraint** on `AlertEvent.EventId` prevents duplicate event ingestion
- **Performance indexes** on correlation keys, foreign keys, and commonly filtered columns

---

## Key Features

### 1. Severity Rules System
Dynamic severity assignment using expression evaluation:
- **Expression Validation**: `ISeverityRuleExpressionValidator` validates rule expressions before persistence
- **Expression Evaluation**: `ExpressionEvaluatorService` evaluates dynamic expressions against alert events
- **Example Generation**: `SeverityRuleExampleService` provides sample data for rule testing
- Rule expressions support filtering and severity assignment based on alert event properties
- Fields defined in `alert_severity_rule_fields` table, conditions in `alert_severity_rule_conditions`

#### Calculated Fields
Severity rules support **calculated fields** (FieldSource.Calculated) in addition to database-sourced fields (FieldSource.Source):

**Current Calculated Fields:**
- `duration` - Time elapsed since alert started (seconds), FieldType.Duration
- `brand` - Server brand extracted from alert event, FieldType.String, case-sensitive wildcard matching
- `servertype` - Server type (USD/USC) from ExternalServerMapping, FieldType.String, defaults to "USD" if null/not found

**Adding New Calculated Fields - Synchronization Checklist:**

When adding a new calculated field, update these locations (in order):

1. **Core Calculation Logic** (`VSH.AlertCollectorAPI.Infrastructure/Services/SeverityRules/FieldExtractorService.cs`):
   - Add to `CalculateValueAsync()` switch statement (line ~60-66)
   - Add private calculation method (sync or async depending on requirements)
   - Inject dependencies if database lookups needed

2. **Validation Layer** (`VSH.AlertCollectorAPI.Infrastructure/Services/SeverityRules/FieldValidatorService.cs`):
   - Add field name to `ValidCalculatedFieldSourceKeys` HashSet (line ~21-26)

3. **API Endpoint** (`VSH.AlertCollectorAPI/Endpoints/Events/AlertEventLabelsAndValuesEndpoints.cs`):
   - Add to calculated fields list in `GetLabelsAndValuesByEventId()` (line ~50-66)
   - Use appropriate collection: `eventLabelResponses` (String) or `valueLabelResponses` (Number/Duration)

4. **Documentation** - Update XML comments in:
   - `IFieldValidator.cs` - Update accepted values list
   - `IFieldExtractor.cs` - Add to supported calculated fields list

5. **Special Cases (Optional)**:
   - **Case-sensitive wildcard**: Update `ConditionMatcherService.cs` (line ~136-138) if field requires case-sensitive matching
   - **Database dependencies**: Inject required repositories in `FieldExtractorService` constructor

**Verification Checklist:**
- Calculation logic implemented
- Validation whitelist updated
- API endpoint exposes field
- Documentation updated
- Special matching configured (if needed)
- Dependencies injected (if needed)

**Example - Adding "environment" field:**
```csharp
// 1. FieldExtractorService.cs - Add to switch and method
"environment" => CalculateEnvironment(unifiedEvent),

private string CalculateEnvironment(UnifiedEvent unifiedEvent)
{
    return unifiedEvent.Labels.GetValueOrDefault("env") ?? "unknown";
}

// 2. FieldValidatorService.cs - Add to HashSet
"duration", "brand", "servertype", "environment"

// 3. AlertEventLabelsAndValuesEndpoints.cs - Add to response
new AlertEventLabelResponse(
    LabelKey: "environment",
    LabelValue: null,
    Type: FieldType.String.ToString(),
    FieldType: FieldType.String,
    FieldSource: FieldSource.Calculated.ToString())

// 4. Update docs - IFieldValidator.cs
/// Accepts: "duration", "brand", "servertype", "environment" (case-insensitive).
```

### 2. Alert Rule Matching
Alert rules use **metric ID pattern matching**:
- Format: `{GrafanaFolder}:{Category}:{AlertName}:*`
- Example: `"Prod Monitoring:performance:MT5 Server Memory Alert:*"`
- Sender key pattern: `{alert_type}:{application}:{...tags}:{server}:{...}` (supports wildcards)
- Severity matching: Array of allowed severities
- Recovery detection: Status `"resolved"` → `IsRecoveryEvent = true`

### 3. Suppression Rules
Time-based and pattern-based alert suppression:
- Suppress alerts matching specific patterns during maintenance windows
- Schedule-based suppression with `SuppressionRuleSchedule` entities
- Supports regex patterns for flexible matching

### 4. Notification Channels
Multi-channel notification delivery:
- Lark (Feishu) bot integration
- Email notifications
- Webhook delivery
- Extensible for additional channels

### 5. Auto-Resolution
Background service for automatic alert resolution:
- **Service**: `AutoResolveRecoveryBackgroundService`
- **Configuration**: `AutoResolveTimeoutSettings` in appsettings.json
- Checks for timed-out alerts and recovery events
- Configurable check interval and batch size

### 6. Real-Time WebSocket Subscriptions
WebSocket endpoints for real-time alert updates:
- Subscribe to alert instance updates
- Subscribe to notification log updates
- Automatic connection management with keep-alive

---

## Performance Requirements

See `PERFORMANCE_OPTIMIZATIONS.md` for detailed performance patterns. Key principles:

### 1. AsNoTracking for Read Operations
Always use `AsNoTracking()` for read-only queries:
```csharp
// Good
var events = await _dbSet
    .AsNoTracking()
    .Where(e => e.IsProcessed == false)
    .ToListAsync();

// Bad - wastes memory on change tracking
var events = await _dbSet
    .Where(e => e.IsProcessed == false)
    .ToListAsync();
```

### 2. Projection DTOs for Pagination
Use projection DTOs instead of loading full entity graphs:
```csharp
// Good - only fetch required fields
var instances = await _dbSet
    .AsNoTracking()
    .Select(ai => new AlertInstanceProjection(
        Id: ai.Id,
        CorrelationKey: ai.CorrelationKey,
        AlertRuleName: ai.AlertRule.RuleName  // Projection
    ))
    .ToListAsync();

// Bad - loads full entity graphs
var instances = await _dbSet
    .Include(ai => ai.AlertRule)
    .Include(ai => ai.AlertInstanceLogs)
    .ToListAsync();
```

### 3. SQL-Side Aggregations
Prevent N+1 queries by using SQL subqueries instead of client-side collection navigation:
```csharp
// Good - single SQL query with subquery
LatestLogStatus = _context.AlertInstanceLogs
    .Where(log => log.AlertInstanceId == alertInstance.Id)
    .OrderByDescending(log => log.CreatedAt)
    .Select(log => log.Status)
    .FirstOrDefault()

// Bad - N+1 query problem
LatestLog = alertInstance.AlertInstanceLogs
    .OrderByDescending(log => log.CreatedAt)
    .FirstOrDefault()
```

### 4. Order in SQL, Not Memory
Order collections in SQL using `.Include()` pattern:
```csharp
// Good - PostgreSQL handles sorting with indexes
.Include(ai => ai.AlertInstanceLogs.OrderBy(l => l.CreatedAt))

// Bad - sorting happens in C# after data loaded
.Include(ai => ai.AlertInstanceLogs)
// ... then sorting in memory
```

### 5. Create Indexes Strategically
Always create indexes for:
- Foreign keys used in joins
- Columns used in WHERE clauses
- Columns used in ORDER BY
- Composite indexes for common query patterns

---

## Configuration Reference

### Seeding Configuration
```json
{
  "Seeding": {
    "SeedAlertRulesOnStartup": false,
    "SeedNotificationChannelsOnStartup": false,
    "SeedSuppressionRulesOnStartup": false
  }
}
```

### Auto-Resolution Configuration
```json
{
  "AutoResolveTimeoutSettings": {
    "CheckIntervalSeconds": 60,
    "BatchSize": 100
  }
}
```

### Kafka Consumer Configuration
```json
{
  "EnableKafkaConsumers": true,
  "KafkaConsumerSettings": {
    "EnableManualCommit": false
  },
  "DefaultKafkaBroker": {
    "BrokerAddress": "kafka:9092",
    "ConsumerGroup": "alert-collector-group",
    "Topics": [
      {
        "User": "GRAFANA",
        "TopicName": "vsh.grafana_monitoring.mt_alert.v1"
      }
    ]
  }
}
```

### Lark Bot Configuration
```json
{
  "LarkBotConfig": {
    "AppId": "cli_xxxxx",
    "AppSecret": "xxxxx",
    "Url": "https://open.larksuite.com/open-apis/",
    "GroupId": "oc_xxxxx"
  }
}
```

---

## Implementation Details

### Generic Repository Upsert Pattern
The `GenericRepository<T>.AddAsync` method implements **upsert logic**:
- Checks if entity has default primary key (0 for `long`/`int`) → INSERT
- If primary key provided, looks up existing entity → UPDATE if exists, INSERT if not
- **Limitation**: Only handles primary key uniqueness, not other unique constraints (e.g., `EventId`)

### Event ID Generation
- `EventId` generated from `Fingerprint + StartsAt` timestamp
- Creates unique constraint for Grafana alerts
- Prevents duplicate event ingestion

### Mapper Services
All entity-to-DTO mapping handled by dedicated mapper services:
- Interface in `Application/Interfaces/`
- Implementation in `Infrastructure/Services/`
- Example: `IAlertInstanceMapper` → `AlertInstanceMapperService`

### Background Services
Registered as `IHostedService` in `DependencyInjection.cs`:
- `AutoResolveRecoveryBackgroundService` - Auto-resolution checks
- Proper cancellation token handling
- Graceful shutdown support
