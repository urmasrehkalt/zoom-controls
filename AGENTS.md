# Development workflow

All changes originate from a GitHub issue with a description and acceptance criteria, assigned to the current developer. Plan before coding. Create feature/<issue>-name or bugfix/<issue>-name from main. Commits use #<issue>: Imperative summary.

Run scripts/test.sh, scripts/build-app.sh and scripts/test-icons.sh. Tests must work without production services or credentials. Sync main before final verification. Keep unfinished work committed and pushed on its branch. Merge to main only with explicit user approval, using squash merge, then close the issue.

The app is a macOS Accessibility client. Preserve window recovery and the bundle identity ee.urmasrehkalt.zooom. Never declare live screen-sharing behavior verified based only on logic tests. Never commit secrets or add generated-by attribution.

Imported commits before the standalone extraction use issue numbers from the original repository.
