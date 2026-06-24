# PDDA

This repo is the standalone source-of-truth installer repo for Project-Driven Doc Automation.

## What is canonical here

- `PROJECT/PDDA.md` - the document contract and enforcement model
- `utils/pdda-*.sh` and `utils/pdda-run.sh` - the shipped deterministic checks and runner
- `utils/PDDA-INSTALL.md` - the extraction and install manifest for other repos

## What this repo is for

- maintaining the PDDA contract
- keeping the install manifest in sync with the shipped scripts
- providing a clean baseline repo that agents can read without inheriting another project's ledger

## First-run verification

```bash
./utils/pdda-run.sh
```

The repo ships in `observe` mode by default via `.pdda-mode`, so a baseline run reports findings without blocking.
