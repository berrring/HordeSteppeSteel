"""Run all Godot gameplay regressions; no Python packages required."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

TESTS = (
    "test_battle_calculator", "test_strategic_ai", "test_tactical_results",
    "test_economy_validation", "test_alen", "test_godot_gameplay",
    "test_campaign_orders", "test_campaign_flow", "test_campaign_input",
)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", default=os.environ.get("GODOT_BIN", "godot"))
    args = parser.parse_args()
    engine = shutil.which(args.engine)
    if engine is None:
        parser.error("Godot not found. Pass --engine /path/to/godot or set GODOT_BIN.")
    project = Path(__file__).resolve().parent
    logs = Path(tempfile.mkdtemp(prefix="horde-tests-"))
    cases = [("import", ["--editor", "--import"])]
    cases += [(test, ["--script", f"res://scripts/tests/{test}.gd"]) for test in TESTS]
    cases.append(("startup", ["--quit-after", "120"]))
    failures = 0
    for name, flags in cases:
        try:
            result = subprocess.run(
                [engine, "--headless", "--path", str(project), *flags],
                capture_output=True, text=True, timeout=60,
            )
        except subprocess.TimeoutExpired:
            print(f"FAIL {name}: exceeded 60 seconds")
            return 1
        output = result.stdout + result.stderr
        (logs / f"{name}.log").write_text(output, encoding="utf-8")
        # Godot may exit zero after a GDScript error; inspect diagnostics too.
        bad = result.returncode != 0 or any(
            marker in output for marker in ("SCRIPT ERROR", "ERROR:", "[FAIL]", "FAIL ")
        )
        summaries = [line.strip() for line in output.splitlines()
                     if any(word in line for word in ("checks, failures:", "TOTAL TESTS:", "ALEN:"))]
        print(f"{'FAIL' if bad else 'PASS'} {name}", *summaries, flush=True)
        if bad:
            failures += 1
            print("\n".join(output.splitlines()[-50:]))
            if name == "import":
                break
    print(f"Failures: {failures}. Logs: {logs}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
