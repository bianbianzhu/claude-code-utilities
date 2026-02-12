# /// script
# requires-python = ">=3.10"
# ///
"""Extract the last final_answer from the most recent Codex session JSONL file.

Usage:
  uv run scripts/get_codex_final_answer.py --cwd <path> [--offset N]

Options:
  --cwd PATH  Only consider sessions whose cwd matches this path (required).
  --offset N  Skip the last N final_answers within the matched session (default: 0).
              Offset operates within a single session, not across sessions.
              Use --offset 1 to get the second-to-last final_answer, etc.
"""

import json
import sys
from pathlib import Path

SESSIONS_DIR = Path.home() / ".codex" / "sessions"
MAX_SESSIONS_TO_CHECK = 3


def get_all_jsonl_files(base: Path) -> list[Path]:
    """Return all .jsonl files sorted by modification time, newest first."""
    jsonl_files = list(base.rglob("*.jsonl"))
    jsonl_files.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return jsonl_files


def get_session_cwd(filepath: Path) -> str | None:
    """Read the session_meta entry and return its cwd."""
    with open(filepath) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            if obj.get("type") == "session_meta":
                return obj.get("payload", {}).get("cwd")
    return None


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


def cwd_matches(session_cwd: str | None, target_cwd: str) -> bool:
    """Compare cwds after resolving symlinks and normalizing trailing slashes."""
    if session_cwd is None:
        return False
    return Path(session_cwd).resolve() == Path(target_cwd).resolve()


def main():
    offset = 0
    cwd = None
    args = sys.argv[1:]

    if "--cwd" in args:
        idx = args.index("--cwd")
        cwd = args[idx + 1]
    if "--offset" in args:
        idx = args.index("--offset")
        offset = int(args[idx + 1])

    if not cwd:
        print(json.dumps({"error": "--cwd is required"}))
        sys.exit(1)

    if not SESSIONS_DIR.exists():
        print(json.dumps({"error": f"Codex sessions directory not found: {SESSIONS_DIR}"}))
        sys.exit(1)

    all_files = get_all_jsonl_files(SESSIONS_DIR)
    if not all_files:
        print(json.dumps({"error": "No .jsonl files found in Codex sessions"}))
        sys.exit(1)

    # Iterate through sessions, only counting cwd-matching ones toward the limit.
    matched = 0
    for jsonl_path in all_files:
        session_cwd = get_session_cwd(jsonl_path)
        if not cwd_matches(session_cwd, cwd):
            continue

        matched += 1
        answers = extract_final_answers(jsonl_path)
        if answers:
            target_idx = len(answers) - 1 - offset
            if target_idx < 0:
                print(json.dumps({
                    "error": f"Only {len(answers)} final_answers in {jsonl_path.name}, offset {offset} is too large",
                }))
                sys.exit(1)
            answer = answers[target_idx]
            print(json.dumps({
                "source_file": str(jsonl_path),
                "total_final_answers": len(answers),
                "selected_index": target_idx,
                "timestamp": answer["timestamp"],
                "text": answer["text"],
            }, ensure_ascii=False))
            return

        if matched >= MAX_SESSIONS_TO_CHECK:
            break

    if matched == 0:
        print(json.dumps({"error": f"No Codex sessions found with cwd: {cwd}"}))
    else:
        print(json.dumps({
            "error": f"No final_answer found in the last {matched} matching session(s) for cwd: {cwd}",
        }))
    sys.exit(1)


if __name__ == "__main__":
    main()
