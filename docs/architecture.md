# Code and architecture

## Actual stack

[Framework, runtime, package manager, ORM, driver, and observed versions. Record reasons and exceptions to the defaults; actual versions also belong in the lockfile.]

## Code map

[Short tree of directories and files that actually exist. State each responsibility; do not present future architecture as implemented.]

## Boundaries and flow

[Actual path between presentation, validation, logic, and data. Server code owns environment, logging, and the database client. Create feature modules as needed; avoid empty layers.]

## Data and migrations

[Drizzle schema, inferred types, migration destination, and generation/review/application lifecycle. Record pooling, driver, runtime, bounded queries, and transactions where needed. Explain the decision if there is no persistence.]

## Decisions

[Decision, reason, relevant alternative, source/date, and condition for revisiting. Do not duplicate PRODUCT.md requirements.]

## Maintenance

Update this map when directories, relevant dependencies, contracts, or boundaries change. Record verified behavior; remove decisions that no longer apply.
