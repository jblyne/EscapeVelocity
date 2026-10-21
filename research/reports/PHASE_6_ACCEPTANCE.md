# Phase 6 — acceptance and release candidate 0.1.178

21 October 2026. This phase has an automated/release track and a manual campaign comparison track. **A candidate release is not a claim of completed original-game parity.** Add-ons remain excluded; requested F-14 controls, equipment, audio and other custom features remain.

## Reproducible acceptance

Run `python3 tools/run_acceptance.py`. Each of the 108 `test_*.gd` scripts runs sequentially in a separate Godot process with a test pilot path, a per-script timeout, retained engine/console logs and a JSON result manifest under `builds/acceptance-0.1.178`. Exit code zero alone does not pass: script/parse/assertion errors and failed checks also fail the run. Pass `--test test_filename.gd` to run selected scripts and `--output` to retain a separate run.

The campaign harness covers nine story routes with acceptance, actor objectives, return/debrief, equipment grants, prerequisite bits and save/reload. It uses a qualified pilot, accelerated travel and controlled combat, not human play. The Phase 1 audit separately checks all 116 original mission records. Other tests exercise deadlines, repeat jobs, cargo scans and mission failure/retry; cloak installation; bar offers and location-specific reports; boarding cargo and protected objectives; fuel/gravity rules; fleet/fighter persistence; capture, release, wages and cargo; bribes and secret controls; trade autopilot/manual cancellation; selected firing and Maverick volleys; domination, tribute and hunter attribution; destroyed worlds; achievements and badge navigation; pilot file isolation; UI dimensions and audio sequencing.

### Findings corrected during this phase

- New pilots omitted the default `satellite: false` secret while restored pilots included it. New and restored pilot snapshots now use the same schema, without granting the unlock or invalidating older saves.
- Legacy checks now follow the documented current communications height and verify action buttons stay inside the dialog; compare arrival speed to the actual hull/upgrade fields; wait for menu presentation and discard setup time before checking machinery cues; use the current F-14 item label; and check the actual active pilot path rather than a hardcoded fixture filename. These update stale tests, not the accepted gameplay rules.

### Result ledger

- Final run: **108 / 108 Godot scripts passed; zero failed scripts**, retained in `builds/acceptance-0.1.178-final/results.json` with individual logs. Includes all six formerly failing scripts after the fixes above.
- Python resource-reader/menu tests: **8 passed**; both new Python tools compile successfully.
- Rendered native checks: communications **10 / 10**, menu presentation **23 / 23**, including frame-to-frame rail/piston stability. These are scripted graphical tests, not manual play.
- Standalone export: version **0.1.178**, universal `x86_64 arm64`; `codesign --verify --deep --strict` succeeds. Apple Silicon native boot reaches the galaxy map at **1440×900** and port at **2560×1080**, with screenshots inspected for legible, contained controls (`/tmp/ev178-map.png`, `/tmp/ev178-wide-port.png`). The port correctly disables full-tank refueling.
- The first short 240-frame smoke run exited before its requested screenshot; the longer 1800-frame run produced the actual port image. Boot success is based on the rendered game, not process exit alone.
- Export logs contain a sandbox-denied editor-settings write outside the project, after successful export; test processes also emit the host CA-certificate warning. Neither is a gameplay pass criterion. Existing exit-time resource-leak warnings remain diagnostic debt; they do not establish gameplay failures.
- Full manual campaign comparisons, native interactive input (computer-control tool timeout), Intel execution and clean-machine Gatekeeper checks remain **pending**, as detailed below.

## Manual campaign comparison — pending

No full original-game manual campaign playthrough is claimed. Native computer-control attempts timed out during this run; scripted rendered checks and packaged-app smoke tests do not replace playthrough evidence. For each row, use a separate pilot for incompatible branches, record the original and remake version, offer origin, acceptance prerequisites, next objective, encounter result, debrief/reward, equipment, final progression, saved pilot and any discrepancy. Reopen the save mid-chain. Use ordinary travel/combat for manual acceptance; label any cheats explicitly.

| Route | Mission IDs | Manual status / final expected result |
|---|---|---|
| Rebellion military | 172,163–165,184–189 | Pending; cloak, rescue/records, alien finale, faction clearance |
| Confederation military | 171,166–170,190–194 | Pending; particle beam and alien finale |
| Environmental investigation | 152–156 | Pending; final progression bit 28 |
| Starbound Shipping | 173–177 | Pending; final progression bit 47 |
| Colony assistance | 178–183 | Pending; defend Turin V, bit 52 |
| UGE | 209–219 | Pending; membership/redemption, bit 79 and cleared bit 78 |
| Astrodyne | 172,230–235 | Pending; board the prototype, return cargo, tractor beam/bit 107 |
| Artemis bounty hunters | 236–241 | Pending; Sirius data, rescue, hunters, finale/bit 113 |
| Escort carrier operations | 171,242–243 | Pending; carrier objective and bit 114 |

Manual unusual-case checklist: full hold at pickup; eight active contracts; exact deadline day and late failure; mission-required hostile port clearance versus ordinary refusal; cloak confiscation/retry; mission target disabled, boarded then destroyed; departure before boarding; auxiliary-wave exhaustion; old/invalid/dead pilot import; new-pilot preservation; fleet loss/release/take-command with cargo; empty fuel/blocked departure; autopilot interruption and resume; repeated bar visits versus a different bar; domination hunter cap and save/reload; ultrawide/minimum-window controls; each audio cue by listening in the original and remake.

## Standalone and distribution boundaries

The Mac export is a universal `arm64`/`x86_64` app with embedded resources. Verify ad-hoc signatures, archive SHA-256, extract to a separate directory and launch that extracted app with isolated pilot paths. Capture title, port and map at normal/ultrawide sizes. This machine can execute Apple Silicon; an Intel machine and a clean downloaded/quarantined installation still need testing. The app is not Developer ID signed or notarized. Windows/Linux are not packaged. Exact original AI cadence, some timing/engine conversions and full audiovisual comparison retain the limits in Phases 2–5.

`tools/package_macos_release.py` verifies the exported version/signature, bundles install notes, credits and this ledger, and creates a versioned ZIP plus checksum. GitHub publication uses an explicitly labeled **pre-release** until the manual comparison and clean-machine checks above are completed. It must not be marked the final fidelity release merely because automated tests pass.

## Final artifact verification

The ZIP was extracted to `/tmp/ev178-extracted`. The extracted app passed strict deep signature verification and reached its rendered title screen with an isolated absent pilot (`/tmp/ev178-extracted-title.png`), independently of the Godot editor. SHA-256 was recomputed and matched the sidecar:

`ce0590436846debeac81694762f4afc9935a2a6db10b82e8f81285b9b141ed2d` — `Escape-Velocity-HD-0.1.178-macOS.zip`.

The packaged ledger predates this final archive/extraction check; the source ledger records it here. The complete machine-readable final script results are in `PHASE_6_RESULTS.json`.
