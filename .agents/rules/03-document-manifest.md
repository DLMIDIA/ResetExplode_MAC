# Antigravity Rule: Project Document Manifest

> **Principle**: Single source of truth. Every document has an explicit owner and scope.

## Canonical Manifest

| File | Scope & Ownership | What belongs here | What does NOT belong here |
|---|---|---|---|
| `PRODUCT.md` | Product Scope & MVP | Problem statement, target user, MVP features, acceptance criteria | Code conventions, terminal commands |
| `AGENTS.md` / `GEMINI.md` | Agentic Guidelines & Bridge | Canonical build commands, lint rules, styling constraints, tool usage | Product roadmap, full API manuals |
| `docs/architecture.md` | System Architecture | Component boundaries, database models, request lifecycles, service integrations | Temporary notes, scratch code |
| `docs/quality.md` | Quality Standards | Lint configs, testing matrix, performance benchmarks, 350-line enforcement | General business goals |
| `docs/setup.md` | Environment & Ops | Prerequisites, environment variables (names only, no secrets!), local setup | Personal credentials |

## Synchronization Rule
Whenever you make a major architectural change, add a dependency, or modify an API contract, immediately update the corresponding document. Never let documentation diverge from working code.
