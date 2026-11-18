#!/usr/bin/env bash
# Run every Luau test file with the Luau CLI and print a summary.
# Each test file is assembled into one combined chunk (stub + game sources
# + test) by tests/build_combined.mjs, because the Luau CLI sandboxes
# required modules away from the stub's globals.
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
LUAU="$HOME/workspace/tools/luau-0.747/luau"
NODE="${NODE:-node}"

if [ ! -x "$LUAU" ]; then
	echo "run.sh: Luau CLI not found at $LUAU" >&2
	exit 2
fi

passed=0
failed=0
failed_files=()

for test_file in "$REPO"/tests/test_*.luau; do
	name="$(basename "$test_file")"
	echo "=== tests/$name ==="
	combined="$(mktemp /tmp/steal-a-snack-test-XXXXXX.luau)"
	if ! "$NODE" "$REPO/tests/build_combined.mjs" "$REPO" "tests/$name" "$combined" 2>&1; then
		echo "BUILD FAILED: tests/$name (see above — a source file is probably missing or empty)"
		failed=$((failed + 1))
		failed_files+=("tests/$name")
		rm -f "$combined"
		continue
	fi
	output="$("$LUAU" "$combined" 2>&1)"
	status=$?
	echo "$output"
	rm -f "$combined"
	line="$(echo "$output" | grep -E '^RESULT: passed=' | tail -n 1)"
	if [ -n "$line" ]; then
		p="$(echo "$line" | sed -E 's/.*passed=([0-9]+).*/\1/')"
		f="$(echo "$line" | sed -E 's/.*failed=([0-9]+).*/\1/')"
		passed=$((passed + p))
		failed=$((failed + f))
	elif [ "$status" -ne 0 ]; then
		# Crashed before printing a RESULT line; count it as one failure.
		failed=$((failed + 1))
	fi
	if [ "$status" -ne 0 ]; then
		failed_files+=("tests/$name")
	fi
done

echo "RESULT: passed=$passed failed=$failed"
if [ "${#failed_files[@]}" -gt 0 ]; then
	echo "FAILED FILES: ${failed_files[*]}"
	exit 1
fi
exit 0
