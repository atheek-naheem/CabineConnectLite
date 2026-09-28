#!/usr/bin/env bash
# pulse.sh - report process progress ("pulses") to ai-hub.
#
# Usage:
#   tools/pulse.sh <stage> started [--dry-run]
#   tools/pulse.sh <stage> completed --gate <passed|failed> [--count name=number ...] [--dry-run]
#   tools/pulse.sh status
#
# Stages: requirements-elaboration design development review quality handoff
#
# Configuration:
#   tools/pulse.config  committed, no secrets (host, agent actor, node and activity IDs)
#   .env                never committed (AIHUB_TEAM_KEY, AIHUB_ACTOR)
#   Environment variables override values from both files.
#
# Exit codes: 0 on success AND on any network/ai-hub/setup failure (never blocks
# the team); 2 on usage errors (bad stage, missing gate, invalid count).
#
# Requires only bash (3.2+), curl, git and a UUID source.

set -u

STAGES="requirements-elaboration design development review quality handoff"
COUNT_SUFFIXES="_count _passed _failed _fixed _completed _traced"
TIMEOUT_SECONDS=5

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$SCRIPT_DIR/pulse.config"
ENV_FILE="$ROOT/.env"
STATE_DIR="$ROOT/.pulse"
LOG_FILE="$ROOT/pulses.log"

# ---------------------------------------------------------------- helpers ---

warn() { printf 'pulse: warning: %s\n' "$*" >&2; }
info() { printf 'pulse: %s\n' "$*" >&2; }

usage() {
    cat >&2 <<'EOF'
Usage:
  tools/pulse.sh <stage> started [--dry-run]
  tools/pulse.sh <stage> completed --gate <passed|failed> [--count name=number ...] [--dry-run]
  tools/pulse.sh status

Stages: requirements-elaboration design development review quality handoff
EOF
}

usage_error() {
    printf 'pulse: error: %s\n' "$*" >&2
    usage
    exit 2
}

# Escape a string for use inside a JSON string literal.
json_escape() {
    local s=$1
    s=${s//\\/\\\\}
    s=${s//\"/\\\"}
    s=${s//$'\n'/\\n}
    s=${s//$'\r'/\\r}
    s=${s//$'\t'/\\t}
    # Drop any remaining control characters (not valid unescaped in JSON).
    s=$(printf '%s' "$s" | LC_ALL=C tr -d '\000-\010\013\014\016-\037')
    printf '%s' "$s"
}

new_uuid() {
    local u=""
    if command -v uuidgen >/dev/null 2>&1; then
        u=$(uuidgen 2>/dev/null)
    fi
    if [ -z "$u" ] && [ -r /proc/sys/kernel/random/uuid ]; then
        u=$(cat /proc/sys/kernel/random/uuid)
    fi
    if [ -z "$u" ] && [ -r /dev/urandom ]; then
        # Last resort: build a version-4 UUID from random bytes.
        local h
        h=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
        u="${h:0:8}-${h:8:4}-4${h:13:3}-a${h:17:3}-${h:20:12}"
    fi
    printf '%s' "$u" | tr 'A-F' 'a-f'
}

timestamp() { date -u +%Y-%m-%dT%H:%M:%SZ; }

is_stage() {
    local s
    for s in $STAGES; do
        [ "$s" = "$1" ] && return 0
    done
    return 1
}

upper() { printf '%s' "$1" | tr '[:lower:]-' '[:upper:]_'; }

# Load KEY=VALUE lines from a file into CFG_<KEY> variables (no eval).
load_kv_file() {
    local file=$1 line key value
    [ -f "$file" ] || return 0
    while IFS= read -r line || [ -n "$line" ]; do
        line=${line%$'\r'}
        case "$line" in ''|'#'*) continue ;; esac
        case "$line" in *=*) ;; *) continue ;; esac
        key=${line%%=*}
        value=${line#*=}
        key=${key#export }
        key=$(printf '%s' "$key" | tr -d ' \t')
        [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
        # Trim surrounding whitespace, then one pair of matching quotes.
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        if [ ${#value} -ge 2 ]; then
            case "$value" in
                \"*\") value=${value:1:${#value}-2} ;;
                \'*\') value=${value:1:${#value}-2} ;;
            esac
        fi
        printf -v "CFG_$key" '%s' "$value"
    done < "$file"
}

# Value lookup: environment variable first, then .env / pulse.config.
cfg() {
    local key=$1 env_val cfg_name="CFG_$1"
    env_val=${!key:-}
    if [ -n "$env_val" ]; then
        printf '%s' "$env_val"
    else
        printf '%s' "${!cfg_name:-}"
    fi
}

is_placeholder() {
    case "$1" in
        ''|*FILL_ME*|'<'*'>'|*your_*|*YOUR_*) return 0 ;;
    esac
    return 1
}

# Extract the first "field": value pair from a single-line JSON string.
json_field_string() {
    local re="\"$1\"[[:space:]]*:[[:space:]]*\"([^\"]*)\""
    [[ "$2" =~ $re ]] && printf '%s' "${BASH_REMATCH[1]}"
}
json_field_raw() {
    local re="\"$1\"[[:space:]]*:[[:space:]]*([-0-9a-z]+)"
    [[ "$2" =~ $re ]] && printf '%s' "${BASH_REMATCH[1]}"
}

# Count logged "started" pulses for a stage (sent and failed; dry-runs excluded).
count_started() {
    local stage=$1 n=0 line
    [ -f "$LOG_FILE" ] || { printf '0'; return; }
    while IFS= read -r line || [ -n "$line" ]; do
        [ "$(json_field_string stage "$line")" = "$stage" ] || continue
        [ "$(json_field_string event "$line")" = "started" ] || continue
        [ "$(json_field_string result "$line")" = "dry-run" ] && continue
        n=$((n + 1))
    done < "$LOG_FILE"
    printf '%s' "$n"
}

# ----------------------------------------------------------------- status ---

cmd_status() {
    if [ ! -f "$LOG_FILE" ]; then
        info "no pulses.log yet - no pulses have been sent."
        return 0
    fi
    printf '%-12s %-10s %-8s %-10s %-7s %s\n' STAGE ITERATIONS STARTED COMPLETED GATE SENT
    local stage line iter latest started completed gate sent any result ev
    for stage in $STAGES; do
        latest=0
        while IFS= read -r line || [ -n "$line" ]; do
            [ "$(json_field_string stage "$line")" = "$stage" ] || continue
            [ "$(json_field_string result "$line")" = "dry-run" ] && continue
            iter=$(json_field_raw iteration "$line")
            [[ "$iter" =~ ^[0-9]+$ ]] || continue
            [ "$iter" -gt "$latest" ] && latest=$iter
        done < "$LOG_FILE"

        if [ "$latest" -eq 0 ]; then
            printf '%-12s %-10s %-8s %-10s %-7s %s\n' "$stage" 0 - - - -
            continue
        fi

        started=no; completed=no; gate=-; sent=yes; any=no
        while IFS= read -r line || [ -n "$line" ]; do
            [ "$(json_field_string stage "$line")" = "$stage" ] || continue
            result=$(json_field_string result "$line")
            [ "$result" = "dry-run" ] && continue
            [ "$(json_field_raw iteration "$line")" = "$latest" ] || continue
            any=yes
            ev=$(json_field_string event "$line")
            [ "$ev" = "started" ] && started=yes
            if [ "$ev" = "completed" ]; then
                completed=yes
                case "$(json_field_raw gate_passed "$line")" in
                    true) gate=passed ;;
                    false) gate=failed ;;
                esac
            fi
            [ "$result" = "sent" ] || sent=no
        done < "$LOG_FILE"
        [ "$any" = yes ] || sent=-
        printf '%-12s %-10s %-8s %-10s %-7s %s\n' \
            "$stage" "$(count_started "$stage")" "$started" "$completed" "$gate" "$sent"
    done
    printf '\n(ITERATIONS counts started pulses; STARTED/COMPLETED/GATE/SENT describe the latest iteration. Dry-runs are ignored.)\n'
}

# ------------------------------------------------------------------ pulse ---

append_log() {
    # $1 result, $2 http status (number or null), $3 url, $4 payload json, $5 message
    local line
    line="{\"timestamp\":\"$(timestamp)\",\"result\":\"$1\",\"http_status\":$2,\"url\":\"$(json_escape "$3")\",\"message\":\"$(json_escape "$5")\",\"payload\":$4}"
    printf '%s\n' "$line" >> "$LOG_FILE" || warn "could not write to pulses.log"
}

main() {
    [ $# -ge 1 ] || usage_error "missing arguments"

    case "$1" in
        status)
            [ $# -eq 1 ] || usage_error "status takes no arguments"
            cmd_status
            exit 0 ;;
        -h|--help|help)
            usage
            exit 0 ;;
    esac

    local stage=$1
    is_stage "$stage" || usage_error "unknown stage '$stage' (allowed: $STAGES)"
    [ $# -ge 2 ] || usage_error "missing event (started or completed)"
    local event=$2
    case "$event" in
        started|completed) ;;
        *) usage_error "unknown event '$event' (allowed: started, completed)" ;;
    esac
    shift 2

    local dry_run=no gate="" counts_json="" seen_names=" " arg name value suffix full
    while [ $# -gt 0 ]; do
        arg=$1
        case "$arg" in
            --dry-run) dry_run=yes ;;
            --gate|--gate=*)
                if [ "$arg" = "--gate" ]; then
                    [ $# -ge 2 ] || usage_error "--gate needs a value (passed or failed)"
                    gate=$2; shift
                else
                    gate=${arg#--gate=}
                fi
                case "$gate" in passed|failed) ;; *) usage_error "--gate must be 'passed' or 'failed' (got '$gate')" ;; esac
                ;;
            --count|--count=*)
                if [ "$arg" = "--count" ]; then
                    [ $# -ge 2 ] || usage_error "--count needs name=number"
                    value=$2; shift
                else
                    value=${arg#--count=}
                fi
                case "$value" in *=*) ;; *) usage_error "--count must be name=number (got '$value')" ;; esac
                name=${value%%=*}
                value=${value#*=}
                [[ "$name" =~ ^[a-z][a-z0-9]*(_[a-z0-9]+)*$ ]] \
                    || usage_error "count name '$name' must be lowercase snake_case (e.g. open_questions)"
                [[ "$value" =~ ^[0-9]+$ ]] \
                    || usage_error "count '$name' must be a non-negative integer (got '$value')"
                [ ${#value} -le 15 ] || usage_error "count '$name' is too large"
                value=$(printf '%s' "$value" | sed 's/^0*//'); [ -n "$value" ] || value=0
                full="${name}_count"
                for suffix in $COUNT_SUFFIXES; do
                    case "$name" in *"$suffix") full=$name ;; esac
                done
                case "$seen_names" in *" $full "*) usage_error "count '$full' given more than once" ;; esac
                seen_names="$seen_names$full "
                counts_json="$counts_json,\"$full\":$value"
                ;;
            *) usage_error "unknown option '$arg'" ;;
        esac
        shift
    done

    if [ "$event" = "started" ]; then
        [ -z "$gate" ] || usage_error "--gate is only valid with 'completed'"
        [ -z "$counts_json" ] || usage_error "--count is only valid with 'completed'"
    else
        [ -n "$gate" ] || usage_error "'completed' requires --gate passed|failed"
    fi

    # --- configuration ---
    load_kv_file "$CONFIG_FILE"
    load_kv_file "$ENV_FILE"

    local stage_up host agent actor key node activity expected_activity problems=""
    stage_up=$(upper "$stage")
    host=$(cfg AIHUB_HOST); host=${host%/}
    agent=$(cfg AGENT_ACTOR)
    actor=$(cfg AIHUB_ACTOR)
    key=$(cfg AIHUB_TEAM_KEY)
    node=$(cfg "${stage_up}_NODE")
    if [ "$event" = "started" ]; then
        activity=$(cfg "${stage_up}_STARTED"); expected_activity="stage-started"
    else
        activity=$(cfg "${stage_up}_COMPLETED"); expected_activity="stage-completed"
    fi

    [ -f "$ENV_FILE" ] || [ -n "${AIHUB_TEAM_KEY:-}" ] || problems="$problems
  - .env not found: copy .env.example to .env and fill it in"
    is_placeholder "$key" && problems="$problems
  - AIHUB_TEAM_KEY is missing or a placeholder (set it in .env)"
    is_placeholder "$actor" && problems="$problems
  - AIHUB_ACTOR is missing or a placeholder (set your registered email in .env)"
    is_placeholder "$host" && problems="$problems
  - AIHUB_HOST is missing in tools/pulse.config"
    is_placeholder "$agent" && problems="$problems
  - AGENT_ACTOR is missing in tools/pulse.config"
    is_placeholder "$node" && problems="$problems
  - ${stage_up}_NODE is missing or a placeholder in tools/pulse.config (ask the organizer)"
    is_placeholder "$activity" && problems="$problems
  - ${stage_up}_$(upper "$event") is missing or a placeholder in tools/pulse.config (ask the organizer)"

    # --- correlation ID and iteration ---
    # .pulse/<stage>.cid holds two lines, written at 'started' and reused at
    # 'completed': the correlation ID and the iteration number.
    local cid_file="$STATE_DIR/$stage.cid" cid="" iteration=""
    if [ "$event" = "started" ]; then
        if [ -f "$cid_file" ] && [ "$dry_run" = no ]; then
            warn "'$stage' was already started and not completed; starting a new iteration."
        fi
        cid=$(new_uuid)
        iteration=$(( $(count_started "$stage") + 1 ))
    else
        if [ -f "$cid_file" ]; then
            cid=$(sed -n '1p' "$cid_file" | tr -d ' \r\n')
            iteration=$(sed -n '2p' "$cid_file" | tr -d ' \r\n')
        fi
        if [ -z "$cid" ]; then
            warn "no matching 'started' pulse found for '$stage'; using a new correlation ID."
            cid=$(new_uuid)
        fi
        if ! [[ "$iteration" =~ ^[0-9]+$ ]] || [ "$iteration" -lt 1 ]; then
            iteration=$(count_started "$stage")
            [ "$iteration" -ge 1 ] || iteration=1
        fi
    fi

    # --- commit ---
    local commit="unknown"
    if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
        commit=$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null) || commit="unknown"
        [ -n "$commit" ] || commit="unknown"
        if [ "$event" = "completed" ] && [ -n "$(git -C "$ROOT" status --porcelain -- . ':(exclude)pulses.log' 2>/dev/null)" ]; then
            warn "working tree has uncommitted changes; commit the stage artifact before 'completed'."
        fi
    else
        warn "not a git repository (or git not installed); commit reported as 'unknown'."
    fi

    # --- payload ---
    local event_id gate_json="" payload url
    event_id=$(new_uuid)
    if [ -z "$event_id" ] || [ -z "$cid" ]; then
        warn "no UUID source available (uuidgen, /proc/sys/kernel/random/uuid or /dev/urandom)."
    fi
    if [ "$event" = "completed" ]; then
        if [ "$gate" = "passed" ]; then gate_json=',"gate_passed":true'; else gate_json=',"gate_passed":false'; fi
    fi
    payload="{\"eventId\":\"$(json_escape "$event_id")\",\"correlationId\":\"$(json_escape "$cid")\",\"actors\":[\"$(json_escape "$actor")\",\"$(json_escape "$agent")\"],\"dimensions\":{\"stage\":\"$stage\",\"event\":\"$event\",\"iteration\":$iteration,\"commit\":\"$(json_escape "$commit")\"$gate_json$counts_json}}"
    url="$host/metrics/nodes/$node/node-activities/$activity/events"

    # --- dry run ---
    if [ "$dry_run" = yes ]; then
        printf 'DRY RUN - nothing sent.\nPOST %s\n%s\n' "$url" "$payload"
        if [ -n "$problems" ]; then
            printf '\nSetup is NOT complete:%s\n' "$problems"
        else
            printf '\nSetup looks complete (key and actor present; key not shown).\n'
        fi
        append_log "dry-run" null "$url" "$payload" "dry run"
        exit 0
    fi

    # Update correlation state now so a failed send does not break the pairing.
    if [ "$event" = "started" ]; then
        if ! { mkdir -p "$STATE_DIR" && printf '%s\n%s\n' "$cid" "$iteration" > "$cid_file"; }; then
            warn "could not write $cid_file"
        fi
    else
        rm -f "$cid_file"
    fi

    # --- setup problems: log as failed, never block ---
    if [ -n "$problems" ]; then
        warn "pulse NOT sent - setup is incomplete:$problems"
        append_log "failed" null "$url" "$payload" "setup incomplete"
        exit 0
    fi

    if ! command -v curl >/dev/null 2>&1; then
        warn "curl not found; pulse NOT sent."
        append_log "failed" null "$url" "$payload" "curl not found"
        exit 0
    fi

    # --- send (key passed to curl on stdin, never on the command line) ---
    local tmp body_file status esc_key
    tmp=$(mktemp -d 2>/dev/null || mktemp -d -t pulse)
    body_file="$tmp/body"
    printf '%s' "$payload" > "$tmp/payload"
    esc_key=${key//\\/\\\\}
    esc_key=${esc_key//\"/\\\"}
    status=$(printf 'header = "Authorization: Bearer %s"\n' "$esc_key" \
        | curl -sS -K - -X POST \
            -H "Content-Type: application/json" \
            --data-binary "@$tmp/payload" \
            --max-time "$TIMEOUT_SECONDS" \
            -o "$body_file" -w '%{http_code}' \
            "$url" 2>"$tmp/err")
    local curl_rc=$?
    local body=""
    [ -f "$body_file" ] && body=$(tr -d '\r\n' < "$body_file")
    local curl_err
    curl_err=$(head -n 1 "$tmp/err" 2>/dev/null)
    rm -rf "$tmp"

    [[ "$status" =~ ^[0-9]{3}$ ]] || status=000
    if [ "$curl_rc" -ne 0 ] || [ "$status" = "000" ]; then
        warn "could not reach ai-hub ($curl_err); pulse NOT sent. Carry on - it is logged in pulses.log."
        append_log "failed" null "$url" "$payload" "network error: $curl_err"
        exit 0
    fi

    if [ "$status" != "202" ]; then
        warn "ai-hub answered HTTP $status (expected 202); pulse NOT accepted. Carry on - it is logged in pulses.log."
        append_log "failed" "$((10#$status))" "$url" "$payload" "unexpected HTTP status"
        exit 0
    fi

    local message="accepted" got_activity accepted
    got_activity=$(json_field_string activity "$body")
    accepted=$(json_field_raw accepted "$body")
    if [ "$got_activity" != "$expected_activity" ]; then
        warn "ai-hub recorded activity '$got_activity' but '$expected_activity' was expected; check ${stage_up}_$(upper "$event") in tools/pulse.config."
        message="activity mismatch: got '$got_activity'"
    fi
    if [ "$accepted" = "0" ]; then
        warn "ai-hub accepted 0 events (filtered); tell the organizer."
        message="$message; accepted 0"
    fi
    append_log "sent" 202 "$url" "$payload" "$message"
    info "$stage $event pulse sent (iteration $iteration)."
    exit 0
}

main "$@"
