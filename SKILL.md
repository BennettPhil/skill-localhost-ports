---
name: localhost-ports
description: Shows listening ports and their owning processes on macOS and Linux, abstracting away lsof/ss/netstat differences.
version: 0.1.0
license: Apache-2.0
---

# Localhost Ports

## Purpose

A cross-platform tool that shows which ports are in use on your machine and what process owns each one. Works on both macOS (`lsof`) and Linux (`ss`/`netstat`) without you having to remember the different flags.

## See It in Action

Start with [examples/basic-example.md](examples/basic-example.md).

## Examples Index

- **[basic-example.md](examples/basic-example.md)** — List all listening ports
- **[common-patterns.md](examples/common-patterns.md)** — Filter by port, process, show UDP
- **[advanced-usage.md](examples/advanced-usage.md)** — JSON output, port availability check, kill by port

## Reference

| Flag            | Description                                   |
|-----------------|-----------------------------------------------|
| `--port PORT`   | Show only the specified port                  |
| `--process NAME`| Filter by process name                        |
| `--all`         | Show all connections, not just LISTEN          |
| `--udp`         | Include UDP ports                             |
| `--json`        | Output as JSON array                          |
| `--check PORT`  | Check if a specific port is free or in use    |
| `--kill PORT`   | Kill the process using the specified port     |
| `--help`        | Show usage information                        |

## Installation

No dependencies — uses built-in OS tools (`lsof` on macOS, `ss` or `netstat` on Linux).
