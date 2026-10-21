# Antigravity Rule: Evidence-First Verification

> **Principle**: Replace "It looks done" with verifiable evidence.

## Mandatory Rules for Antigravity

1. **No Unverified Completion**:
   Never mark a task, feature, or bugfix as complete without running concrete verification commands in the terminal and proving the result.
   - "I have updated the code" is not proof.
   - Executing the test runner, typechecker, and linter with exit code `0` is proof.

2. **Standard Verification Sequence**:
   Before concluding any non-trivial implementation, the agent must execute:
   - **Type Check**: `npx tsc --noEmit` (TypeScript) or `python3 -m py_compile` / `mypy` (Python).
   - **Lint**: Project linter (`npm run lint`, `biome check`, or equivalent).
   - **Unit/Integration Tests**: Run the test suite (`npm test`, `pytest`, `vitest`).
   - **Build**: Ensure the production bundle compiles without errors (`npm run build`).
   - **File Limits**: Verify no created/modified file exceeds the 350-line ceiling.

3. **Reporting Evidence**:
   In your final response or status summary, always include:
   - The exact command line executed.
   - The output summary or exit status proving success.
   - Any residual risks or items that require user-level credentials.
