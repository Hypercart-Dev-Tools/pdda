# Phased Playbook for Repo-Driven Documentation Governance Automation

This document describes a low-effort, pragmatic rollout plan for using an agentic model such as Agents-A1 to monitor repository changes, propose or apply documentation updates in an isolated git worktree, and gradually graduate from PR-only changes to direct local commits for low-risk documentation categories. [huggingface](https://huggingface.co/InternScience/Agents-A1)

## Goal

The objective is to keep documentation, ADRs, runbooks, and governance artifacts aligned with code changes without letting the system directly mutate the primary working tree too early. The recommended model is a single pipeline with the same review logic in every phase, while the final action changes over time from dry-run, to PR creation, to narrowly-scoped local auto-commit for trusted low-risk categories. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook)

## Two path plans

### Path A: Pragmatic event-driven pipeline

This is the recommended path because it is simpler, cheaper, and easier to trust. A repo event such as a merge to `main` or a push to the primary branch triggers a small script that builds context from the diff, asks the model whether docs should change, applies edits inside a git worktree, runs checks, and opens a PR or creates a local commit depending on policy. [dev](https://dev.to/nickytonline/git-worktrees-git-done-right-2p7f)

**Why this path is best first:**

- It uses git worktrees for isolation instead of inventing a second repo-management system. [dev](https://dev.to/bagniz/simplify-your-git-workflow-with-git-worktree-2pea)
- It keeps the model in a constrained tool-using role with explicit inputs and outputs. [databricks](https://www.databricks.com/blog/introducing-structured-outputs-batch-and-agent-workflows)
- It aligns with agent observability guidance that emphasizes logs, traces, and evaluation before expanding autonomy. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation)
- It supports a clean maturity ladder from review-only to selective autonomy without architectural churn. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation)

### Path B: Always-on local daemon

This path runs a local watcher continuously, notices changes or commits, classifies whether a governance update may be needed, and stages changes proactively in the background. It is attractive in theory, but it adds runtime concerns such as file-watch debounce logic, long-lived model serving, loop prevention, retry behavior, and more noise management, so it should come later if the event-driven path proves valuable. [huggingface](https://huggingface.co/learn/cookbook/en/agents)

**Use this only after Path A is working well.** The main benefit is immediacy, but the cost is extra operational complexity relative to the value of the first version. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook)

## Recommended implementation

Build **Path A** first and design it so that Phase 2 only swaps the finalizer behavior. That means one orchestrator, one prompt contract, one validation layer, and one policy engine, with a final action of either `dry_run`, `open_pr`, or `local_commit`. [xebia](https://xebia.com/blog/how-to-get-the-most-out-of-your-agents-part-i/)

The recommended pipeline is:

1. Detect a relevant repo event such as merge to `main` or post-merge local hook. [dev](https://dev.to/nickytonline/git-worktrees-git-done-right-2p7f)
2. Create a git worktree on a temporary branch for the automation run. [dev](https://dev.to/bagniz/simplify-your-git-workflow-with-git-worktree-2pea)
3. Build a small context pack from the diff and a few governance references. [huggingface](https://huggingface.co/InternScience/Agents-A1)
4. Ask the model for structured output describing whether changes are needed, where, why, and with what risk level. [databricks](https://www.databricks.com/blog/introducing-structured-outputs-batch-and-agent-workflows)
5. Apply edits only inside allowlisted documentation paths. [huggingface](https://huggingface.co/InternScience/Agents-A1)
6. Run deterministic checks such as markdown lint, link validation, path validation, and simple rule assertions. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook)
7. Finalize as either a PR or a local commit depending on the policy gate and trust score for that change category. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation)

## Operating phases

### Phase 0: Dry-run

In Phase 0, the system never writes files. It classifies diffs, identifies candidate doc targets, and emits a structured recommendation such as “would update README and runbook because auth permissions changed,” along with a rationale and confidence score. [xebia](https://xebia.com/blog/how-to-get-the-most-out-of-your-agents-part-i/)

**Exit criteria for Phase 0:**

- At least 10 to 20 reviewed runs across real commits. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook)
- Low false-positive rate for irrelevant doc suggestions. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation)
- Stable targeting of doc files inside the intended allowlist. [huggingface](https://huggingface.co/InternScience/Agents-A1)

### Phase 1: PR-only doc changes

In Phase 1, the system writes changes only inside a git worktree and always surfaces them as a PR for human review. This phase is the default operating mode and should remain the fallback even after Phase 2 exists. [dev](https://dev.to/nickytonline/git-worktrees-git-done-right-2p7f)

**Phase 1 rules:**

- Always use a temporary automation branch, for example `docgov/<short-sha>`. [dev](https://dev.to/nickytonline/git-worktrees-git-done-right-2p7f)
- Never edit the primary working tree directly. [dev](https://dev.to/bagniz/simplify-your-git-workflow-with-git-worktree-2pea)
- Restrict writes to an allowlist such as `docs/**`, `adr/**`, `README.md`, `SECURITY.md`, `compliance/**`, and `runbooks/**`. [huggingface](https://huggingface.co/InternScience/Agents-A1)
- Require all checks to pass before opening the PR. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook)

**Why Phase 1 matters:**

PR-only flow builds a review corpus that can later be used to judge which kinds of changes are safe enough for direct local commits. It also gives a concrete acceptance metric by category, which is a much better trust signal than general intuition. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation)

### Phase 2: Selective local auto-commit

In Phase 2, the system can directly create local commits, but only for narrowly-scoped low-risk documentation categories that have earned trust through Phase 1 performance. The same worktree flow should still be used first, with the only difference being that successful changes can be committed locally instead of opened as a PR. [databricks](https://www.databricks.com/blog/introducing-structured-outputs-batch-and-agent-workflows)

**Important constraint:** Phase 2 should not mean “full autonomy.” It should mean “safe autopilot for boring doc maintenance.” [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook)

Eligible examples may include:

- README command usage sync. [discuss.huggingface](https://discuss.huggingface.co/t/looking-for-simple-ways-to-evaluate-an-ai-agent/175062)
- Internal runbook touchups that do not change policy meaning. [discuss.huggingface](https://discuss.huggingface.co/t/looking-for-simple-ways-to-evaluate-an-ai-agent/175062)
- Link fixes, generated indexes, glossary additions, or small code-sample updates. [discuss.huggingface](https://discuss.huggingface.co/t/looking-for-simple-ways-to-evaluate-an-ai-agent/175062)
- Changelog or release-note alignment where the source of truth is already deterministic. [discuss.huggingface](https://discuss.huggingface.co/t/looking-for-simple-ways-to-evaluate-an-ai-agent/175062)

Still PR-only examples should include:

- Security policy documents. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation)
- Compliance controls, audit mappings, retention language, or privacy docs. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook)
- ADRs and architectural intent changes. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook)
- Anything involving permissions, auth, RBAC, external behavior, or customer commitments. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation)

## Policy gate

The model may recommend an action, but policy code should make the final decision. This keeps the autonomy boundary deterministic and auditable. [xebia](https://xebia.com/blog/how-to-get-the-most-out-of-your-agents-part-i/)

A simple policy function should evaluate:

| Input | Example rule | Action impact |
|---|---|---|
| Changed code area | `auth/`, `api/`, `schema/`, `infra/` touched | Increase likelihood docs need review. [huggingface](https://huggingface.co/InternScience/Agents-A1) |
| Proposed edit targets | Must stay inside doc allowlist | Block direct commit if outside allowlist. [huggingface](https://huggingface.co/InternScience/Agents-A1) |
| Risk level | `low`, `medium`, `high` from model output | `high` always forces PR. [databricks](https://www.databricks.com/blog/introducing-structured-outputs-batch-and-agent-workflows) |
| Diff size | More than 50 to 100 changed doc lines | Force PR. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation) |
| File count | More than 3 to 5 doc files changed | Force PR. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation) |
| Trust score by category | Must exceed threshold | Allow `local_commit` only for trusted categories. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook) |
| Check results | Lint or link check fails | Block write or downgrade to review. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook) |

A practical default policy is:

- `dry_run` when confidence is low, targeting is unclear, or checks cannot run cleanly. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation)
- `open_pr` for all medium- and high-risk changes, and for all new categories. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook)
- `local_commit` only for low-risk categories that have proven stable acceptance in Phase 1. [databricks](https://www.databricks.com/blog/introducing-structured-outputs-batch-and-agent-workflows)

## Trust model

Trust should be tracked by **change category**, not globally. A README sync task and a security-controls update are not comparable risk classes, so they should not share the same promotion threshold. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation)

A minimal trust registry can look like this:

| Category | Reviewed runs | Accepted | Acceptance rate | Serious misses | Eligible for local commit |
|---|---:|---:|---:|---:|---|
| README usage sync | 20 | 18 | 90% | 0 | Yes after threshold. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook) |
| Runbook minor edits | 15 | 13 | 87% | 0 | Yes after threshold. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook) |
| ADR updates | 8 | 5 | 62% | 1 | No. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook) |
| Security policy changes | 7 | 6 | 86% | 1 | No, due to risk class. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation) |

A pragmatic promotion rule is:

- Keep a category in PR mode until it has at least 10 reviewed runs. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook)
- Promote to local-commit eligible only if acceptance is at least 85 to 90 percent and there were no serious misses in the last 5 runs. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation)
- Immediately demote to PR mode after one material error, such as incorrect policy language, wrong behavioral description, or edits outside intended scope. [arize](https://arize.com/blog/best-ai-observability-tools-for-autonomous-agents-in-2026/)

## Concrete playbook

### Trigger rules

Start with a small set of meaningful triggers rather than watching every file indiscriminately. Good first triggers include: [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook)

- Auth, RBAC, or permission layer changes. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook)
- API contract or schema changes. [huggingface](https://huggingface.co/InternScience/Agents-A1)
- Data retention, logging, audit, or compliance-related code changes. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook)
- Infra or deployment changes that affect operational runbooks. [discuss.huggingface](https://discuss.huggingface.co/t/looking-for-simple-ways-to-evaluate-an-ai-agent/175062)
- User-facing CLI or setup changes that should sync to the README. [discuss.huggingface](https://discuss.huggingface.co/t/looking-for-simple-ways-to-evaluate-an-ai-agent/175062)

### Allowlisted write paths

Use a strict write allowlist from day one. Example: [huggingface](https://huggingface.co/InternScience/Agents-A1)

```text
docs/**
adr/**
runbooks/**
README.md
SECURITY.md
compliance/**
```

Everything else is read-only to the automation layer. [huggingface](https://huggingface.co/InternScience/Agents-A1)

### Suggested structured output schema

Use structured output instead of freeform text so the orchestration code can behave predictably. [xebia](https://xebia.com/blog/how-to-get-the-most-out-of-your-agents-part-i/)

```json
{
  "should_update": true,
  "mode_recommendation": "open_pr",
  "risk": "low",
  "category": "readme_usage_sync",
  "targets": ["README.md", "docs/setup/local-dev.md"],
  "reason": "CLI flag changed and setup instructions are now stale.",
  "summary": "Update setup commands and add note about new auth flag.",
  "confidence": 0.91
}
```

The orchestrator should parse this output, run policy logic, and decide whether to write nothing, open a PR, or create a local commit. [databricks](https://www.databricks.com/blog/introducing-structured-outputs-batch-and-agent-workflows)

### Worktree flow

A minimal worktree flow is enough: [dev](https://dev.to/bagniz/simplify-your-git-workflow-with-git-worktree-2pea)

```bash
git fetch origin
git worktree add ../repo-docgov-$SHA -b docgov/$SHA origin/main
cd ../repo-docgov-$SHA
```

Then run the automation only inside that worktree, never in the primary working tree. [dev](https://dev.to/nickytonline/git-worktrees-git-done-right-2p7f)

### Finalizer behavior

Implement one finalizer interface with two concrete modes: [databricks](https://www.databricks.com/blog/introducing-structured-outputs-batch-and-agent-workflows)

- `open_pr`: commit in the worktree branch and push for review. [dev](https://dev.to/nickytonline/git-worktrees-git-done-right-2p7f)
- `local_commit`: commit locally on a dedicated automation branch after checks pass. [futurepixels.co](https://futurepixels.co.uk/posts/improving-my-productivity-and-context-switching-with-git-worktrees/)

Even in `local_commit` mode, it is still wise to commit on a dedicated branch such as `local-docgov/<category>` rather than directly onto the user’s active feature branch. [futurepixels.co](https://futurepixels.co.uk/posts/improving-my-productivity-and-context-switching-with-git-worktrees/)

## Minimal implementation stack

The least-overengineered stack is: [huggingface](https://huggingface.co/learn/cookbook/en/agents)

- One Python script for orchestration and policy. [huggingface](https://huggingface.co/learn/cookbook/en/agents)
- One GitHub Action or post-merge local hook as the trigger. [dev](https://dev.to/nickytonline/git-worktrees-git-done-right-2p7f)
- One local model endpoint backed by MLX Agents-A1 or an equivalent wrapped command. [huggingface](https://huggingface.co/InternScience/Agents-A1)
- One JSON file or SQLite table for trust tracking by category. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook)
- Standard CLI checks such as markdown lint and link validation. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook)

There is no need for a message bus, workflow engine, or multi-agent graph in the first version. A compact script plus deterministic rules is enough to prove whether the workflow delivers useful doc hygiene. [huggingface](https://huggingface.co/learn/cookbook/en/agents)

## Suggested week-one rollout

### Day 1

Define:

- Write allowlist. [huggingface](https://huggingface.co/InternScience/Agents-A1)
- Trigger rules. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/monitoring-and-evaluating-agents-notebook)
- Risk categories and doc categories. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation)
- Structured output schema. [xebia](https://xebia.com/blog/how-to-get-the-most-out-of-your-agents-part-i/)

### Day 2

Build the script stages:

- Collect diff.
- Build context pack.
- Invoke model.
- Parse structured output.
- Apply edits in worktree.
- Run checks. [huggingface](https://huggingface.co/learn/cookbook/en/agents)

### Day 3

Add Phase 0 dry-run mode and Phase 1 PR finalizer. Log every run with category, confidence, selected targets, policy decision, and check results. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation)

### Day 4

Replay 10 to 20 recent commits and manually score the outcomes by category. Use that dataset to tighten triggers, path rules, and prompt wording. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation)

### Day 5

Enable live PR creation for one or two low-risk categories first, such as README usage sync and internal runbook touchups. Keep everything else in PR mode or dry-run until acceptance data justifies graduation. [discuss.huggingface](https://discuss.huggingface.co/t/looking-for-simple-ways-to-evaluate-an-ai-agent/175062)

## Recommended default policy

The most practical default is:

- Phase 0 for initial tuning and replay testing. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation)
- Phase 1 as the normal operating mode for most categories. [huggingface](https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation)
- Phase 2 only for boring, repetitive, low-risk doc maintenance with proven acceptance history. [databricks](https://www.databricks.com/blog/introducing-structured-outputs-batch-and-agent-workflows)

This preserves trust while still giving a believable path to future autonomy. It also avoids building two systems, because the same orchestrator, worktree flow, structured outputs, checks, and policy code are reused throughout the rollout. [dev](https://dev.to/nickytonline/git-worktrees-git-done-right-2p7f)