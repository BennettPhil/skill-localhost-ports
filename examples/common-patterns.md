# Common Patterns

## Pattern 1: Check a Specific Port

```bash
./scripts/run.sh --port 3000
```

Output:

```
PORT    PID     PROCESS         STATE
3000    5678    node            LISTEN
```

## Pattern 2: Show All Connections (Not Just Listening)

```bash
./scripts/run.sh --all
```

Output includes ESTABLISHED, TIME_WAIT, and other states.

## Pattern 3: Filter by Process Name

```bash
./scripts/run.sh --process node
```

Output:

```
PORT    PID     PROCESS         STATE
3000    5678    node            LISTEN
3001    5679    node            LISTEN
```

## Pattern 4: Show UDP Ports Too

```bash
./scripts/run.sh --udp
```

Output includes UDP listening ports alongside TCP.
