---
name: result-error-handling
description: "Result<T> for expected failures, exception handling in pipelines, structured logging. Use when implementing error handling or return types in Application/Infrastructure."
context:
  - .claude/skills/solid-ocp/SKILL.md
---

# Skill: Result & Error Handling

## Result<T> for Expected Failures

```csharp
public class Result<T>
{
    public bool IsSuccess { get; }
    public T? Value { get; }
    public string? Error { get; }
    public ResultType Type { get; }

    public static Result<T> Ok(T value) => new(value);
    public static Result<T> NotFound(string msg) => new(msg, ResultType.NotFound);
    public static Result<T> ValidationError(string msg) => new(msg, ResultType.Validation);
    public static Result<T> Forbidden(string msg) => new(msg, ResultType.Forbidden);
}
```

## Mapping to HTTP

```csharp
return result.Type switch
{
    ResultType.Ok => Ok(result.Value),
    ResultType.NotFound => NotFound(result.Error),
    ResultType.Validation => BadRequest(result.Error),
    ResultType.Forbidden => Forbid(),
    _ => StatusCode(500, result.Error)
};
```

## Agent Pipeline Error Handling

```csharp
catch (BudgetExceededException) { return AgentResponse.Queued("Queued."); }
catch (ClaudeApiException ex) { _logger.LogError(ex, "Claude API error {TenantId}", ctx.TenantId);
    return AgentResponse.Error("Issue encountered. Accountant notified."); }
catch (Exception ex) { _logger.LogError(ex, "Unhandled {Agent} {TenantId}", GetType().Name, ctx.TenantId);
    return AgentResponse.Escalate("Connecting you to your accountant."); }
```

## Rules

- Exceptions for unexpected failures — try-catch in pipelines
- Result<T> for expected failures — no throwing
- NEVER swallow exceptions silently
- Structured logging with `{TenantId}` in every log message
- User-facing messages: polite and vague (no stack traces)
- Escalate on unhandled — never leave user hanging

## Location

```
src/AiAgents.Application/Common/Models/      ← AgentResult.cs
src/AiAgents.Application/Common/Exceptions/  ← domain exceptions
```
