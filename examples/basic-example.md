# Basic Example

> See what ports are in use on your machine and which processes own them.

## Step 1: Run the Script

```bash
./scripts/run.sh
```

## Step 2: See the Output

Expected output (example):

```
PORT    PID     PROCESS         STATE
80      1234    nginx           LISTEN
443     1234    nginx           LISTEN
3000    5678    node            LISTEN
5432    9012    postgres        LISTEN
8080    3456    java            LISTEN
```

## What Just Happened

The script detected your OS (macOS or Linux), used the appropriate tool (`lsof` on macOS, `ss` on Linux), and listed all listening TCP ports with the owning process.

## Next Steps

- See [Common Patterns](./common-patterns.md) for filtering and formatting
- See [Advanced Usage](./advanced-usage.md) for JSON output and specific port checks
