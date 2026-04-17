# Sprint 005 Plan — Severity Rule Audit Notifications via Lark

## Task: Audit Notifications for Severity Rule CRUD Operations
**Complexity:** medium
**Scope:** Implement audit notification pipeline for severity rule mutations (Create/Update/Delete/Enable/Disable). Sends Lark card messages to a dedicated audit channel. No database audit table — notification-only. IN: all 5 mutation operations. OUT: read operations, backtesting, reprocessing.
**Approach:** Implement the existing unused ISeverityRuleAuditNotification interface with a Lark-backed service. Add fire-and-forget audit calls in SeverityRuleCommandService after each successful mutation. Use Audit-keyed Lark services following the existing Duplicate-keyed pattern.

### Subtasks
- [x] 1. Create snapshot mapper + card builder — layer: Application+Infrastructure — files: `Application/Helpers/SeverityRuleAuditSnapshotMapper.cs` (create), `Infrastructure/Notifications/Lark/Utilities/LarkAuditCardBuilder.cs` (create) — parallel-group: A — check-profile: service
- [x] 2. Create audit notification service + config + DI registration — layer: Infrastructure — files: `Infrastructure/Services/SeverityRules/SeverityRuleAuditNotificationService.cs` (create), `VSH.AlertCollectorAPI/appsettings.json` (modify L49-55), `Infrastructure/StartUp/DependencyInjection.cs` (modify L131-163) — parallel-group: A — check-profile: service
- [x] 3. Integrate audit calls into SeverityRuleCommandService — layer: Infrastructure — files: `Infrastructure/Services/SeverityRules/SeverityRuleCommandService.cs` (modify L60-631) — parallel-group: sequential — check-profile: service

### Key Details

**Existing scaffolding (reuse as-is):**
- `ISeverityRuleAuditNotification` interface at `Application/Interfaces/SeverityRules/ISeverityRuleAuditNotification.cs` — single method: `SendAuditNotificationAsync(SeverityRuleAuditEventDto, CancellationToken)`
- `SeverityRuleAuditEventDto` at `Application/Dtos/Audit/SeverityRuleAuditEventDto.cs` — `SeverityRuleAuditAction` enum (Created/Updated/Deleted/Enabled/Disabled), `SeverityRuleAuditSnapshotDto` record, `SeverityRuleAuditEventDto` record

**Snapshot mapper (`SeverityRuleAuditSnapshotMapper`):**
- `FromResponse(AlertSeverityRuleDetailsResponse)` — maps: Id, RuleName, Description, SeverityRuleType, SeverityMappingMode, Expression, EventTitle, MatchSource, IsEnabled, Fields.Count, SeverityMapping.Count
- `FromEntity(AlertSeverityRule)` — maps: Id, RuleName, Description, SeverityRuleType.ToString(), SeverityMappingMode.ToString(), ScoreFormula, EventTitles.FirstOrDefault(), MatchSource.ToString(), IsEnabled, Fields?.Count ?? 0, SeverityMappings?.Count ?? 0

**Card builder (`LarkAuditCardBuilder`):**
- Follow `LarkRoutingCardBuilder` pattern: static class, constants for tag names, single public BuildAuditCard method
- Header colors: Created=blue, Updated=orange, Deleted=red, Enabled=green, Disabled=grey
- Body sections: Action type, ActionBy, Timestamp, then rule snapshot (ID, RuleName, EventTitle, MatchSource, RuleType, MappingMode, Expression, IsEnabled, FieldCount, MappingCount)
- For Updated: show Before section, then `---` divider, then After section
- Reference: `LarkSendCardMessageRequest(ChatId, MsgType: "interactive", Card: LarkCard(Config, Header, Elements[]))` — use LarkCardElement with Tag="div", Text with Tag="lark_md"

**Audit notification service (`SeverityRuleAuditNotificationService`):**
- Constructor: `ILarkNotification larkNotification`, `string chatId`, `ILogger<SeverityRuleAuditNotificationService>`
- `SendAuditNotificationAsync`: builds card via `LarkAuditCardBuilder.BuildAuditCard(auditEvent, _chatId)`, sends via `_larkNotification.SendCardMessageAsync(cardMessage, cancellationToken)`, logs result. Catches ALL exceptions — never throws.

**Config (`appsettings.json`):**
- Add `"AuditLarkBot"` section after `DuplicateLarkBot` (same structure as LarkBotConfig: AppId, AppSecret, Url, GroupId)
- Temporarily same values as main LarkBotConfig

**DI registration (`DependencyInjection.cs`):**
- `services.Configure<LarkBotConfig>("Audit", configuration.GetSection("AuditLarkBot"));`
- Keyed ILarkAuth("Audit") with fallback — same factory pattern as "Duplicate" (lines 141-151)
- Keyed ILarkNotification("Audit") with fallback — same pattern as lines 153-163
- `services.AddScoped<ISeverityRuleAuditNotification>(sp => { ... })` — factory resolves Audit-keyed ILarkNotification + IOptionsSnapshot<LarkBotConfig>.Get("Audit") for GroupId

**SeverityRuleCommandService integration:**
- Add `IServiceScopeFactory _serviceScopeFactory` constructor parameter (line 68-85 area)
- Fire-and-forget pattern for all 5 operations:
  ```
  _ = Task.Run(async () => {
      using var scope = _serviceScopeFactory.CreateScope();
      var auditService = scope.ServiceProvider.GetRequiredService<ISeverityRuleAuditNotification>();
      await auditService.SendAuditNotificationAsync(auditEvent);
  });
  ```
- **CreateRuleAsync**: after `ExecuteInTransactionAsync` returns, pattern match `is Result<...>.Success success`, snapshot from `SeverityRuleAuditSnapshotMapper.FromResponse(success.Value)`, Before=null, ActionBy=request.CreatedBy
- **UpdateRuleAsync**: capture `beforeSnapshot = FromEntity(ruleById)` at line 274 (after fetch, before mutations), after transaction returns capture after from response. ActionBy=request.UpdatedBy
- **DeleteRuleAsync**: capture `beforeSnapshot = FromEntity(rule)` at line 586 (after fetch), fire after SaveChangesAsync at line 591. After=null, ActionBy=null
- **EnableRuleAsync**: capture `beforeSnapshot = FromEntity(rule)` at line 601, after SaveChangesAsync use `beforeSnapshot with { IsEnabled = true }`. ActionBy=null
- **DisableRuleAsync**: same pattern as Enable, `beforeSnapshot with { IsEnabled = false }`. ActionBy=null

**Result type**: Discriminated union — `Result<T,E>.Success(Value)` / `Result<T,E>.Failure(Error)`. Pattern match with `is Result<AlertSeverityRuleDetailsResponse, ServiceError>.Success success`.

### Acceptance Criteria
- [x] AuditLarkBot config section exists in appsettings.json with same values as main bot
- [x] ISeverityRuleAuditNotification is registered in DI and resolves correctly
- [x] All 5 mutation operations (Create/Update/Delete/Enable/Disable) fire audit notifications
- [x] Audit notification is fire-and-forget (does not block main response)
- [x] Audit notification failures are logged but never throw to caller
- [x] Lark card includes action type, actor (when available), timestamp, and rule snapshot
- [x] Update audit card shows both before and after snapshots
- [x] Solution builds cleanly and all existing tests pass

### Sprint Contract — Testable Behaviors
1. `dotnet build VSH.AlertCollectorAPI.sln` passes with zero errors/warnings from new code
2. `dotnet test VSH.AlertCollectorAPI.sln --verbosity quiet` passes (no regressions)
3. `ISeverityRuleAuditNotification` resolves from DI container (verifiable via service collection check in startup)
4. `LarkAuditCardBuilder.BuildAuditCard` produces valid `LarkSendCardMessageRequest` for each of the 5 audit actions

### Rework Items
