# Docker Reset — Full Teardown and Rebuild

Tear down the Docker development environment, rebuild, run migrations, apply RLS, and seed data.

Optional argument: `$ARGUMENTS`
- `soft` — keep volumes (preserve data), only restart containers
- `no-seed` — skip seed data
- (empty) — full reset with volume deletion

## Instructions

### Step 1: Determine mode

- If `$ARGUMENTS` contains "soft": do NOT pass `-v` to `docker compose down` (keep data)
- If `$ARGUMENTS` contains "no-seed": skip the seed step
- Default (empty): full teardown including volumes

### Step 2: Tear down

```bash
# Full reset (default):
cd /mnt/c/Users/lkw06/Projects/ai-agents && docker compose -f docker/docker-compose.yml down -v

# Soft reset:
cd /mnt/c/Users/lkw06/Projects/ai-agents && docker compose -f docker/docker-compose.yml down
```

### Step 3: Rebuild and start

```bash
cd /mnt/c/Users/lkw06/Projects/ai-agents && docker compose -f docker/docker-compose.yml up -d --build
```

### Step 4: Wait for PostgreSQL health

Check if PostgreSQL is ready:
```bash
docker compose -f docker/docker-compose.yml exec postgres pg_isready -U aiagents
```

If not ready, wait a few seconds and retry (up to 30 seconds total).

### Step 5: Apply EF Core migrations

```bash
cd /mnt/c/Users/lkw06/Projects/ai-agents && dotnet ef database update --project src/AiAgents.Infrastructure --startup-project src/AiAgents.Api -- --ConnectionStrings:DefaultConnection="Host=localhost;Port=5432;Database=aiagents;Username=aiagents;Password=dev_password"
```

Note: Uses `--` separator to pass connection string as app argument, overriding appsettings.

### Step 6: Apply RLS policies

```bash
cd /mnt/c/Users/lkw06/Projects/ai-agents && docker compose -f docker/docker-compose.yml exec -T postgres psql -U aiagents -d aiagents < scripts/apply-rls.sql
```

### Step 7: Seed development data (unless no-seed)

```bash
cd /mnt/c/Users/lkw06/Projects/ai-agents && docker compose -f docker/docker-compose.yml exec -T postgres psql -U aiagents -d aiagents < scripts/seed-dev-data.sql
```

### Step 8: Verify

Check all containers are running:
```bash
docker compose -f docker/docker-compose.yml ps
```

### Step 9: Report

Tell the user:
- Which mode was used (full/soft/no-seed)
- Container status
- Migration result
- RLS applied
- Seed data status
- Endpoints: API http://localhost:5000, Grafana http://localhost:3001, Prometheus http://localhost:9090
