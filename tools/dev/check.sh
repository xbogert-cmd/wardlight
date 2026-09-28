#!/bin/bash
# Import new files, parse-check every script/resource, then run the rule tests.
# usage: tools/dev/check.sh   (prints CHECK OK / TESTS PASSED on success)
cd "$(dirname "$0")/../.."
d=$(mktemp -d)
godot --headless --path . --import > "$d/import.log" 2>&1
tools/dev/run.sh "$d/check.log" 120 --headless --path . res://tools/check_scripts.tscn | grep -E "CHECK|FAIL|SCRIPT ERROR|Parse Error|killed"
tools/dev/run.sh "$d/tests.log" 120 --headless --path . res://tests/run_tests.tscn | grep -E "TESTS|FAIL|not ok|SCRIPT ERROR|killed"
