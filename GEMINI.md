# Antigravity Agent Guidelines & Rules Bridge

This file is automatically loaded by Google Antigravity across all sessions within this workspace.

## Canonical Reference
- Detailed product requirements and acceptance criteria: [`PRODUCT.md`](./PRODUCT.md)
- Complete agent instructions and build commands: [`AGENTS.md`](./AGENTS.md)
- System architecture and boundaries: [`docs/architecture.md`](./docs/architecture.md)
- Quality verification standards: [`docs/quality.md`](./docs/quality.md)

## Core Working Principles
1. **Evidence-First**: Never claim a task is completed without running tests, linter, or typecheck in the terminal and proving exit code `0`.
2. **350-Line Limit**: Keep every source file under 350 lines. Deconstruct large modules using the facade pattern.
3. **Subagent Discipline**: Reviewers are strictly read-only. Writers own distinct files with zero collisions.
4. **Documentation Sync**: Any contract change must update `PRODUCT.md` or `docs/architecture.md`.
