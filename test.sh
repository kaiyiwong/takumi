#!/bin/bash
# ============================================================================
# takumi smoke tests — quick sanity checks, no video files needed
# ============================================================================

set -uo pipefail

PASS=0
FAIL=0

assert() {
  local DESC="$1" EXPECTED="$2" ACTUAL="$3"
  if echo "$ACTUAL" | grep -q "$EXPECTED"; then
    echo "  ✅ $DESC"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $DESC"
    echo "     expected: $EXPECTED"
    echo "     got:      $ACTUAL"
    FAIL=$((FAIL + 1))
  fi
}

run() {
  bash takumi.sh "$@" 2>&1 || true
}

# ── Dispatcher ───────────────────────────────────────────────────────────────

echo "🔧 Dispatcher"

OUT=$(run)
assert "no args shows help" "takumi (匠)" "$OUT"

OUT=$(run help)
assert "help shows help" "Commands:" "$OUT"

OUT=$(run --help)
assert "--help shows help" "Commands:" "$OUT"

OUT=$(run -h)
assert "-h shows help" "Commands:" "$OUT"

OUT=$(run badcmd)
assert "unknown command shows error" "Unknown command: badcmd" "$OUT"

# ── Help flags per command ───────────────────────────────────────────────────

echo ""
echo "🔧 Per-command help"

COMMANDS=("cc" "convert" "trim" "thumb" "info" "gif" "strip" "srt2vtt" "vtt2srt")

for CMD in "${COMMANDS[@]}"; do
  OUT=$(run "$CMD" help)
  assert "$CMD help shows usage" "Usage:" "$OUT"

  OUT=$(run "$CMD" --help)
  assert "$CMD --help shows usage" "Usage:" "$OUT"
done

# ── Argument validation ─────────────────────────────────────────────────────

echo ""
echo "🔧 Argument validation"

OUT=$(run cc)
assert "cc no args shows usage" "Usage:" "$OUT"

OUT=$(run convert)
assert "convert no args shows usage" "Usage:" "$OUT"

OUT=$(run trim)
assert "trim no args shows usage" "Usage:" "$OUT"

OUT=$(run trim nonexistent.mp4 00:00:00 00:00:05)
assert "trim bad file shows error" "not found" "$OUT"

OUT=$(run thumb)
assert "thumb no args shows usage" "Usage:" "$OUT"

OUT=$(run info)
assert "info no args shows usage" "Usage:" "$OUT"

OUT=$(run gif)
assert "gif no args shows usage" "Usage:" "$OUT"

OUT=$(run gif nonexistent.mp4 00:00:00 00:00:05)
assert "gif bad file shows error" "not found" "$OUT"

OUT=$(run strip)
assert "strip no args shows usage" "Usage:" "$OUT"

OUT=$(run strip nonexistent.mp4 audio)
assert "strip bad file shows error" "not found" "$OUT"

OUT=$(run srt2vtt)
assert "srt2vtt no args shows usage" "Usage:" "$OUT"

OUT=$(run vtt2srt)
assert "vtt2srt no args shows usage" "Usage:" "$OUT"

OUT=$(run info nonexistent.mp4)
assert "info bad file shows error" "not found" "$OUT"

OUT=$(run thumb nonexistent.mp4)
assert "thumb bad file shows error" "not found" "$OUT"

# ── get_best_mod16 logic ────────────────────────────────────────────────────

echo ""
echo "🔧 get_best_mod16 (convert sizing)"

source commands/convert.sh

OUT=$(get_best_mod16 1920 1080 1080)
assert "1920x1080 → 1920:1080" "1920:1080" "$OUT"

OUT=$(get_best_mod16 1920 1080 720)
assert "1920x1080 capped 720 → 1280:720" "1280:720" "$OUT"

OUT=$(get_best_mod16 1280 720 1080)
assert "1280x720 → 1280:720" "1280:720" "$OUT"

OUT=$(get_best_mod16 640 480 1080)
assert "640x480 (4:3) → 640:480" "640:480" "$OUT"

OUT=$(get_best_mod16 640 480 240)
assert "640x480 capped 240 → 320:240" "320:240" "$OUT"

OUT=$(get_best_mod16 3840 2160 1080)
assert "4K capped 1080 → 1920:1080" "1920:1080" "$OUT"

# ── All commands listed in help ──────────────────────────────────────────────

echo ""
echo "🔧 Help completeness"

HELP=$(run help)
for CMD in "${COMMANDS[@]}"; do
  assert "$CMD listed in help" "$CMD" "$HELP"
done
assert "setup listed in help" "setup" "$HELP"

# ── Results ──────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
