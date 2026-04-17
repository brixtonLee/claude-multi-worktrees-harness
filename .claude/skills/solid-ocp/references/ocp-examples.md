# OCP — Before/After Examples

## Before: Switch Chain That Grows

```csharp
public class NotificationDispatcher
{
    public async Task SendAsync(AlertEvent evt, NotificationChannel channel, CancellationToken ct)
    {
        switch (channel.Type)
        {
            case "lark":
                var larkAuth = new LarkAuthService(channel.AppId, channel.AppSecret);
                var token = await larkAuth.GetTokenAsync(ct);
                // ... 20 lines of Lark-specific logic
                break;
            case "email":
                using var smtp = new SmtpClient(channel.Host, channel.Port);
                // ... 15 lines of email logic
                break;
            case "webhook":
                using var http = new HttpClient();
                // ... 10 lines of webhook logic
                break;
            // Every new channel: modify THIS file, add a case, retest everything
        }
    }
}
```

## After: Strategy Pattern

```csharp
// Adding webhook_v2 channel = new class + 1 DI line. Zero existing code modified.
public class WebhookV2NotificationProvider : INotificationProvider
{
    public string ChannelType => "webhook_v2";

    public async Task SendAsync(AlertEvent alertEvent, CancellationToken ct)
    {
        // New implementation, completely isolated
    }
}

// DI registration — the only "modification" (and it's additive, not a change):
services.AddScoped<INotificationProvider, WebhookV2NotificationProvider>();
```

**The dispatcher never changes. Each channel owns its own logic.**
