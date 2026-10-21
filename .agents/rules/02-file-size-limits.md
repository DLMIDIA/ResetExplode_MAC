# Antigravity Rule: 350-Line Modular Limit

> **Principle**: High cohesion, low coupling, and zero context bloat.

## The 350-Line Limit

In any project adopting this toolkit, source files (`.ts`, `.tsx`, `.js`, `.py`, `.go`, `.rs`, `.php`, etc.) must not exceed **350 lines of code**.

### Why 350 Lines?
1. **Model Context Precision**: LLMs reasoning over 200–300 lines maintain near-perfect attention across all identifiers and edge cases. At 800+ lines, subtle bugs and regressions spike dramatically.
2. **Single Responsibility**: Long files almost always mix state management, data transformation, API calls, and UI rendering.
3. **Atomic Diffs**: Reviewing and merging small diffs is fast and collision-free.

### Guidelines for Refactoring Bloated Files
- Split UI components into smaller presentational atoms.
- Extract business logic, formatting, and mathematical operations into pure utility functions or custom hooks.
- Separate database schemas, DTOs, and type definitions into dedicated `types/` or `schemas/` directories.
- Group related submodules inside a directory with an `index.ts` re-export barrier.
