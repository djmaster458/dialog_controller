# Contributing to dialog_flow

Thanks for contributing to dialog_flow.

## Before You Start

- Use Flutter through FVM for all local commands.
- Keep changes focused and small when possible.
- Match existing code style and project architecture.
- Add or update tests for every behavior change.

## Development Setup

1. Install FVM if needed:

```sh
dart pub global activate fvm
```

2. Install the configured Flutter SDK:

```sh
fvm install
```

3. Fetch dependencies:

```sh
fvm flutter pub get
```

4. Fetch example dependencies:

```sh
cd example
fvm flutter pub get
cd ..
```

## Running Checks

Run these before opening a pull request:

```sh
fvm flutter analyze
fvm flutter test
```

Also validate the example app:

```sh
cd example
fvm flutter analyze
fvm flutter test
cd ..
```

For publishing readiness checks:

```sh
fvm flutter pub publish --dry-run
```

## Architecture and Code Guidelines

- Follow Dart and Flutter style guidelines.
- Keep the package architecture aligned with MVVM principles.
- Do not add third-party dependencies to the package unless absolutely necessary and approved by maintainers.
- Keep public APIs documented with Dart doc comments.
- Avoid breaking changes unless they are intentional, documented, and versioned correctly.

## Tests

- Add unit tests for logic changes in package code.
- Add widget tests when UI rendering or host behavior changes.
- If behavior changes are visible in the example app, update example tests as needed.

## Documentation

- Update README sections whenever public APIs or usage patterns change.
- Add a changelog entry in CHANGELOG.md for user-visible changes.

## Pull Requests

Please include:

- A clear summary of what changed and why.
- Notes about any API changes or breaking behavior.
- Test coverage details (what was added/updated).

A pull request should only be merged after CI passes.

## Versioning and Releases

This package follows semantic versioning:

- Patch: bug fixes and documentation-only updates.
- Minor: backward-compatible features.
- Major: breaking API or behavior changes.

When preparing a release, ensure CHANGELOG.md and pubspec.yaml are updated consistently.
