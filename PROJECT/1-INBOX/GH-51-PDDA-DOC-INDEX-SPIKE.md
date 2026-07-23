---
title: "Spike: device-wide PDDA doc index (SQLite + local embeddings) to catch status/folder drift"
status: Proposed (1-INBOX) — Codex-reviewed 4 rounds, all findings applied; BLOCKED on one operator call (formal vs simple Phase 2 gate) before any code starts
created: 2026-07-22
updated: 2026-07-22
owner: noel
gh_issue: 51
source: https://github.com/Hypercart-Dev-Tools/pdda/issues/51
doc_type: project
effort: 5
complexity: 5
risk: 3
phases: 4
ratings_note: >
  Re-rated up from 3/3/2 after Codex review r1. The original numbers priced Phase 1 alone and ignored
  filesystem discovery across 37 repos, snapshot-safe git/HQ/GH reconciliation, a clone-identity
  policy, an operator DB contract, and an unproven MLX embedding path. Phase 3 is estimated
  SEPARATELY and only after the Phase 2 gate — it is not included in these numbers.
goal: >
  Settle — cheaply and with a real kill criterion — whether a derived SQLite index over every PDDA
  install on this device catches doc lifecycle drift (folder vs status vs GH issue vs ROADMAP) that
  the current per-repo checks miss, and whether a local-embedding semantic layer adds anything the
  deterministic SQL layer does not already deliver.
---

## In plain terms (read this first)

**The problem.** Across the 37 PDDA repos on this device, about **1 in 6 project documents
contradicts itself** about whether its work is done — the folder says "in progress," the document
text says "complete," or the GitHub issue disagrees with both. Nobody notices, because nothing checks.

**Why it happens.** Not because detection is hard: 40 lines of script found 144 conflicts in two
seconds. Because (a) nothing runs a check *across* repos, and (b) the check that exists can only see
documents carrying a `gh_issue:` field — and 241 documents don't have one.

**The fix.** A throwaway database indexing all the documents, reporting the contradictions. A cache
built from git, gitignored, deletable at any time. **The documents stay plain Markdown in git exactly
as they are today** — nothing moves into a database.

**Cost and risk.** Low, and reversible. No new dependency for anyone *installing* PDDA — this is an
operator-side tool only.

**Open decision.** How rigorous the "do we also want AI/semantic search on top?" gate needs to be.
Recommendation: the simple version. See [Open decision](#open-decision--operator-call) at the end.

**Status.** Investigation and plan only. No code written.

## Ask

Agents update a PDDA doc's body and forget its `status:`, forget to `git mv` it out of `2-WORKING/`,
and forget the `ROADMAP.md` pointer. Nothing catches this across repos. Build a **derived, disposable**
SQLite index of all PDDA `PROJECT/**` + `ROADMAP.md` on the device, enumerated via HQ, and use it to
report drift. Answer whether embeddings earn their place, or whether plain SQL is the whole answer.

## Why — the measured problem

A read-only probe on 2026-07-22 (`utils/` script to be landed in Phase 1; scratch version reproduced
in the issue) found:

| Metric | Count |
|---|---|
| PDDA installs on device | 37 |
| `PROJECT/**/*.md` docs | 1,856 (24.6 MB) |
| repos with a `ROADMAP.md` | 14 / 37 |
| `2-WORKING/` docs | 333 |
| `3-COMPLETED/` docs | 591 |
| **status ↔ folder mismatches** | **144** (15.6% of the 924 lifecycle docs) |
| `2-WORKING/` stale (`updated:` > 30d) | 19 (worst: 134d) |
| `2-WORKING/` missing `updated:` | 28 |
| docs with **no frontmatter at all** | 185 |
| docs with **no `gh_issue:`** | 241 |

Three findings drive the design:

1. **The drift is real and large.** 144 mismatches is not a rounding error; it is one in six lifecycle
   docs making two contradictory claims about itself.
2. **Detection is cheap.** All 144 were found by ~40 lines of `awk` substring matching. This is the
   central negative result: *finding* drift is not the hard part, so nothing exotic is warranted for
   detection. The hard part is **reconciliation** — deciding which claim is right — and that is a
   join across four sources, not a graph traversal.
3. **Today's check cannot see most of it.** `issue-doc-sync` reconciles only docs carrying a
   `gh_issue:`. 241 docs have none, so they are structurally invisible to it.

## Key concepts

- **Derived, never authoritative.** The index is a cache built from git. Markdown in git stays the
  source of truth. The DB is gitignored, rebuildable in one command, and deleting it loses nothing.
  Every finding must cite a `path:line` a human can open.
- **Two claims per doc, plus two external ones.** Folder (lifecycle claim), `status:` (prose claim),
  GH issue state (external claim), ROADMAP pointer (ledger claim). Disagreement among the four is a
  *detection*, not a verdict. This is the schema.
- **The four claims are not symmetric — applicability is pre-registered, not inferred.** A completed
  doc needs no queue pointer; a reference doc has no lifecycle claim; a valid non-issue doc has no GH
  state. Without this matrix, `consistent` silently degrades to "nothing applicable was checked," and
  the Phase 0 baseline of 144 becomes incomparable to the gate population. Fixed in advance:

  | Doc context | Folder | `status:` | GH issue state | ROADMAP pointer |
  |---|---|---|---|---|
  | `2-WORKING`, `doc_type: project`/`bugfix` | required | required | required unless no-issue-by-design | required unless `roadmap_exempt: true` |
  | `3-COMPLETED`, lifecycle doc | required | required | required **iff** `gh_issue:` present | inapplicable |
  | `1-INBOX` | required | required | optional | optional |
  | `4-MISC` / `doc_type: reference` | inapplicable | optional | inapplicable | inapplicable |

  **Zero-or-one applicable claim ⇒ outcome `not-applicable`** — excluded from the drift denominator
  and reported separately. A row that cannot be in conflict must never be counted as agreement.

- **Detection is not adjudication.** Naming a conflict is the easy half; deciding which claim is right
  is the hard half, and the plan must not pretend the first delivers the second. Every scanned doc
  resolves to exactly one outcome:

  | Outcome | Meaning |
  |---|---|
  | `consistent` | **≥ 2 applicable** claims were checked and all agree |
  | `not-applicable` | fewer than 2 applicable claims — structurally incapable of conflict |
  | `metadata-invalid` | a *required* claim cannot be read at all (no frontmatter, unparseable `status:`) — the lifecycle claim is *unknowable*, not merely absent |
  | `needs-human-triage` | applicable claims are readable and disagree; the tool refuses to pick a winner |

  The denominator and the five Phase 2 audit strata are both **derived from this matrix**, so the
  baseline and the gate measure the same population.

- **Git history is evidence, never a fifth authoritative claim.** Last-commit-touching-path informs a
  `needs-human-triage` row (it is why one claim looks staler than another) but must never
  auto-resolve one. Promoting history to an authority would let a doc-formatting commit silently
  "prove" a project complete.
- **Every row is snapshot-stamped.** A multi-repo scan reads repos in different states at different
  moments. Each row persists `scanned_at`, `head_sha`, `dirty` (working-tree clean?), and
  `path_last_commit_at`. Without this the report is unreproducible and two runs can disagree for
  reasons that have nothing to do with drift.
- **Deterministic first, semantic second, with a kill gate between them.** Phase 1 ships SQL-only.
  Phase 3 is authorized by **exactly one** condition — a pre-registered residual *semantic* question
  that survives a structurally passing gate (Phase 2, decision table row 3). A gate *failure* never
  authorizes Phase 3; it sends the work back to Phase 1, because a failed deterministic check almost
  always means a broken parser or a wrong applicability rule, and embeddings do not repair either.
- **HQ enumerates, filesystem verifies.** `hq.sh registries` reports 15/11/10 across its three
  registries; the filesystem has 37 PDDA installs. The registry ladder is the *naming* layer, not the
  *enumeration* layer. Indexing must scan and then enrich from HQ, never the reverse.

## Non-goals

- **Neo4j, or any server-backed graph store.** Evaluated and rejected **for the queries this spike
  serves**: 924 lifecycle docs is far below the scale where variable-depth traversal beats a b-tree
  join; PDDA ships as a portable shell installer (`install.sh`) and cannot acquire a JVM + daemon
  dependency; and reconciliation is a four-way join.

  This is a scoped rejection, not a blanket verdict — a graph genuinely can express arbitrary-depth
  cross-repo dependency and provenance questions that the relational schema below cannot. So the
  rejection carries a **falsifiable reconsideration trigger**, evaluated in Phase 4:

  > Reopen the graph question when someone writes down a **concrete, user-facing query** that (a) is
  > variable-depth or transitive over repo/doc/issue/commit relations, (b) cannot be expressed within
  > the documented relational schema, and (c) someone actually wants answered. A named query reopens
  > it. "It might be useful later" does not.
- **Moving PDDA docs into a database.** Never. See "Derived, never authoritative."
- **Auto-fixing drift.** This spike *reports*. Auto-`git mv` on 144 docs across 37 repos is a
  blast-radius decision that belongs to Sentinel (GH-10) and the operator, not to an indexer.
- **Replacing `ask-self`.** Reuse its `sqlite-vec` schema; do not fork its indexer.

## Embedding stack — traced, not assumed

An initial pass concluded "no Qwen embedding model is installed" by checking `ollama list` and
`lms ls`. **That was wrong.** The model does not run as a *server*, so a port/daemon inventory cannot
see it. Traced properly through Rebalance:

| Fact | Value | Evidence |
|---|---|---|
| Model | `Qwen/Qwen3-Embedding-0.6B` | `rebalance-OS/src/rebalance/ingest/embedder.py:22` |
| Dimensions | **1024** | `embedder.py:23` (`EMBEDDING_DIM = 1024`) |
| Runtime | **`mlx-embeddings` 0.1.0, in-process, Apple Silicon Metal** | `embedder.py:2`; `mx.metal.is_available() == True` |
| Weights | fp32 1.1 GB + `mlx-community/Qwen3-Embedding-0.6B-4bit-DWQ` 335 MB | `~/.cache/huggingface/hub/` |
| Context | 32,768 tokens | `config.json:max_position_embeddings` |
| Pooling | last-token → L2 normalize, cosine similarity | `modules.json`, `config_sentence_transformers.json` |
| **Live smoke test** | `load(...)` → `generate(...)` → **shape `(1, 1024)`** | run 2026-07-22 in `rebalance-OS/.venv` |

So the model is present, the library is installed, Metal is available, and **it produces vectors
today**. No `ollama pull` is required. The 1024-dim width is the number that locks the `sqlite-vec`
virtual-table schema.

### The actual risk (worse than a missing model)

**The Qwen path is wired but has never been run to completion.** `rebalance.db` shows
`chunks = 0`, `embeddings_chunks = 0`, `semantic_documents = 0`, and an **empty `embedding_meta`
table** — only `project_registry` (15 rows) is populated. Meanwhile the *working* semantic index on
this device is `rebalance-OS/ask_self/index/rebalance-OS.sqlite`: **2,263 chunks on cloud
`gemini-embedding-001` @ 768 dims**.

Two embedding stacks coexist in one repo — a local 1024-d Qwen pipeline that is designed but unproven,
and a cloud 768-d Gemini pipeline that is proven but remote. Phase 3's real question is therefore not
"can we get a model?" but **"can the local MLX path complete a full corpus embed?"** — something no
run on this device has yet demonstrated. Budget for that being the hard part.

One pattern worth stealing regardless: `embedder.py` detects a model-name change via `embedding_meta`
and forces a full re-embed. Any index built here must do the same, or a swapped model silently
produces a mixed-dimension corpus.

## Phases

### Phase 0 — Enumerate and characterise (DONE, scratch)

- [x] Filesystem enumeration of PDDA installs (37) and corpus size (1,856 docs / 24.6 MB).
- [x] Drift baseline measured (144 mismatches / 19 stale / 185 no-frontmatter / 241 no-issue).
- [x] Registry-vs-filesystem gap identified (15/11/10 known vs 37 actual).
- [x] Confirm the corpus fits trivially in SQLite — it does; 24.6 MB is not a scale problem.
- [ ] Land the throwaway probe as a real script under `utils/` so the baseline is reproducible.

### Phase 1 — Deterministic index + drift report (the load-bearing phase)

- [ ] **Reproducible discovery boundary.** "Every PDDA install on this device" is not a definable
      population — the Phase 0 probe hardcoded four search roots and `-maxdepth 5`, so a later run
      cannot prove it examined the same repo set, and snapshot-stamping rows does not fix a population
      frame that silently changes underneath. Phase 1 must take discovery as **input**, not behaviour:
      a versioned config of discovery roots + depth, or an explicit repo manifest; a stated
      **symlink and exclusion policy** (do not follow symlinks out of a root; skip vendored `.xyz/`,
      `node_modules`, `graphify-out`).
- [ ] **Persist the resolved repo inventory** as a first-class table: `canonical_repo_id`,
      physical path, discovery reason (which root/manifest entry matched), and scan result
      (scanned / skipped-with-reason / unreadable). Diff it against the previous run and **report
      additions, removals, and skips before** any comparison to the Phase 0 baseline.
- [ ] `utils/pdda-index/pdda-index.sh build` — walk every enumerated repo, parse frontmatter, write
      SQLite (`repos`, `repo_inventory`, `docs`, `roadmap_pointers`, `gh_state`). Gitignored path.
- [ ] **Clone identity policy** (replaces the naive `origin`-URL key, which Codex correctly rejected:
      SSH vs HTTPS aliases collide, some clones have no origin, and two worktrees on *different*
      commits would share a key while holding legitimately different docs).

      Every row carries the immutable triple **`(canonical_repo_id, head_sha, rel_path)`** where
      `canonical_repo_id` normalizes SSH/HTTPS/`.git`-suffix/case variants of the remote, falling back
      to the common git dir when no origin exists. Collapse two entries **only** when they share a
      common git dir *and* the same `head_sha` — i.e. genuine duplicate views of one commit.

      Forks and same-repo-different-commit worktrees are **equivalence groups, not duplicates**:
      report them grouped and collapsed by default, expandable, never silently discarded. A finding
      that exists in `LTVera-Pandas` but *not* in `LTVera-Pandas-pr-66` is signal — dropping it hides
      exactly the divergence worth seeing.
- [ ] `pdda-index.sh drift` — four-way reconciliation report, every row citing `repo`, `path:line`,
      and *which two claims disagree*.
- [ ] **Exemption policy for the 185 no-frontmatter and 241 no-`gh_issue:` docs.** Separate report
      classes are observability, not reconciliation — a doc with no `gh_issue:` may be a perfectly
      valid non-issue doc, whereas a doc with no frontmatter has an *unknowable* lifecycle claim.
      Those are different problems and must not share a bucket. Classify every such doc as:

      | Class | Meaning | Gate consequence |
      |---|---|---|
      | `required-missing` | the doc type demands the field and lacks it | counts as drift |
      | `allowed-with-reason` | legitimately exempt (e.g. `roadmap_exempt: true`, a reference doc) | excluded from the denominator, reason recorded |
      | `legacy-invalid` | predates the convention; unknowable, not exempt | counts as drift, flagged separately |

      Emit reason-coded rows, publish the denominator each class is measured against, and **include
      `required-missing` and `legacy-invalid` rows in Phase 2's audited population** — they are not
      a side report. Never silently skip: silent skipping is how the drift got here.
- [ ] Enrich with HQ: join `hq.sh resolve` names onto scanned repos so the report speaks project
      names, not paths. Fail-open when HQ has no entry (23 of 37 repos it does not know).

### Phase 2 — Kill gate

**The r1 version of this gate was broken and is replaced.** It proposed hand-auditing 30 of the 144
*flagged* mismatches and calling the result "catches ≥90% of real drift." Sampling only what the
detector already flagged can measure **precision** (how many flags are right) but is structurally
incapable of measuring **recall** (how much drift was missed) — the missed drift is, by definition,
not in the flagged set. The gate claimed recall and measured precision. Fixed:

- [ ] **Pre-register the adjudication rubric before looking at any sample.** Written criteria for
      what counts as real drift, decided in advance, so the gate cannot be rationalized after the
      fact by whoever wants their preferred outcome.
- [ ] **Stratified random sample spanning flagged AND unflagged docs.** Strata: flagged mismatches;
      unflagged `2-WORKING`; unflagged `3-COMPLETED`; `required-missing`; `legacy-invalid`. The
      unflagged strata are what make recall measurable at all.
**The r2 version was still broken — it was internally contradictory.** It said "Phase 3 is
mechanically unauthorized unless the gate meets both thresholds" and, in the next breath, that a
*passing* gate means Phase 3 is never built. Read literally, Phase 3 could never be authorized under
any outcome. Worse, it implied a *failing* SQL gate would justify embeddings — but a failed
deterministic gate is far more likely to mean the parser or the classification policy is broken, and
embeddings are not a remedy for a broken parser. Replaced with an explicit decision table below.

#### Pre-registered sampling design (fixed now, not "to be stated later")

**The r3 strata were not a partition and are replaced.** "flagged · unflagged `2-WORKING` ·
unflagged `3-COMPLETED` · `required-missing` · `legacy-invalid`" overlap — a `legacy-invalid` doc can
also be flagged *and* sit in `2-WORKING`, so a row could fall in three strata at once. Proportional
allocation and size-weighting over overlapping sets double-count and make the estimator undefined.
Replaced with an exhaustive, mutually exclusive partition on two independent dimensions:

| Stratum | Detector verdict | Metadata class | Folder |
|---|---|---|---|
| **S1** | flagged (`needs-human-triage`) | valid | any |
| **S2** | flagged | `required-missing` or `legacy-invalid` | any |
| **S3** | unflagged (`consistent`) | valid | `2-WORKING` |
| **S4** | unflagged | valid | `3-COMPLETED` |
| **S5** | unflagged | `required-missing` or `legacy-invalid` | any |

Every frame member lands in **exactly one** cell; `not-applicable` docs are outside the frame
entirely. Each dimension is single-valued per doc, so no precedence rule is needed.

| Parameter | Value |
|---|---|
| **Population frame** | docs under `PROJECT/2-WORKING/` + `PROJECT/3-COMPLETED/` in the deduped repo set whose applicability matrix marks **≥ 2 claims applicable** |
| **Recall rule** | the **lower bound of the design-based 95% CI ≥ 90%** — not a point estimate with an asserted margin |
| **False-positive rule** | upper bound of the 95% CI on flagged-row FP rate **≤ 10%** |
| **Estimator** | stratified Horvitz–Thompson with **inclusion probabilities published per stratum**; CI by stratified bootstrap over the adjudicated sample |
| **Stopping rule** | *not* a fixed n, and *not* a precision target — see the sequential rule below. Recall precision depends on the count of **adjudicated true-drift rows**, not total docs sampled |
| **Initial allocation** | 20 per stratum (100 total) as a *starting* draw, oversampling S1/S2 relative to their frame share because true-drift rows concentrate there |
| **Reproducibility** | publish stratum sizes, realized allocation, **random seed**, inclusion weights, and the CI method with the report |

#### Sequential stopping rule — decision-driven, not precision-driven

A precision target must never be the stopping trigger. "Stop at half-width ≤ 10 pp" would end
sampling at, say, 95% observed recall ± 9 pp — a lower bound of 86%, recorded as a **failure** even
though a few more adjudications could have established the required bound. That converts a precision
target into a premature, non-diagnostic failure. Sample until one of three decisions is *reached*:

| Stop | Condition | Outcome |
|---|---|---|
| **Pass** | one-sided 95% **lower** bound on recall ≥ 90% **and** one-sided 95% **upper** bound on FP rate ≤ 10% | decision table row 1 |
| **Futility** | one-sided 95% **upper** bound on recall < 90% — the floor is established as unreachable | decision table row 2 (repair Phase 1) |
| **Exhausted** | the relevant strata are fully adjudicated with neither bound resolved | **indeterminate** — escalate to the operator; do *not* silently read it as either pass or fail |

The ±10 pp half-width is retained only as a **reporting** target, and explicitly may not force a stop
before one of the three decisions above is reached.

- [ ] Adjudicate the sample against the pre-registered rubric, blind to the detector's verdict where
      practical.
- [ ] Publish the realized design (sizes, seed, weights, achieved CI) alongside the verdict. A gate
      whose sampling design is not reproducible is not a gate.

#### Decision table — the only three outcomes

| # | Condition | Action |
|---|---|---|
| **1** | Sequential rule stops at **Pass** | **Close the spike. No Phase 3.** Success, smaller artifact than proposed. |
| **2** | Sequential rule stops at **Futility**, and the failure is attributable to deterministic implementation or policy (parser bug, wrong applicability matrix, bad exemption class) | **Repair Phase 1 and re-run the gate.** Not a semantic problem; embeddings fix nothing here. |
| **3** | Row 1 holds **and** a pre-defined, adjudicated **residual semantic question** remains — one written down *before* the gate ran, that no relational rule can answer | **Only this authorizes Phase 3**, and it is scoped and estimated separately. |
| **—** | Sequential rule stops at **Exhausted** (indeterminate) | **Escalate to the operator.** Never silently resolved as pass or fail. |

- [ ] Record the dated outcome, the numbers, and which row of the table fired, in this doc.
- [ ] Note explicitly: outcome **1** is the expected and preferred result.

### Phase 3 — Semantic layer (only if Phase 2 says so)

**Pre-registration — authored BEFORE Phase 2 runs, or Phase 3 is not authorized.** Without this,
"benchmark against Gemini" becomes an open-ended experiment that can always be argued into a
positive result after the fact. Freeze all four of these while the gate outcome is still unknown:

- [ ] **Name the exact residual question(s)** — the specific semantic questions that a structurally
      passing deterministic gate still leaves unanswered. These, and only these, are what decision
      table row 3 authorizes. Two candidates to make concrete or drop: *"does this doc's prose still
      describe what shipped?"* and *"are two repos carrying near-duplicate work?"*
- [ ] **Freeze the labeled query set and relevance rubric** — the actual queries, the actual
      judgments, written down before any embedding exists to be flattered by them.
- [ ] **Set retrieval and resource acceptance thresholds** — a numeric bar on retrieval quality
      versus the Gemini baseline, plus wall-clock and peak-memory ceilings.
- [ ] **State the keep/discard decision rule** — what result ends the experiment with "discard."
      The one-repo run must clear these thresholds **before** any corpus-scale embedding is attempted.

- [ ] Lock the `sqlite-vec` virtual-table width to **1024** (`Qwen3-Embedding-0.6B` via `mlx-embeddings`,
      already resident and smoke-tested — no model pull needed). Store the model name in an
      `embedding_meta` row and force a full re-embed on change, per `embedder.py`'s precedent.
- [ ] **One-repo exit contract — prove the local MLX path end-to-end before the 1,856-doc corpus.**
      `rebalance.db` has zero embedded rows today, so "local embedding completes at corpus scale" is
      unproven on this device and is this phase's real risk. "Prove it works" is not an acceptance
      test; these are:

      | Dimension | Must demonstrate |
      |---|---|
      | Completeness | every expected doc accounted for — embedded, or skipped with a recorded reason |
      | Counts | chunk and vector counts reconcile against the doc set |
      | Correctness | all vectors 1024-d, finite (no NaN/Inf), L2-normalized |
      | Failure behaviour | defined retry/skip on a doc that fails to embed; a partial run must not look like a complete one |
      | Performance | stated wall-clock and peak-memory ceiling, measured not assumed |
      | Rebuild | clean rebuild from scratch reproduces counts |
      | Model change | changing the model name forces a full re-embed (`embedder.py`'s `embedding_meta` precedent) |
      | Retrieval | labeled query set, scored against the Gemini baseline — not vibes |

- [ ] Decide 4-bit DWQ (335 MB, faster) vs fp32 (1.1 GB). **Both happen to be cached on this device —
      that is not a reproducible prerequisite.** Document model acquisition, `mlx-embeddings`
      installation, and the Apple-Silicon/Metal requirement as explicit operator prerequisites, held
      strictly separate from PDDA's zero-dependency installer promise. Nothing here may become a
      dependency of `install.sh`.
- [ ] Chunk + embed doc bodies reusing `ask-self`'s `chunks` / `chunks_vec` / `file_revisions` schema.
- [ ] Answer the two questions SQL provably cannot: (a) does a doc's prose still describe what
      actually shipped, and (b) are two repos carrying near-duplicate work?
- [ ] Benchmark local Qwen (1024-d) against the incumbent cloud `gemini-embedding-001` (768-d) on the
      same corpus before declaring local-only viable. Note the widths differ — this is a retrieval-quality
      comparison, not a vector-space one.

### Phase 4 — Decide the disposition

- [ ] Write the recommendation: fold into `pdda.sh` as a subcommand, hand to Sentinel (GH-10) as a
      finding source, keep as a standalone HQ-level tool, or discard.
- [ ] Evaluate the **graph reconsideration trigger** from Non-goals: did any concrete, user-facing,
      variable-depth query surface that the relational schema cannot express? Name it or close the
      question.
- [ ] If kept, the drift report becomes an input to Sentinel's act-on-it pipeline — not a new
      parallel automation.

## Acceptance criteria

- One command rebuilds the entire index from scratch; deleting the DB has zero consequence.
- The drift report reproduces the Phase 0 baseline counts, **with the class definitions and
  denominators stated explicitly** so the comparison is meaningful rather than coincidental.
- Every row carries `(canonical_repo_id, head_sha, rel_path)` plus `scanned_at` / `dirty`, so any
  finding is reproducible and two runs disagree only when the repos actually changed.
- Fork/worktree equivalence groups are collapsed by default and expandable — never silently dropped.
- Every doc lands in exactly one of `consistent` / `not-applicable` / `metadata-invalid` /
  `needs-human-triage`, derived from the pre-registered applicability matrix, and the tool never
  auto-picks a winner among conflicting claims.
- The Phase 0 baseline is restated against the matrix-derived denominator before being compared to
  the gate population, so "reproduces the baseline" is a meaningful claim rather than a coincidence.
- Discovery is driven by a versioned config or manifest, and the persisted repo inventory diff
  (additions / removals / skips) is reported before any run-to-run comparison.
- The Phase 2 report publishes stratum sizes, realized allocation, random seed, inclusion weights,
  and CI method — enough for a third party to recompute the verdict.
- Zero new runtime dependencies for anyone who merely *installs* PDDA. This tool is operator-side;
  the embedding prerequisites are documented separately and never enter `install.sh`.
- Phase 2's gate produces a dated, recorded report measuring **both** recall and false-positive rate
  against a pre-registered rubric — including the outcome where Phase 3 is never built.

## Swarm Preflight Contract

- **Write-set:** `utils/pdda-index/**`, `PROJECT/1-INBOX/GH-51-PDDA-DOC-INDEX-SPIKE.md`,
  `ROADMAP.md` (one pointer line), `.gitignore` (one entry for the DB path).
- **Read-only outside the write-set:** all 37 target repos are read **only**. This tool must never
  write to a repo it is indexing.
- **Disjoint from:** GH-50 (`sentinel/**`), GH-48/GH-47 (`utils/pdda/pdda.sh`, `.claude/skills/pdda`).
  No overlap with any open lane.
- **Rollback:** delete `utils/pdda-index/` and the gitignored DB. No migrations, no state.

## Open decision — operator call

Codex reviewed this plan over 4 rounds on 2026-07-22 (thread
`relay-system/2026-07-22/gh-51-doc-index-spike-r2.md`): **4 blockers + 7 shoulds, all implemented,
none declined.**

**All four blockers were in Phase 2 — the kill gate. Phase 1 drew zero.** The deterministic core
(discovery, clone identity, applicability matrix, four-claim reconciliation) has been stable since
round 1 and only ever attracted `[Should]`s. Every blocker was in the apparatus built to *justify
skipping Phase 3* — an invalid metric, a self-contradictory authorization rule, an undefined
estimator over non-partitioned strata, and a stopping rule that could not decide its own gate. Each
fix was correct, and each made the gate heavier.

Phase 2 now specifies a stratified Horvitz–Thompson estimator with published inclusion probabilities
and sequential futility bounds — to decide the question *"do we also want embeddings?"* That is
plausibly over-engineered for its job. The review never challenged it, because the review brief asked
whether the gate was **rigorous**, not whether it was **warranted**.

| Option | Case | Best if |
|---|---|---|
| **Simple** | Build Phase 1, read the output, decide with judgment, record the decision and its reasoning in this doc. | The operator trusts their own read of a report they will be holding. |
| **Formal** | Keep Phase 2 as specified. | The decision must survive an external audit. |

**Recommendation: Simple.** Nothing here is hard to reverse — the DB is a throwaway cache and the
docs never leave git. The one commitment worth protecting is unrelated to the gate: **the embedding
stack must never become a dependency of `install.sh`.**

Until this is answered, Phase 2 stands as written and no code should be started.

## Related

- [#10 Sentinel](https://github.com/Hypercart-Dev-Tools/pdda/issues/10) — the act-on-it layer this
  should feed rather than duplicate.
- [#9 weekly progress counter](https://github.com/Hypercart-Dev-Tools/pdda/issues/9) — same
  "flag, don't silently drop, any mismatch" posture; reuse its `.pdda-gh-state.tsv` cache.
- HQ (GH-128, `xyz-3-agents-swarm`) — enumeration and project-name resolution.
- `ask-self` — the `sqlite-vec` schema to reuse in Phase 3.

Full discussion: [#51](https://github.com/Hypercart-Dev-Tools/pdda/issues/51)
