# Antigravity Rule: Subagent Orchestration & Parallel Waves

> **Principle**: Zero collisions, bounded responsibilities, independent workers.

## Guidelines for Antigravity Subagents (`invoke_subagent`)

1. **One Writer Per File**:
   Never assign two concurrent subagents to edit the same file or closely coupled modules. 
   - Each worker must own a distinct set of files.
   - The coordinator agent (parent) retains exclusive ownership of root lockfiles (`package-lock.json`, `pnpm-lock.yaml`), shared configuration files, and git merges.

2. **Read-Only Reviewers**:
   Specialized subagents spawned for code review, security audits, or architectural analysis must operate in strictly **read-only mode**. They produce evidence and reports, but do not directly mutate code.

3. **Deterministic Workwaves**:
   Execute tasks in discrete waves:
   - **Wave 1 (Foundation)**: Core schemas, types, and database models. (Wait for completion & verification).
   - **Wave 2 (Parallel Implementation)**: Frontend UI worker + Backend API worker (operating on separate file trees).
   - **Wave 3 (Verification & Review)**: Automated test execution + Security review subagent.

4. **Context Economy**:
   When launching subagents via `invoke_subagent`, provide only the minimal required context, explicit file paths, and crisp acceptance criteria. Do not dump the entire project history.
