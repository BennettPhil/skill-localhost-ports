# Advanced Usage

## JSON Output

```bash
./scripts/run.sh --json
```

Output:

```json
[
  {"port": 80, "pid": 1234, "process": "nginx", "state": "LISTEN", "protocol": "tcp"},
  {"port": 3000, "pid": 5678, "process": "node", "state": "LISTEN", "protocol": "tcp"}
]
```

## Check If a Port Is Free

```bash
./scripts/run.sh --check 8080
```

Output (port in use):

```
Port 8080 is in use by java (PID 3456)
```

Output (port free):

```
Port 8080 is free
```

## Kill Process on a Port

```bash
./scripts/run.sh --kill 3000
```

Output:

```
Killed process node (PID 5678) on port 3000
```
