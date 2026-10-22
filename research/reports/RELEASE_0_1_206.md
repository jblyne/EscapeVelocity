# Local Mac build and repository update 0.1.206

Includes all work since 0.1.178: staged world reconstruction and landing/orbit artwork; faithful HD menu/startup art and animation; original Sillycon font recovery; classic Mac dialogs with native Open Pilot; bar slot-machine gambling; illustrated full-height story with distinct alternating paintings, blue Confederation/red Rebellion colors, nonoverlapping fades, corrected single-sample rendering, and fade through black into flight.

Validation on 2026-10-21:

- Full acceptance run: **113/113 scripts passed**, zero failures (`tools/run_acceptance.py --output builds/acceptance-0.1.206-prepush`).
- Native renderer visual checks at standard and ultrawide sizes for the final story art, and earlier checks for title animation, dialogs, gambling, and landing screens.
- Local Mac app version: 0.1.206; `codesign --verify --deep --strict` passed. Ad-hoc signed; not Developer ID signed or notarized.
- Packaged download: `builds/Escape-Velocity-HD-0.1.206-macOS.zip`.
- SHA256: `5b4c59a91db3f2f3660df7bb5f431fbda37e41ac0c5e19262e9fd038398d8786`.

The app archive and detailed test logs remain local build artifacts. Original-game manual parity and Intel/clean-machine execution limitations from the Phase 6 acceptance report still apply. This repository update does not itself publish a new GitHub Release.
