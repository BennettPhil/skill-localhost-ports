#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: run.sh [OPTIONS]

Shows listening ports and owning processes. Works on macOS and Linux.

Options:
  --port PORT      Show only the specified port
  --process NAME   Filter by process name
  --all            Show all connections (not just LISTEN)
  --udp            Include UDP ports
  --json           Output as JSON array
  --check PORT     Check if a port is free or in use
  --kill PORT      Kill the process on the specified port
  --help           Show this help message
EOF
  exit 0
}

# --- Parse arguments ---
FILTER_PORT=""
FILTER_PROCESS=""
SHOW_ALL=false
SHOW_UDP=false
JSON_OUTPUT=false
CHECK_PORT=""
KILL_PORT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help) usage ;;
    --port) FILTER_PORT="$2"; shift 2 ;;
    --process) FILTER_PROCESS="$2"; shift 2 ;;
    --all) SHOW_ALL=true; shift ;;
    --udp) SHOW_UDP=true; shift ;;
    --json) JSON_OUTPUT=true; shift ;;
    --check) CHECK_PORT="$2"; shift 2 ;;
    --kill) KILL_PORT="$2"; shift 2 ;;
    *) echo "Error: Unknown option '$1'" >&2; exit 1 ;;
  esac
done

OS=$(uname -s)

# --- Check if a port is free ---
if [[ -n "$CHECK_PORT" ]]; then
  if [[ "$OS" = "Darwin" ]]; then
    result=$(lsof -iTCP:"$CHECK_PORT" -sTCP:LISTEN -P -n 2>/dev/null | tail -n +2 | head -1 || true)
  else
    result=$(ss -tlnp 2>/dev/null | grep ":${CHECK_PORT} " | head -1 || true)
  fi
  if [[ -n "$result" ]]; then
    if [[ "$OS" = "Darwin" ]]; then
      proc=$(echo "$result" | awk '{print $1}')
      pid=$(echo "$result" | awk '{print $2}')
    else
      proc=$(echo "$result" | grep -oP 'users:\(\("\K[^"]+' || echo "unknown")
      pid=$(echo "$result" | grep -oP 'pid=\K[0-9]+' || echo "?")
    fi
    echo "Port $CHECK_PORT is in use by $proc (PID $pid)"
    exit 1
  else
    echo "Port $CHECK_PORT is free"
    exit 0
  fi
fi

# --- Kill process on port ---
if [[ -n "$KILL_PORT" ]]; then
  if [[ "$OS" = "Darwin" ]]; then
    result=$(lsof -iTCP:"$KILL_PORT" -sTCP:LISTEN -P -n 2>/dev/null | tail -n +2 | head -1 || true)
    if [[ -z "$result" ]]; then
      echo "No process found on port $KILL_PORT" >&2
      exit 1
    fi
    proc=$(echo "$result" | awk '{print $1}')
    pid=$(echo "$result" | awk '{print $2}')
  else
    result=$(ss -tlnp 2>/dev/null | grep ":${KILL_PORT} " | head -1 || true)
    if [[ -z "$result" ]]; then
      echo "No process found on port $KILL_PORT" >&2
      exit 1
    fi
    proc=$(echo "$result" | grep -oP 'users:\(\("\K[^"]+' || echo "unknown")
    pid=$(echo "$result" | grep -oP 'pid=\K[0-9]+' || echo "")
  fi
  if [[ -n "$pid" && "$pid" != "?" ]]; then
    kill "$pid" 2>/dev/null && echo "Killed process $proc (PID $pid) on port $KILL_PORT" || echo "Failed to kill PID $pid" >&2
  else
    echo "Could not determine PID for port $KILL_PORT" >&2
    exit 1
  fi
  exit 0
fi

# --- List ports ---
get_ports_darwin() {
  local lsof_flags="-iTCP -P -n"
  if [[ "$SHOW_ALL" = false ]]; then
    lsof_flags="$lsof_flags -sTCP:LISTEN"
  fi
  if [[ -n "$FILTER_PORT" ]]; then
    lsof_flags="-iTCP:${FILTER_PORT} -P -n"
    if [[ "$SHOW_ALL" = false ]]; then
      lsof_flags="$lsof_flags -sTCP:LISTEN"
    fi
  fi

  local tcp_output
  tcp_output=$(eval lsof $lsof_flags 2>/dev/null | tail -n +2 || true)

  local udp_output=""
  if [[ "$SHOW_UDP" = true ]]; then
    if [[ -n "$FILTER_PORT" ]]; then
      udp_output=$(lsof -iUDP:"$FILTER_PORT" -P -n 2>/dev/null | tail -n +2 || true)
    else
      udp_output=$(lsof -iUDP -P -n 2>/dev/null | tail -n +2 || true)
    fi
  fi

  local combined="$tcp_output"
  if [[ -n "$udp_output" ]]; then
    combined="$combined"$'\n'"$udp_output"
  fi

  echo "$combined" | while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local proc pid port_info state proto
    proc=$(echo "$line" | awk '{print $1}')
    pid=$(echo "$line" | awk '{print $2}')
    proto=$(echo "$line" | awk '{print $8}' | grep -oE '(TCP|UDP)' || echo "tcp")
    port_info=$(echo "$line" | awk '{print $9}')
    local port
    port=$(echo "$port_info" | grep -oE '[0-9]+$' || echo "?")
    state=$(echo "$line" | awk '{print $10}')
    [[ -z "$state" ]] && state="LISTEN"
    state=$(echo "$state" | tr -d '()')

    if [[ -n "$FILTER_PROCESS" && "$proc" != *"$FILTER_PROCESS"* ]]; then
      continue
    fi

    echo "${port}|${pid}|${proc}|${state}|${proto}"
  done | sort -t'|' -k1 -n | uniq
}

get_ports_linux() {
  local output=""

  if [[ "$SHOW_ALL" = true ]]; then
    output=$(ss -tanp 2>/dev/null | tail -n +2 || true)
  else
    output=$(ss -tlnp 2>/dev/null | tail -n +2 || true)
  fi

  if [[ "$SHOW_UDP" = true ]]; then
    local udp
    if [[ "$SHOW_ALL" = true ]]; then
      udp=$(ss -uanp 2>/dev/null | tail -n +2 || true)
    else
      udp=$(ss -ulnp 2>/dev/null | tail -n +2 || true)
    fi
    if [[ -n "$udp" ]]; then
      output="$output"$'\n'"$udp"
    fi
  fi

  echo "$output" | while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local state local_addr port proto proc pid
    state=$(echo "$line" | awk '{print $1}')
    local_addr=$(echo "$line" | awk '{print $4}')
    port=$(echo "$local_addr" | grep -oE '[0-9]+$' || echo "?")
    proto=$(echo "$line" | awk '{if ($1 ~ /udp/) print "udp"; else print "tcp"}')

    if [[ -n "$FILTER_PORT" && "$port" != "$FILTER_PORT" ]]; then
      continue
    fi

    proc=$(echo "$line" | grep -oP 'users:\(\("\K[^"]+' || echo "-")
    pid=$(echo "$line" | grep -oP 'pid=\K[0-9]+' || echo "-")

    if [[ -n "$FILTER_PROCESS" && "$proc" != *"$FILTER_PROCESS"* ]]; then
      continue
    fi

    echo "${port}|${pid}|${proc}|${state}|${proto}"
  done | sort -t'|' -k1 -n | uniq
}

# --- Collect data ---
if [[ "$OS" = "Darwin" ]]; then
  DATA=$(get_ports_darwin)
else
  DATA=$(get_ports_linux)
fi

# --- Output ---
if [[ "$JSON_OUTPUT" = true ]]; then
  echo "["
  first=true
  while IFS='|' read -r port pid proc state proto; do
    [[ -z "$port" ]] && continue
    if [[ "$first" = true ]]; then
      first=false
    else
      echo ","
    fi
    printf '  {"port": %s, "pid": %s, "process": "%s", "state": "%s", "protocol": "%s"}' \
      "$port" "$pid" "$proc" "$state" "$proto"
  done <<< "$DATA"
  echo ""
  echo "]"
else
  printf "%-8s%-8s%-16s%-12s\n" "PORT" "PID" "PROCESS" "STATE"
  while IFS='|' read -r port pid proc state proto; do
    [[ -z "$port" ]] && continue
    printf "%-8s%-8s%-16s%-12s\n" "$port" "$pid" "$proc" "$state"
  done <<< "$DATA"
fi
