---
title: "Rethinking the 'AI Co-worker' — A Practical Setup with n8n and Obsidian"
emoji: "⚙️"
type: "tech"
topics: ["claudecode", "n8n", "obsidian", "github", "automation"]
published: false
---

The "AI co-worker" concept has gone mainstream. But most implementations treat AI as a chat interface — you ask, it answers. The real productivity unlock is making AI a persistent actor in your workflow, not just a responsive one.

This article describes a setup where AI takes actions autonomously, based on triggers from n8n workflows and context from an Obsidian vault — without you initiating every interaction.

---

## The Problem with Chat-First AI

When you use ChatGPT or Claude in a browser, you're in what I call "request mode": you write a prompt, it responds, you start over.

The limitations are structural:
- **No memory**: Every session starts from zero
- **No triggers**: You have to remember to ask
- **No actions**: It gives text, you do the work

Paying for an AI subscription and still spending 4 hours a week on mechanical tasks means you're using a calculator as a hammer.

---

## What "Autonomous AI" Looks Like in Practice

Here's a concrete Monday morning in my current setup:

**8:00 AM** — n8n fires a scheduled workflow. It hits the GitHub API, collects the week's closed PRs and merged releases, scores all open issues, and posts a structured digest to Slack. No prompt required.

**10:00 AM** — I see a PR has 8 review comments. I open Claude Code, type `/pr-respond`, and wait 3 minutes. All 8 comments are classified, code is fixed, and replies are posted. I review the diff and push.

**Whenever** — A new GitHub release from a project I follow triggers a webhook. n8n catches it, formats a Slack notification, and adds it to my Obsidian `02_AREAS/reading-list/`.

None of these required me to write a prompt. The AI worked because triggers fired and context existed.

---

## The Architecture: Three Layers

```
Triggers (n8n) → Context (Obsidian) → Execution (Claude Code)
```

### Layer 1: Triggers — n8n as the Nervous System

n8n is a self-hosted workflow automation tool (think Zapier, but open source and free). You connect nodes: Schedule → HTTP Request → Slack → Obsidian.

Key trigger types:
- **Cron**: daily digests, weekly triage, monthly reports
- **Webhook**: GitHub events, Stripe payments, form submissions
- **HTTP Poll**: RSS feeds, API endpoints without webhook support

The critical insight: **n8n does the work even when you're not at your computer**. It runs as a background daemon, firing workflows on schedule or on event.

### Layer 2: Context — Obsidian as Persistent Memory

Claude Code doesn't remember anything between sessions by default. To make it context-aware, you need to give it context at the start of each session.

The `MEMORY.md` file at `~/.claude/projects/{project}/memory/MEMORY.md` is loaded automatically. But memory is only as useful as the system that keeps it current.

n8n keeps MEMORY.md and your vault current:
- Session logs appended via Obsidian REST API
- Weekly summaries written to the vault
- Project status updated after each n8n workflow run

The three vault files that matter most:

```
99_meta/
  AI-DATA-RULES.md    ← where AI can/cannot write
  LANE-SPEC.md        ← which AI handles which tasks
60_RULES_SOURCE/
  brand-voice.md      ← tone and style for all AI output
```

With these files in place, Claude Code knows what it's allowed to touch, what it's responsible for, and how to communicate.

### Layer 3: Execution — Claude Code + github-flow-kit

Claude Code is the execution layer. It reads from Obsidian (via MCP or direct file access), takes actions in your codebase, and writes results back.

github-flow-kit adds 4 skills that connect Claude Code to your GitHub workflow:

```bash
# Install all 4 skills
for skill in pr-respond release-notes issue-triage repo-tour; do
  gh skill install thinkyou0714/github-flow-kit $skill \
    --agent claude-code --scope user
done
```

| Skill | Trigger | Action |
|---|---|---|
| `/pr-respond` | n8n PR alert → Slack → you open Claude | Classify + fix + reply to all comments |
| `/release-notes` | After merging a release branch | Generate CHANGELOG + GitHub Release notes |
| `/issue-triage` | Weekly Monday morning | Score all issues, write TRIAGE.md |
| `/repo-tour` | First time in a new repo | Generate REPO_TOUR.md + Mermaid diagram |

---

## Before and After: Three Concrete Tasks

### Task 1: PR Review Response

**Before:**
1. Open GitHub, read each comment (5 min)
2. Find the relevant file (5 min)
3. Fix the code (20 min)
4. Write a commit message (5 min)
5. Reply to each comment explaining the fix (10 min)
6. **Total: 45 minutes**

**After:**
1. n8n sends PR alert to Slack
2. Open Claude Code, run `/pr-respond`
3. Review the diff, push
4. **Total: 5 minutes**

### Task 2: Weekly Issue Prioritization

**Before:**
1. Open GitHub issues
2. Read each one to understand severity
3. Manually sort by importance
4. Write a sprint plan
5. **Total: 60 minutes every Monday**

**After:**
1. n8n cron fires Monday 10:00 JST
2. GitHub API fetches all open issues
3. Claude Code `/issue-triage` scores each one (Impact × Effort × Urgency)
4. TRIAGE.md written to vault, Slack post with TOP 5
5. **Total: 5 minutes review time**

### Task 3: Release Notes

**Before:**
1. `git log --oneline` to see what changed
2. Categorize commits by type
3. Write user-facing summary
4. Write developer-facing summary
5. Update CHANGELOG.md
6. **Total: 30 minutes per release**

**After:**
1. `cd` to the release branch, run `/release-notes`
2. Review the generated notes, push
3. **Total: 3 minutes**

---

## The Setup Checklist

You can implement this incrementally. Start with the highest-ROI items:

**Week 1 — Foundation**
- [ ] Create `~/.claude/projects/{project}/memory/MEMORY.md`
- [ ] Install github-flow-kit: `gh skill install ... pr-respond --agent claude-code`
- [ ] Run `/pr-respond` on your next PR review

**Week 2 — Automation**
- [ ] Install n8n (Docker or npm)
- [ ] Create Daily GitHub Brief workflow (cron + HTTP + Slack)
- [ ] Create PR Alert webhook (GitHub → n8n → Slack)

**Week 3 — Memory**
- [ ] Set up Obsidian with Local REST API plugin
- [ ] Create `AI-DATA-RULES.md` and `LANE-SPEC.md`
- [ ] Configure n8n to save session logs to vault

**Week 4 — Optimization**
- [ ] Install remaining github-flow-kit skills (release-notes, issue-triage, repo-tour)
- [ ] Set up weekly-triage cron in n8n
- [ ] Review MEMORY.md and update with lessons learned

---

## What This Setup Cannot Do

Setting expectations is as important as setting up the tools.

**This setup won't:**
- Make product decisions (which features to build)
- Handle customer-facing communications without review
- Replace code review (it responds to review, but human judgment is still needed)
- Work without Obsidian running (the REST API requires the desktop app to be open)

The goal is to eliminate mechanical work, not judgment work.

---

## Cost and Maintenance

| Component | Monthly Cost | Maintenance |
|---|---|---|
| n8n (self-hosted) | $0 | ~1 hour/quarter |
| Obsidian | $0 | Minimal |
| Claude Code | ~$20 | None |
| github-flow-kit | $0 (open source) | Auto-updates via gh skill |
| **Total** | **~$20** | **~4 hours/year** |

---

## Get Started

The single highest-ROI starting point: install `pr-respond` and use it on your next PR review.

```bash
gh skill install thinkyou0714/github-flow-kit pr-respond \
  --agent claude-code --scope user
```

30 seconds to install. Save 45 minutes on your next PR review. That's the pitch.

- GitHub: [github-flow-kit](https://github.com/thinkyou0714/github-flow-kit)
- Companion tool for SSH stability: [ccmux](https://github.com/thinkyou0714/think-you-lab/tree/main/apps/ccmux)

⭐ If this was useful, a Star helps others find it.
