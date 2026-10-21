#!/usr/bin/env python3
"""Run each Godot regression in a fresh process and retain auditable logs.

Fixtures remain test-owned; --save-path prevents accidental use of the player's pilot.
A zero exit code is insufficient: script errors, assertions and failed checks fail the run.
"""
import argparse
import json
from pathlib import Path
import re
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
BAD = re.compile(r'SCRIPT ERROR:|Parse Error:|Assertion failed|^FAIL(?:ED)?[: ]|[1-9]\d* failures', re.M | re.I)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'builds' / 'acceptance-0.1.178')
    parser.add_argument('--timeout', type=int, default=120)
    parser.add_argument('--test', action='append', help='Exact test filename; repeatable. Default: every test_*.gd.')
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    engine = ROOT / '.tools/Godot.app/Contents/MacOS/Godot'
    tests = sorted((ROOT / 'godot/tests').glob('test_*.gd'))
    if args.test:
        tests = [test for test in tests if test.name in args.test]
        if len(tests) != len(set(args.test)):
            parser.error('Unknown or duplicate test selection')
    results = []
    for test in tests:
        started = time.monotonic()
        cmd = [str(engine), '--headless', '--path', str(ROOT / 'godot'), '--log-file', str(output / (test.stem + '-engine.log')),
               '--script', 'res://tests/' + test.name, '--', '--save-path', str(output / (test.stem + '-pilot.json'))]
        timed_out = False
        try:
            run = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=args.timeout)
            log, code = run.stdout + run.stderr, run.returncode
        except subprocess.TimeoutExpired as error:
            timed_out = True
            log = (error.stdout or b'').decode(errors='replace') + (error.stderr or b'').decode(errors='replace')
            code = -1
        (output / (test.stem + '.log')).write_text(log)
        summaries = [line for line in log.splitlines() if re.search(r'\d+ checks|\d+ failures', line)]
        result = dict(test=test.name, passed=code == 0 and not timed_out and not BAD.search(log), exit_code=code,
                      seconds=round(time.monotonic()-started, 2), timeout=timed_out, summaries=summaries)
        results.append(result)
        (output / 'results.json').write_text(json.dumps(results, indent=2) + '\n')
        print(f'{len(results)}/{len(tests)} {"PASS" if result["passed"] else "FAIL"} {test.name} ({result["seconds"]}s)', flush=True)
    failures = sum(not result['passed'] for result in results)
    print(f'Acceptance: {len(results)-failures}/{len(results)} scripts passed; {failures} failed.', flush=True)
    return bool(failures)


if __name__ == '__main__':
    raise SystemExit(main())
