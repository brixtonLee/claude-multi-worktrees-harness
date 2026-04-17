# Generate EF Core Migration + RLS Policy

Create an EF Core migration named `$ARGUMENTS` and auto-update RLS policies for any new tenant-scoped tables.

## Instructions

### Step 1: Generate the migration

Run:
```bash
dotnet ef migrations add $ARGUMENTS --project src/AiAgents.Infrastructure --startup-project src/AiAgents.Api
```

If this fails, diagnose and fix the issue (usually a missing entity configuration or DbSet).

### Step 2: Find the new migration file

Look in `src/AiAgents.Infrastructure/Migrations/` for the newly created migration file (it will have a timestamp prefix + the migration name).

Read the migration file and identify any `migrationBuilder.CreateTable` calls.

### Step 3: Check for tenant-scoped tables

For each new table created in the migration:
1. Check if the table has a `tenant_id` column (this means the entity inherits from `TenantEntity`).
2. Extract the table name (the snake_case name passed to `CreateTable`).

### Step 4: Update RLS script

If any new tenant-scoped tables were found, edit `scripts/apply-rls.sql`:
- Add the new table name(s) to the `tables TEXT[]` array (maintain alphabetical order within the array for readability).

The array currently looks like:
```sql
tables TEXT[] := ARRAY[
    'contacts', 'conversations', ...
];
```

Add the new table name in the correct alphabetical position.

### Step 5: Verify

Run a quick sanity check:
```bash
dotnet build AiAgents.sln
```

### Step 6: Report

Tell the user:
- Migration name and path
- New tables detected (if any)
- Which tables were added to RLS (if any)
- Any tables that are NOT tenant-scoped (informational — some tables like `tenants` itself don't need RLS)
- Remind the user to run `docker-reset` or manually apply the migration if Docker is running
