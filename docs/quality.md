# Quality

## Commands

[List existing scripts and what they prove: lint, typecheck, Vitest tests, rule self-check, and build. State the combined check command and when to run a scoped test or the suite.]

## Baseline rules

- Strict TypeScript and official framework presets.
- A 350-line limit and organization proportional to behavior.
- Structured server logging; no direct data access from presentation.
- With Drizzle, guard update/delete without where and review queries/migrations.
- Input and environment validation, errors without secrets, and relevant boundary tests.

## Testing strategy

[Cover behavior, decisions, failures, and regressions. State existing test environments and how to isolate services. Do not write tests that only repeat the code. Do not invent coverage, an E2E suite, or a security guarantee.]

[For adopted capabilities, document runtime/browser preflight, comparable bundle measurements, SQL/migration checks, actual CI run evidence, security report range/coverage, UI interaction checks, and read-only Sentry evidence. Omit inapplicable checks with a reason. Installation and discovery alone do not prove these workflows ran.]

[For typed lint, record the two focused async rules, severity, command, measured runner cost, and any legacy adoption plan. Run relevant harness smoke cases after instruction, memory, skill, or orchestration changes; identify the client/model and distinguish observed behavior from unrun cases.]

[Record the default Harness2-inspired native method adaptation, reusable prompt source/invocation, and relevant initial smoke results. If an observed failure justifies a candidate comparison, keep baseline/candidate inputs and independent checks comparable, retain security/permission boundaries, and record adopted/rejected changes and evidence-supported lessons. Separate any optional official CLI demo/benchmark evidence from actual project behavior; one passing case does not establish general reliability.]

## Review after implementation or fixes

Select review scope by risk and the actual diff. Use independent review for nontrivial work when available. Record the exact target, connected callers/contracts/tests, confirmed findings, and coverage. Add rounds for new evidence or unresolved risk; honor an explicitly requested count without inventing additional cycles.

Finish when relevant findings are resolved or explicitly dispositioned, affected checks pass, and integrated verification and residual risks are recorded. Fixes do not reset an agreed count. Missing independent review or blocked checks remain explicit limitations.

## Security review

[Record the adopted reusable prompt/skill, baseline or diff procedure, private report location, authorization boundaries, and relevant checks. Reviews trace entry points through shared validation/authorization to sensitive operations. Keep reviews read-only unless fixes are requested; redact reports and do not publish sensitive findings. Record severity, confidence, reproducibility, exclusions, and remaining hypotheses.]

## Dependencies and delivery

Check full and production audits. Investigate advisories and record known risk and available fixes. Passing lint/build does not mean a clean audit.

Checks are explicit commands. Git hooks, push blockers, and branch requirements are not defaults. Update this document together with scripts and rules that change.
