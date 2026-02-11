# /// script
# requires-python = ">=3.10"
# ///
"""Extract the last final_answer from the most recent Codex session JSONL file.

Usage:
  uv run scripts/get_codex_final_answer.py [--offset N]

Options:
  --offset N  Skip the last N final_answers (default: 0, i.e. return the very last one).
              Use --offset 1 to get the second-to-last, etc.
"""

import json
import sys
from pathlib import Path

SESSIONS_DIR = Path.home() / ".codex" / "sessions"


def find_latest_jsonl(base: Path) -> Path | None:
    """Recursively find the most recently modified .jsonl file."""
    jsonl_files = list(base.rglob("*.jsonl"))
    if not jsonl_files:
        return None
    return max(jsonl_files, key=lambda p: p.stat().st_mtime)


def extract_final_answers(filepath: Path) -> list[dict]:
    """Extract all final_answer entries from a JSONL file, preserving order."""
    results = []
    with open(filepath) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            if obj.get("type") != "response_item":
                continue
            payload = obj.get("payload", {})
            if payload.get("phase") != "final_answer":
                continue
            for item in payload.get("content", []):
                if item.get("type") == "output_text":
                    results.append({
                        "text": item["text"],
                        "timestamp": obj.get("timestamp", ""),
                    })
                    break
    return results


def main():
    offset = 0
    args = sys.argv[1:]
    if "--offset" in args:
        idx = args.index("--offset")
        offset = int(args[idx + 1])

    if not SESSIONS_DIR.exists():
        print(json.dumps({"error": f"Codex sessions directory not found: {SESSIONS_DIR}"}))
        sys.exit(1)

    jsonl_path = find_latest_jsonl(SESSIONS_DIR)
    if not jsonl_path:
        print(json.dumps({"error": "No .jsonl files found in Codex sessions"}))
        sys.exit(1)

    answers = extract_final_answers(jsonl_path)
    if not answers:
        print(json.dumps({"error": f"No final_answer found in {jsonl_path}"}))
        sys.exit(1)

    target_idx = len(answers) - 1 - offset
    if target_idx < 0:
        print(json.dumps({"error": f"Only {len(answers)} final_answers found, offset {offset} is too large"}))
        sys.exit(1)

    answer = answers[target_idx]
    output = {
        "source_file": str(jsonl_path),
        "total_final_answers": len(answers),
        "selected_index": target_idx,
        "timestamp": answer["timestamp"],
        "text": answer["text"],
    }
    print(json.dumps(output, ensure_ascii=False))


if __name__ == "__main__":
    main()
