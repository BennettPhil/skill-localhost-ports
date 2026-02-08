# localhost-ports

Shows listening ports and their owning processes on macOS and Linux. No more forgetting lsof vs ss vs netstat flags.

## Quick Start

```bash
./scripts/run.sh                  # list all listening ports
./scripts/run.sh --port 3000      # check specific port
./scripts/run.sh --json           # JSON output
./scripts/run.sh --check 8080     # is port 8080 free?
./scripts/run.sh --kill 3000      # kill process on port 3000
```

## Prerequisites

- `bash`
- macOS or Linux (uses `lsof` on macOS, `ss` on Linux)
