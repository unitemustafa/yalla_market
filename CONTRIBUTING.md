# Contributing

## Working agreement

- Branch from `main` and keep each pull request focused on one behavior or one
  refactor cohort.
- Preserve existing behavior during refactors. Add a characterization test before
  moving code whose behavior is not already protected.
- Do not mix dependency upgrades, design changes, or API-contract changes into a
  structural refactor.
- Never commit credentials, signing material, Firebase deployment files, or local
  `env/*.local.json` files.

## Code rules

- Follow the dependency rules in `ARCHITECTURE.md`.
- Keep new handwritten Dart files at or below 500 lines. Existing oversized
  files are tracked by `tool/check_source_size.dart`; remove each path from its
  allowlist as the file is split.
- Use Cubit/Bloc and `get_it`; do not add another state-management system.
- Prefer immutable state and `const` widgets.
- Dispose controllers, focus nodes, streams, and lifecycle observers.
- Handle loading, empty, success, stale-data, cancellation, and failure paths.
- Reusable visual primitives belong in `core` only when they are feature-neutral.

## Pull-request checklist

- [ ] `dart format --output=none --set-exit-if-changed lib test integration_test tool`
- [ ] `flutter analyze`
- [ ] `flutter test --coverage`
- [ ] Coverage does not fall below the repository baseline.
- [ ] `flutter build apk --debug`
- [ ] New use cases, mappers, repositories, and Cubit branches have tests.
- [ ] Routes, API payloads, localization, and visual behavior are unchanged unless
      the pull request explicitly says otherwise.
- [ ] Documentation and environment templates remain accurate.

Release changes must additionally pass the platform checklist in
`docs/RELEASE_CHECKLIST.md` and the release preflight tool.
