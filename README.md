# PDDA

This repo is the standalone source-of-truth installer repo for Project-Driven Doc Automation.

## What is canonical here

- `PROJECT/PDDA.md` - the document contract and enforcement model
- `utils/pdda.sh` - the unified entry point: a dispatcher for every deterministic check plus the
  aggregate `pdda.sh run` (shared helpers live in `utils/pdda-lib.sh`)
- `utils/pdda-doc-ready.sh` - the opt-in LLM readiness review (a separate, model-dependent layer)
- `utils/PDDA-INSTALL.md` - the extraction and install manifest for other repos

## What this repo is for

- maintaining the PDDA contract
- keeping the install manifest in sync with the shipped scripts
- providing a clean baseline repo that agents can read without inheriting another project's ledger

## First-run verification

```bash
./utils/pdda.sh run
```

The repo ships in `observe` mode by default via `.pdda-mode`, so a baseline run reports findings without blocking.
