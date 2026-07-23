# PDDA — Project-Driven Doc Automation

PDDA keeps a repo's project plans, bug-fix docs, and roadmap honest enough that a human *or an agent*
can pick up work with minimal drift. Deterministic shell checks enforce the parts that should never
need judgment (frontmatter, an exact status table, no hardcoded paths, a pointer-only roadmap); an
opt-in LLM pass flags the fuzzier readiness gaps. It starts **non-blocking** and you graduate it onto
the rails deliberately.

This is the standalone **source-of-truth installer repo**. The repo also dogfoods itself — its own
`ROADMAP.md`, `CHANGELOG.md`, and `PROJECT/**` docs are live PDDA artifacts, so it doubles as a
working demo.

---

## Install into your repo

PDDA installs *into* your existing project repo — you don't build your app in here.

```bash
# 1. clone this repo
git clone https://github.com/Hypercart-Dev-Tools/pdda.git
cd pdda

# 2. install into your project (zero state, ready to use)
./install.sh /path/to/your-repo
```

That copies the runtime + contract, creates the `PROJECT/**` lifecycle tree, drops blank seed
`ROADMAP.md` / `CHANGELOG.md` / `PROJECT/PDDA-ACTIVITY.jsonl` / `.pdda-mode` files (it never copies
this repo's own content), makes the scripts executable, and runs `pdda.sh run` so you see it working
immediately.

Installer options:

```text
--force                overwrite existing seed files (your real PROJECT/** docs are never touched)
--with-startup-docs    also install adapted ROUTER.md + AGENTS.md + GUIDING-PRINCIPLES.md (agent read-order scaffold)
--mode observe|light|full   initial enforcement mode (default: observe)
--quad                      enable the opt-in Quad Concepts layer (off by default; see below)
-h, --help
```

Re-running is safe: runtime scripts and the contract are refreshed, but existing seeds and your real
docs are kept unless you pass `--force`.

---

## Day-to-day use

After install, everything runs through one dispatcher:

```bash
./utils/pdda/pdda.sh run                # all deterministic checks, then the LLM readiness review
./utils/pdda/pdda.sh frontmatter        # one check on its own
./utils/pdda/pdda.sh roadmap-coverage
./utils/pdda/pdda.sh glance             # roll up title + Quad Concepts across 2-WORKING
./utils/pdda/pdda.sh help               # list every command
```

The workflow PDDA expects:

1. New ideas land in `PROJECT/1-INBOX`. Substantive work opens a GitHub issue first and is captured
   as a `GH-<n>-*.md` doc (see the issue-first SOP in `PROJECT/PDDA.md`).
2. Active work lives in `PROJECT/2-WORKING` — each doc needs YAML frontmatter and a near-top
   `## Status` table with the exact columns `What was just completed | What's next`.
3. `ROADMAP.md` stays a one-line **pointer ledger** for every active/queued doc — detail lives in the
   doc, not the roadmap.
4. Finished docs move to `PROJECT/3-COMPLETED`; stale/abandoned ones to `PROJECT/4-MISC` (flagged,
   never auto-moved).
5. Record each substantive iteration in `CHANGELOG.md`.

## Enforcement modes (the adoption ramp)

| Mode | When | Behavior |
|---|---|---|
| `observe` | just installed | reports findings, never blocks (default) |
| `light` | transitioning | reports everything incl. stale flags, still never blocks |
| `full` | on rails | `error` findings block with a non-zero exit |

Set it in `.pdda-mode` (or the `PDDA_MODE` env var). No mode ever mutates your tree.

Wire `./utils/pdda/pdda.sh run` into a pre-commit hook, CI, or an hourly cron once you're ready.

### Quad Concepts (opt-in glance layer)

An **orthogonal**, opt-in convention (off by default). The `## Status` table says *where* the work is;
Quad Concepts says *what* it is — a 5-second read of the core problems a plan tackles and how:

```md
## Quad Concepts
- <pain the doc addresses> → <how it addresses it>
```

Enable it with `--quad` at install (or set `.pdda-quad` to `on` / `PDDA_QUAD=1`). When on, plan docs in
`2-WORKING`, `1-INBOX/GH-*`, and `3-COMPLETED` must carry a `## Quad Concepts` section of **1–4 bullets**;
`pdda.sh quad-concepts` enforces the shape (structure-only), and the enforcement mode above still decides
report-vs-block. Opt a doc out with `quad_exempt: true`. It's independent of the mode ladder — you can
trial it in `observe` first.

---

## The project memory layer

The hygiene rails above exist for one payoff: a repo an agent (or a human returning cold) can pick up
without re-learning what the last session already discovered. PDDA treats its own documents as a **de
facto project memory layer** — the same `PROJECT/**` docs that keep work resumable also carry the
durable context, decisions, and gotchas that stop a fresh agent from re-hitting a wall someone already
walked around. Nothing new is stored; the conventions just make the memory *retrievable* and *durable*.

Three lightweight conventions make it work:

- **Retrieval on start.** `ROUTER.md`'s startup sequence tells an agent that is exploring an unknown
  system, proposing a spike, or blocked to first search `PROJECT/3-COMPLETED/` and `CHANGELOG.md` —
  past docs are the first place to look, not the last.
- **Spikes are memory injection.** A discovery/spike phase isn't done when the code is understood — it's
  done when the findings are *written back into the plan doc*. `PROJECT/PDDA.md` frames this as active
  **Memory Injection**: quirks, mechanics, and gotchas become project state, not chat context that
  evaporates when the session ends.
- **Lessons captured at closeout.** Before a doc moves to `PROJECT/3-COMPLETED/`, it needs a
  `## Lessons Learned (For Future Agents)` section — the one-paragraph "here's what would have saved us
  an hour" that the next agent gets for free.

Two optional aids sharpen recall without adding any blocking check:

- **`context_tags`** — an optional frontmatter field (e.g. `context_tags: [auth, flaky-tests, build]`)
  that tags a doc by topic so related work is easy to find later. It needs no shell change — the
  deterministic checks ignore unknown frontmatter keys — so it stays a pure documentation convention.
- **Memory nudges in the LLM pass.** The opt-in readiness review (`pdda-doc-ready.sh`) emits a
  *warning* (never a block) when a medium-large plan leaves `related:` empty, or when a high-risk
  (`risk: 4`/`5`) plan links no `decisions/` record — gentle pressure to connect new work to the
  context and decisions it depends on.

Because all of this rides on the existing hygiene contract, the memory is only as trustworthy as the
docs are honest — which is exactly what the deterministic checks are there to keep true.

---

## Bundled Claude Code skills

This repo ships a couple of Claude Code skills under `SKILLS/` for working the PDDA workflow itself:

- **`SKILLS/PDDA-EOD/`** — a sequenced iteration wrap for this repo: reconciles `PROJECT/**` docs
  with `ROADMAP.md`/`CHANGELOG.md`, commits only approved paths, delivers them directly or through a
  PR as branch policy requires, closes landed issues only after user verification, and optionally
  tears down a clean, fully pushed linked worktree. Trigger: `/pdda-eod`.
- **`SKILLS/PDDA-hook/`** — opt-in installer for a `SessionStart` hook that deterministically
  re-anchors `ROUTER.md`/`AGENTS.md`/`PROJECT/PDDA.md` doc-governance rules at every context boundary
  (startup/resume/clear/compact), auto-scoped to repos that carry a `PROJECT/PDDA.md`. Personal,
  propose-then-confirm, and only ever writes to the operator's own `~/.claude/settings.json` or a
  repo's gitignored `.claude/settings.local.json` — never a repo's committed settings. Trigger:
  `/pdda-hook`.

## Maintaining this repo (contributors)

This repo's job is to keep the PDDA contract and the shipped surface in lockstep:

- `GUIDING-PRINCIPLES.md` — the north star the goals and design tradeoffs answer to
- `PROJECT/PDDA.md` — the document contract and enforcement model (the source of truth)
- `utils/pdda/pdda.sh` — unified entry point: dispatcher for every deterministic check + `pdda.sh run`
  (shared helpers in `utils/pdda/pdda-lib.sh`)
- `utils/pdda/pdda-doc-ready.sh` — the opt-in, model-dependent LLM readiness review (a separate layer)
- `install.sh` — the executable installer (keep in lockstep with `utils/pdda/PDDA-INSTALL.md`)
- `utils/pdda/PDDA-INSTALL.md` — the extraction/install manifest for target repos

Read `ROUTER.md` first for the startup order, then `GUIDING-PRINCIPLES.md` for the north star, then
`AGENTS.md` for the operating principles. Verify any change with `./utils/pdda/pdda.sh run` before
reporting it done.
