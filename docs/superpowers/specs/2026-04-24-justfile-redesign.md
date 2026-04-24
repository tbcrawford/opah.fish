# Justfile Redesign

## Goal

Redesign the repository `justfile` so it presents a cleaner, more task-oriented command surface with single-word recipe names only.

The new interface should:

- reduce the number of top-level recipes
- consolidate closely related commands behind argument dispatch
- keep the build-tool UX direct and discoverable
- preserve useful maintenance capabilities while aggressively simplifying the shape

## Current State

The current `justfile` exposes several narrowly scoped helper recipes:

- `test`
- `test-one`
- `test-module`
- `install-fishtape`
- `install-local`
- `uninstall`
- `lint`
- `functions`
- `config`
- `clear-cache`
- `show-cache`
- `ci`

This works, but the command surface is broader than necessary and has multiple naming styles that do not match the desired constraints.

## Constraints

- Recipe names must be one word only.
- Do not use kebab-case, camelCase, or snake_case for recipe names.
- The resulting interface should feel more like a cohesive task runner than a bag of unrelated helpers.
- Comments may be updated, but they must not mention any outside inspiration.

## Approved Command Shape

The redesigned command surface will center on these recipes:

- `check`
- `test [target]`
- `install [target]`
- `lint`
- `list`
- `config`
- `clean`
- `cache`
- `uninstall`

This is the approved shape for implementation.

## Recipe Semantics

### `check`

Runs the full local verification path.

Behavior:

- execute `lint`
- execute the full test suite

This replaces the current `ci` naming with a more task-oriented verification verb while still serving the same function.

### `test [target]`

Unifies all test entrypoints into one recipe.

Behavior:

- `just test` runs the full test suite
- `just test load` runs `tests/test_load.fish`
- `just test cache` runs `tests/test_cache.fish`
- `just test tests/test_load.fish` runs that exact file

Dispatch rules:

- if no target is provided, run the full suite
- if the argument ends in `.fish` or starts with `tests/`, treat it as an explicit path
- otherwise treat the argument as a module name and map it to `tests/test_<name>.fish`

This replaces both `test-one` and `test-module`.

### `install [target]`

Unifies installation-oriented helpers.

Behavior:

- `just install` installs the plugin locally with Fisher
- `just install test` installs `fishtape`

This replaces `install-local` and `install-fishtape`.

### `lint`

Keeps the current syntax validation behavior.

Behavior:

- run `fish --no-execute` against project Fish source files
- fail with a clear count if any syntax errors are found

No functional redesign is required beyond wording cleanup if helpful.

### `list`

Lists public functions exposed by the plugin.

This replaces the current `functions` recipe with a more general task verb.

### `config`

Shows the active `opah` config file location and contents when available.

This keeps the current purpose and name.

### `clean`

Clears local generated runtime state that is safe to remove.

Initial scope:

- clear the local `opah` secret cache

This replaces `clear-cache`.

### `cache`

Shows the current local `opah` cache contents for debugging.

This replaces `show-cache`.

### `uninstall`

Uninstalls the plugin from the local Fish environment.

This keeps the current purpose and name.

## Recipes To Remove

The redesign should remove these top-level recipe names:

- `test-one`
- `test-module`
- `install-fishtape`
- `install-local`
- `functions`
- `clear-cache`
- `show-cache`
- `ci`

Their capabilities should be absorbed into the approved command shape.

## Default Output

The default `just` invocation should remain focused on discoverability.

Expected behavior:

- still show the available recipes list
- present a smaller, cleaner set of task names
- make argument-driven recipes obvious through naming or brief comments

## Implementation Notes

The implementation should prefer simple Fish branching inside recipes over adding extra wrapper scripts unless a script meaningfully improves clarity.

For `test` and `install`, argument dispatch should stay readable inside the `justfile` itself.

The redesign should preserve the current verified behavior of running tests file-by-file where needed.

## Documentation Expectations

Comments in the `justfile` should be updated to match the new shape.

Comment style should be:

- concise
- task-oriented
- internally consistent

Comments must not mention any outside inspiration.

## Acceptance Criteria

The redesign is complete when:

1. All recipe names are single words.
2. `just test` supports full-suite, module-name, and direct-file invocations.
3. `just install` supports local plugin install and test dependency install.
4. `check` replaces the old `ci` verification role.
5. Cache-related helpers are exposed as `clean` and `cache`.
6. The old multi-word or punctuated recipe names are removed.
7. The resulting `just --list` output is materially simpler than the current one.
