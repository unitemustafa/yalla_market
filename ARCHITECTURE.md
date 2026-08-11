# Yalla Market architecture

## Principles

The application is organized by feature. Every feature may contain `data`,
`domain`, and `presentation` layers. Keep dependencies pointing inward:

```text
Flutter UI / Cubit -> use case -> repository contract <- repository implementation
                                                data source / API / local storage
```

- Presentation renders state and forwards user intent. Cubits depend on use
  cases, never repositories, API clients, storage packages, or demo fixtures.
- Domain contains immutable business concepts, repository contracts, and use
  cases. It must not import Flutter, presentation, data, API configuration, or
  asset constants.
- Data owns JSON parsing, endpoint paths, persistence, platform adapters, demo
  data, and conversion to domain entities.
- Dependency injection is the only place that selects demo or remote
  implementations.
- `core` is feature-neutral. Application composition code that imports features
  belongs in the application shell rather than a reusable core primitive.

## State and data flow

Events move in one direction: widget -> Cubit -> use case -> repository. Results
return as `ApiResult<T>` and become immutable presentation state. A repository is
the source of truth for its data; widgets must not merge remote and demo records.

Local widget state is limited to transient presentation concerns such as focus,
animation, an open panel, or an unsubmitted text field. Persisted preferences,
network decisions, validation with business meaning, and cross-screen state live
behind domain interfaces.

## Cross-feature composition

Features can reuse domain entities or explicit presentation adapters from another
feature when the ownership is clear. Generic `core` widgets receive primitive
display values and callbacks; they do not read feature Cubits directly. Routing,
session lifecycle, deep links, and push-event coordination are application-level
composition concerns.

## File boundaries

- A view coordinates one screen; substantial sections live in named widget files.
- Controllers and Cubits contain orchestration, not widget construction.
- Hand-written `part` files are avoided for modularization; normal libraries with
  explicit imports are preferred. Declarative translation tables are exempt.
- A hand-written executable file over 500 lines requires a documented reason.
  Views should normally remain below 350 lines.

## Adding or changing a feature

1. Define or reuse the domain entity and repository contract.
2. Add a focused use case for each Cubit operation.
3. Implement remote/local behavior and DTO mapping in data.
4. Register the implementation and use cases in the feature DI module.
5. Add Cubit tests, repository/mapper tests, and widget characterization tests.
6. Run every command in the README verification section.

Backend endpoints, JSON shapes, route names, localization text, and widget keys
are compatibility contracts. Change them only in an explicitly scoped task.
