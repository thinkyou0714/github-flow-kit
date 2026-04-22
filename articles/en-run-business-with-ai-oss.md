---
title: "Running Half Your Business with AI and Open Source Tools"
emoji: "🤖"
type: "tech"
topics: ["claudecode", "n8n", "obsidian", "automation", "productivity"]
published: false
---

Using AI to run half your business isn't just a dream — it's achievable today with open-source tools. This article shows you the exact setup I use: n8n for automation, Obsidian for AI memory, and Claude Code for hands-on development work.

---

## The Viral Post That Inspired This

A post titled "I gave AI a brain, and now it runs half my business" went viral recently. The setup: Claude Cowork (paid SaaS) + Obsidian MCP + Google Drive to build an AI that extracts context from meetings and operates autonomously.

The result was impressive. But the toolchain costs $50–100/month and requires proprietary services.

I replicated the same outcome using only open-source tools — at zero marginal cost.

---

## What "Running Half Your Business" Actually Means

Before diving into setup, let's be concrete about what gets automated vs. what stays human.

**Automated (AI handles these):**
- Daily information gathering and summarization
- PR review comment responses
- Issue backlog prioritization
- Release note generation
- GitHub activity digests
- Session notes → vault storage

**Human (still requires judgment):**
- Product direction decisions
- Customer relationship management
- Code architecture for new features
- Publishing and marketing strategy

The goal isn't to replace human judgment — it's to eliminate the 3-4 hours/week of mechanical work that doesn't require it.

---

## The Four-Pillar Architecture

```
┌─────────────────────────────────────────────────┐
│              Your Business Operations            │
│                                                  │
│  n8n (Orchestration)                             │
│    ↓ Webhook / Schedule triggers                 │
│  Obsidian Vault (Memory)                         │
│    ↓ Context injection via REST API              │
│  Claude Code (Execution)                         │
│    ↓ Code changes, PR responses, analysis        │
│  GitHub (Output)                                 │
└─────────────────────────────────────────────────┘
```

### Pillar 1: n8n — The Orchestration Layer

n8n runs on your local machine (or VPS) and connects everything via webhooks, schedules, and HTTP requests. No vendor lock-in. No per-workflow pricing.

**My active workflows (20+):**

| Workflow | Trigger | Action |
|---|---|---|
| Daily brief | Cron 09:00 JST | GitHub activity + Slack digest |
| PR alert | GitHub webhook | Slack notification → Claude Code |
| Weekly triage | Cron Monday 10:00 JST | Issue scoring → Slack TOP 5 |
| Release monitor | Cron daily | New releases → Slack notification |
| Session save | n8n HTTP | Claude session → Obsidian vault |

**Install n8n (self-hosted, WSL2):**

```bash
# Using Docker
docker run -it --rm \
  -p 5679:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n

# Or via npm
npm install -g n8n
n8n start
```

Access at `http://localhost:5679`.

### Pillar 2: Obsidian Vault — The AI's Memory

Obsidian stores everything the AI needs to know about your business in plain markdown files.

The three files that make AI context-aware:

**`99_meta/AI-DATA-RULES.md`** — defines where AI can and cannot write:
```markdown
## Zone A (AI-read-only)
- 00_INBOX/ — raw captures, do not modify
- 99_meta/ — rules and config

## Zone B (AI-write-allowed)
- 02_AREAS/dev-log/ — session logs
- 05_PROJECTS/ — project notes

## Zone C (human-only)
- 01_PROJECTS/finances/
- personal/
```

**`99_meta/LANE-SPEC.md`** — role definitions:
```markdown
# Lane Specification
LANE-WF: n8n workflows (data collection, transformation, storage)
LANE-CLAUDE: Claude Code (code execution, analysis, PR work)
LANE-HUMAN: Architecture decisions, publishing, business strategy
```

**`60_RULES_SOURCE/brand-voice.md`** — tone definition for all AI outputs:
```markdown
# Brand Voice
- Direct and technical, no corporate speak
- First-person ("I") when appropriate
- No excessive hedging ("I think", "perhaps")
- Code examples over explanations whenever possible
```

Without these files, AI operates without context — useful but not persistent.

### Pillar 3: Claude Code + MEMORY.md

Claude Code sessions pick up context from `~/.claude/projects/*/memory/MEMORY.md` at the start of every session. This means the AI knows your project state, conventions, and recent work without you re-explaining it every time.

The key MEMORY.md sections:
- Project status (what's done, what's next)
- Architecture decisions (why certain choices were made)
- Feedback patterns (what corrections the AI has received)
- Human tasks (what requires human action)

This is the equivalent of Claude Cowork's "brain" — except it's a local markdown file you control.

### Pillar 4: Obsidian REST API Plugin

Install the [Local REST API plugin](https://github.com/coddingtonbear/obsidian-local-rest-api) in Obsidian. This enables:
- n8n workflows to write session logs directly to the vault
- Claude Code to read project context from Obsidian
- Automated note creation without opening Obsidian manually

One limitation: Obsidian must be running for the REST API to work. On Windows/WSL2, run Obsidian in the background and leave it open.

---

## Step-by-Step Setup (30 Minutes)

### Step 1: Create MEMORY.md

```bash
mkdir -p ~/.claude/projects/your-project/memory
cat > ~/.claude/projects/your-project/memory/MEMORY.md << 'EOF'
# MEMORY — Your Project

## Project Status
- Main stack: [your stack]
- Current phase: [what you're working on]

## Conventions
- [coding style notes]
- [git commit format]

## Human Tasks
- [things only you can do]
EOF
```

Claude Code will load this at session start.

### Step 2: Set Up n8n with One Core Workflow

Start with the Daily GitHub Brief workflow:

1. Open n8n at `http://localhost:5679`
2. Create new workflow: **Daily Brief**
3. Add nodes:
   - `Schedule Trigger` → cron `0 9 * * *` (9 AM daily)
   - `HTTP Request` → `https://api.github.com/users/YOUR_USERNAME/events`
   - `Code` → filter last 24h events, format as markdown
   - `Slack` → post to your `#daily-brief` channel

This takes 15 minutes to set up and saves 30 minutes of manual review daily.

### Step 3: Add github-flow-kit to Your Claude Code Setup

Install the 4 automation skills:

```bash
for skill in pr-respond release-notes issue-triage repo-tour; do
  gh skill install thinkyou0714/github-flow-kit $skill \
    --agent claude-code --scope user
done
```

These integrate directly with your GitHub workflows:
- When n8n sends a PR alert to Slack, open Claude Code and run `/pr-respond`
- Before every sprint, run `/issue-triage` to prioritize your backlog
- After every release, run `/release-notes` for the changelog

### Step 4: Connect n8n to Obsidian

Install [Local REST API plugin](https://github.com/coddingtonbear/obsidian-local-rest-api) in Obsidian, then enable it and copy the API key.

In n8n, create a session-save workflow:
1. `Webhook` trigger (POST `/save-session`)
2. `HTTP Request` → POST to `http://localhost:27123/vault/02_AREAS/dev-log/{{date}}.md`
   - Auth: Bearer `[your obsidian api key]`
   - Body: session content

Now Claude Code can append session summaries directly to your vault.

---

## Cost Breakdown

| Tool | Cost | Notes |
|---|---|---|
| n8n (self-hosted) | $0/month | Runs on your machine or a $5 VPS |
| Obsidian | $0 | Free for personal use |
| Claude Code | ~$20/month | Claude API usage via Claude.ai Pro |
| github-flow-kit | $0 | Open source, MIT license |
| **Total** | **~$20/month** | vs. $50-100+ for SaaS equivalents |

The main cost is Claude API usage. With smart automation, most routine work costs $0.10-0.50/day.

---

## What This Setup Automates

After 3 months of running this system, here's what I no longer do manually:

| Task | Before | After |
|---|---|---|
| PR review responses | 50 min/PR | 3 min (Claude Code `/pr-respond`) |
| Daily GitHub digest | 20 min | 0 min (n8n → Slack) |
| Issue prioritization | 60 min/week | 5 min (Claude Code `/issue-triage`) |
| Release notes | 30 min/release | 2 min (Claude Code `/release-notes`) |
| Session summaries | 10 min/session | 0 min (n8n webhook → Obsidian) |

Weekly time saved: **~4 hours**. Monthly: **~16 hours**.

---

## Limitations and Workarounds

**Obsidian must stay open**: The REST API plugin only works while Obsidian is running. Solution: configure Obsidian to start on login.

**Claude API downtime**: Rare but it happens. When it does, manual fallback to git log / GitHub UI. No data is lost since everything is version controlled.

**n8n workflow maintenance**: Workflows occasionally need updates when APIs change. Budget 1-2 hours/quarter for maintenance.

---

## Start Small

You don't need to implement everything at once. The minimal viable setup:

1. **Week 1**: Create MEMORY.md → notice how Claude Code maintains context
2. **Week 2**: Install github-flow-kit → `/pr-respond` on the next PR review
3. **Week 3**: Set up one n8n workflow (Daily Brief)
4. **Week 4**: Add Obsidian REST API → session logging

Each step independently saves time. Together, they compound.

---

## More Tools from This Stack

- **github-flow-kit**: 4 Claude Code skills for GitHub automation → [Star on GitHub](https://github.com/thinkyou0714/github-flow-kit)
- **ccmux**: Never lose a Claude Code session to SSH timeouts → `npm install -g ccmux`
- **Zenn Book** (coming): Full guide to this stack with templates → [github-flow-kit/books](https://github.com/thinkyou0714/github-flow-kit/tree/main/books)

---

*All tools mentioned are open source. No affiliate links.*
