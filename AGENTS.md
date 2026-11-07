# AGENTS.md

Instructions for AI coding agents working in this repository.

## Project overview

PHOENIX-11: ворклог операций TH-* (журнал неповторимых результатов), сборки WinPE, сессии. Правила ведения — в rtynbirf/repo-doctrine.

## Commands

No build or test commands are configured at the repository root. Inspect existing
files and follow the patterns already used in this codebase before making changes.

## Conventions

- Keep changes minimal and focused; one logical change per commit.
- Never commit secrets, tokens, or credentials.
- Ворклог пломбируется событием операции: после записи в worklog.md — `python3 scripts/seal_worklog.py --subject TH-ID --note "..."`; SEALS.jsonl append-only, хеш-цепь prev_sha256 (канон дома SPEC-0003); `--verify` — fail-closed сверка цепи.
- Update README.md when behavior or structure changes.
- Run any available checks before committing.
