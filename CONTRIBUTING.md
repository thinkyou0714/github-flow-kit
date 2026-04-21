# Contributing to github-flow-kit

## Customize Skills for Your Repo

Add a `references/custom-rules.md` inside any skill directory to override defaults:

```bash
mkdir -p ~/.claude/skills/pr-respond/references/
cat > ~/.claude/skills/pr-respond/references/custom-rules.md << 'EOF'
# Custom PR Review Rules

## Classification Overrides
- Comments with "[perf]" prefix → always MUST-FIX
- Comments from @your-lead → always MUST-FIX

## Response Language
Always respond in English.

## Commit Message Format
Use: "fix(scope): message" — scope = directory of changed file.
EOF
```

Claude Code loads `references/` as context automatically.

---

## Improve references/ (Most Valuable Contribution)

Found a comment pattern that was misclassified? Open an Issue with label `references-improvement`:

1. Paste the comment text
2. State the expected classification
3. State the actual classification

We update `references/*.md` within 7 days. Your handle goes in CONTRIBUTORS.

---

## Add a New Skill

```bash
# 1. Fork + Clone
gh repo fork thinkyou0714/github-flow-kit --clone
cd github-flow-kit

# 2. Create skill directory
mkdir -p my-new-skill/references

# 3. Write SKILL.md
cat > my-new-skill/SKILL.md << 'EOF'
---
name: my-new-skill
description: >-
  [What this skill does — max 1536 chars]
  Use when: ...
  Triggers on: ...
  DO NOT USE FOR: ...
allowed-tools: Bash(git *) Read Grep
context: fork
model: claude-sonnet-4-6
effort: medium
---

# My New Skill

[Instructions here]
EOF

# 4. PR
gh pr create --title "Add my-new-skill: [one-line description]"
```

## PR Acceptance Criteria

- [ ] SKILL.md has `name`, `description`, `allowed-tools`
- [ ] `description` is under 1,536 characters
- [ ] `context: fork` is set (required for skills with side effects)
- [ ] All referenced `references/*.md` files exist
- [ ] CI (skill-validate.yml) passes
- [ ] README Skills table updated

---

## Report a Bug

Open an [Issue](https://github.com/thinkyou0714/github-flow-kit/issues/new/choose) using the Bug Report template. Include:
- `gh --version`
- `gh auth status`
- `claude --version`
- The exact command you ran
- What you expected vs. what happened
