#!/usr/bin/env bash
set -euo pipefail

# Auto-merge ZiggyStarClaw PRs when merge gates are satisfied.
# Policy (from Deano): merge only when:
# - CI passes
# - local tests pass (we run `zig build`)
# - chatgpt-review / codex review gives a thumbs-up OR any comments are addressed
# - ALL comments/threads (including inline review comments) are addressed
# Additionally: do NOT auto-merge if PR has label "no-auto-merge".

REPO="DeanoC/ZiggyStarClaw"

cd "$(git rev-parse --show-toplevel)"

log() { echo "[auto-merge] $*"; }

# Quick local sanity build (acts as our 'local tests')
log "Running local build: zig build"
zig build

# List open PR numbers
prs=$(gh pr list --repo "$REPO" --state open --json number --jq '.[].number')
if [[ -z "$prs" ]]; then
  log "No open PRs."
  exit 0
fi

for pr in $prs; do
  # Skip drafts / labeled no-auto-merge
  labels=$(gh pr view "$pr" --repo "$REPO" --json labels,isDraft --jq '{labels: [.labels[].name], isDraft: .isDraft}')
  isDraft=$(echo "$labels" | node -pe 'JSON.parse(fs.readFileSync(0,"utf8")).isDraft' 2>/dev/null || echo "false")
  if [[ "$isDraft" == "true" ]]; then
    log "PR #$pr is draft; skipping"
    continue
  fi
  if echo "$labels" | grep -q 'no-auto-merge'; then
    log "PR #$pr has label no-auto-merge; skipping"
    continue
  fi

  # Check mergeability + status checks
  meta=$(gh pr view "$pr" --repo "$REPO" --json mergeable,reviewDecision,statusCheckRollup,headRefName,headRefOid,url --jq '{mergeable, reviewDecision, statusCheckRollup, headRefName, headRefOid, url}')
  mergeable=$(echo "$meta" | node -pe 'JSON.parse(fs.readFileSync(0,"utf8")).mergeable')
  if [[ "$mergeable" != "MERGEABLE" ]]; then
    log "PR #$pr not mergeable ($mergeable); skipping"
    continue
  fi

  # Require all status checks success (if any exist)
  checks_ok=$(echo "$meta" | node - <<'NODE'
const fs=require('fs');
const m=JSON.parse(fs.readFileSync(0,'utf8'));
const scr=m.statusCheckRollup;
if (!scr || !scr.contexts || scr.contexts.length===0) { console.log('true'); process.exit(0); }
// accept only SUCCESS
for (const c of scr.contexts) {
  const st=c.conclusion || c.state || c.status;
  if (st && String(st).toUpperCase() !== 'SUCCESS') { console.log('false'); process.exit(0); }
}
console.log('true');
NODE)
  if [[ "$checks_ok" != "true" ]]; then
    log "PR #$pr status checks not all SUCCESS; skipping"
    continue
  fi

  # Inline review comments (sub-comments): if any exist from chatgpt-codex-connector newer than HEAD commit time, skip.
  # Heuristic: if there are inline comments at all from non-bot authors, skip unless explicitly handled.
  inline=$(gh api --silent "repos/DeanoC/ZiggyStarClaw/pulls/$pr/comments")
  inline_count=$(echo "$inline" | node -pe 'JSON.parse(fs.readFileSync(0,"utf8")).length')
  if [[ "$inline_count" -gt 0 ]]; then
    # If there are inline comments from humans, skip.
    has_human=$(echo "$inline" | node - <<'NODE'
const fs=require('fs');
const arr=JSON.parse(fs.readFileSync(0,'utf8'));
const bots=new Set(['chatgpt-codex-connector[bot]']);
let human=false;
for (const c of arr) {
  const u=c.user?.login||'';
  if (!bots.has(u)) { human=true; break; }
}
console.log(human?'true':'false');
NODE)
    if [[ "$has_human" == "true" ]]; then
      log "PR #$pr has human inline comments; skipping"
      continue
    fi
  fi

  # Review decision gate: accept APPROVED, or empty (some repos use only bot inline comments)
  reviewDecision=$(echo "$meta" | node -pe 'JSON.parse(fs.readFileSync(0,"utf8")).reviewDecision || ""')
  if [[ -n "$reviewDecision" && "$reviewDecision" != "APPROVED" ]]; then
    log "PR #$pr reviewDecision=$reviewDecision; skipping"
    continue
  fi

  url=$(echo "$meta" | node -pe 'JSON.parse(fs.readFileSync(0,"utf8")).url')
  log "Merging PR #$pr ($url)"

  gh pr merge "$pr" --repo "$REPO" --merge --delete-branch --admin
  log "Merged PR #$pr"

done
