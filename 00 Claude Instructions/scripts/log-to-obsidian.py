#!/usr/bin/env python3
"""
Claude Code セッション transcript (jsonl) を Obsidian Vault の日次 Markdown に集約する。

実行方法:
  1) Stop hook から: stdin に { "transcript_path": "...", ... } JSON を渡す
  2) 手動: log-to-obsidian.py <transcript.jsonl> [<transcript.jsonl> ...]
  3) 一括: log-to-obsidian.py --all

ロジック:
  - 各 jsonl のレコードを (date, session_id) でグルーピング
  - 同じ日付に複数セッションあれば 1ファイルにまとめる
  - 該当する Vault/Claude Logs/YYYY-MM-DD.md を再生成 (上書き)
  - 既存ファイルは .bak.<timestamp> にバックアップ (--all 実行時の初回のみ)
"""

import datetime as dt
import glob
import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path


HOME = Path.home()
PROJECTS_DIR = HOME / ".claude" / "projects"
VAULT_GLOB = HOME / "Library" / "CloudStorage"
LOGS_SUBDIR = "Obsidian Vault/Claude Logs"


def find_vault_logs_dir() -> Path:
    for p in VAULT_GLOB.glob("GoogleDrive-*"):
        candidate = p / "マイドライブ" / LOGS_SUBDIR
        if candidate.parent.is_dir():
            candidate.mkdir(exist_ok=True)
            return candidate
    raise SystemExit(
        f"Vault not found under {VAULT_GLOB}/GoogleDrive-*/マイドライブ/Obsidian Vault/"
    )


def extract_text(content) -> str:
    """user / assistant の message.content から text 部分だけ取り出す。"""
    if isinstance(content, str):
        return content.strip()
    if not isinstance(content, list):
        return ""
    parts = []
    for blk in content:
        if not isinstance(blk, dict):
            continue
        if blk.get("type") == "text":
            t = blk.get("text", "")
            if t:
                parts.append(t)
        # thinking / tool_use / tool_result / image はスキップ
    return "\n\n".join(parts).strip()


def parse_jsonl(path: Path):
    """jsonl をパースして (timestamp, session_id, role, text, meta) のリストを返す。"""
    items = []
    session_meta = {}  # session_id -> {"title": ..., "cwd": ..., "first_ts": ...}
    if not path.exists():
        return items, session_meta
    try:
        with path.open() as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    d = json.loads(line)
                except json.JSONDecodeError:
                    continue
                t = d.get("type")
                sid = d.get("sessionId") or d.get("message", {}).get("sessionId")

                if t in ("user", "assistant"):
                    msg = d.get("message", {})
                    text = extract_text(msg.get("content", ""))
                    if not text:
                        continue
                    # tool_result だけの user メッセージはスキップ済み
                    ts = d.get("timestamp")
                    cwd = d.get("cwd")
                    if sid and cwd and sid not in session_meta:
                        session_meta[sid] = {"cwd": cwd, "first_ts": ts}
                    elif sid and ts and session_meta.get(sid, {}).get("first_ts") is None:
                        session_meta[sid]["first_ts"] = ts
                    items.append((ts, sid, t, text))
                elif t in ("custom-title", "ai-title"):
                    title = d.get("customTitle") or d.get("aiTitle") or d.get("title")
                    if sid and title:
                        session_meta.setdefault(sid, {})["title"] = title
    except (OSError, UnicodeDecodeError) as e:
        print(f"warn: failed to read {path}: {e}", file=sys.stderr)
    return items, session_meta


def strip_system_reminders(text: str) -> str:
    """<system-reminder>...</system-reminder> ブロックを除去。"""
    return re.sub(r"<system-reminder>.*?</system-reminder>\s*", "", text, flags=re.DOTALL).strip()


def parse_ts(ts: str):
    if not ts:
        return None
    try:
        return dt.datetime.fromisoformat(ts.replace("Z", "+00:00"))
    except Exception:
        return None


def to_local_date(ts: str) -> str:
    d = parse_ts(ts)
    if not d:
        return "unknown"
    # ローカルタイムに変換
    return d.astimezone().strftime("%Y-%m-%d")


def to_local_hm(ts: str) -> str:
    d = parse_ts(ts)
    if not d:
        return "??:??"
    return d.astimezone().strftime("%H:%M")


def render_session(session_id, items, meta) -> str:
    """1セッション分の Markdown を返す。items は (ts, sid, role, text)。"""
    items.sort(key=lambda x: x[0] or "")
    first_ts = items[0][0] if items else meta.get("first_ts")
    hm = to_local_hm(first_ts)
    title = meta.get("title") or session_id[:8]
    cwd = meta.get("cwd", "?")

    lines = [
        f"## {hm} — `{title}`",
        "",
        f"**cwd:** `{cwd}`",
        f"**session:** `{session_id}`",
        "",
    ]
    for ts, sid, role, text in items:
        cleaned = strip_system_reminders(text)
        if not cleaned:
            continue
        emoji = "🧑" if role == "user" else "🤖"
        label = "User" if role == "user" else "Assistant"
        lines.append(f"### {emoji} {label}")
        lines.append("")
        lines.append(cleaned)
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def collect_all_jsonl():
    paths = []
    if PROJECTS_DIR.is_dir():
        for project in PROJECTS_DIR.iterdir():
            if not project.is_dir():
                continue
            for f in project.glob("*.jsonl"):
                paths.append(f)
    return paths


def merge_and_write(jsonl_paths, logs_dir: Path):
    """指定 jsonl から日付別 Markdown を生成して書き出す。影響された日付の集合を返す。"""
    # date -> session_id -> list of (ts, sid, role, text)
    buckets = defaultdict(lambda: defaultdict(list))
    metas = defaultdict(dict)  # session_id -> meta
    for p in jsonl_paths:
        items, smetas = parse_jsonl(p)
        for sid, m in smetas.items():
            existing = metas[sid]
            for k, v in m.items():
                if v and not existing.get(k):
                    existing[k] = v
        for ts, sid, role, text in items:
            date = to_local_date(ts)
            if not sid:
                sid = "unknown"
            buckets[date][sid].append((ts, sid, role, text))

    affected_dates = set()
    for date, sessions in buckets.items():
        if date == "unknown":
            continue
        # セッションを first_ts 昇順に
        ordered_sids = sorted(sessions.keys(), key=lambda s: (sessions[s][0][0] or ""))
        body_parts = [f"# Claude Logs — {date}", "", "#claude-log", ""]
        for sid in ordered_sids:
            body_parts.append(render_session(sid, sessions[sid], metas.get(sid, {})))
            body_parts.append("")
        out_path = logs_dir / f"{date}.md"
        out_path.write_text("\n".join(body_parts), encoding="utf-8")
        affected_dates.add(date)
    return affected_dates


def main():
    args = sys.argv[1:]
    logs_dir = find_vault_logs_dir()

    transcript_paths = []
    if "--all" in args:
        transcript_paths = collect_all_jsonl()
    elif args:
        transcript_paths = [Path(a) for a in args]
    else:
        # Stop hook 経由: stdin の JSON から transcript_path を取る
        try:
            payload = json.loads(sys.stdin.read() or "{}")
        except json.JSONDecodeError:
            payload = {}
        tp = payload.get("transcript_path")
        if tp:
            transcript_paths = [Path(tp)]
        else:
            # フォールバック: 最新のjsonlを推測
            paths = collect_all_jsonl()
            if paths:
                paths.sort(key=lambda p: p.stat().st_mtime, reverse=True)
                transcript_paths = [paths[0]]

    if not transcript_paths:
        print("no transcripts to process", file=sys.stderr)
        return 0

    affected = merge_and_write(transcript_paths, logs_dir)
    if affected:
        for d in sorted(affected):
            print(f"wrote {logs_dir / (d + '.md')}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)
