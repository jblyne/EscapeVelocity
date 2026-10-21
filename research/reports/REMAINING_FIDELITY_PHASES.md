# Remaining original-game fidelity phases

Accepted plan, 21 October 2026. Add-ons remain excluded. Preserve requested Maverick features and current default firing controls throughout.

| Phase | Scope | Status / evidence |
|---|---|---|
| 1. Mission clarity and reliability | Objectives, rewards, prerequisites, grants, failures, retries and handoffs | Delivered in 0.1.158; see PHASE_1_MISSION_AUDIT.md. Full manual campaign comparison remains Phase 6. |
| 2. Flight and combat timing | Acceleration, turning, weapon cadence, lifetime and recovery | Timing baseline delivered in 0.1.159; see PHASE_2_FLIGHT_COMBAT_TIMING.md for source constants, tests and explicit integration differences. |
| 3. NPC behavior and encounters | Pursuit, retreat, civilian evasion, inspections, spawning and departures | Behavior baseline delivered in 0.1.164; see PHASE_3_NPC_BEHAVIOR.md. Civilian threat response, retreat, patrol approach/motion gating, source speed and launch drift, weighted arrivals and departures verified. Exact original state-machine timing remains a documented comparison boundary. |
| 4. Fighters and fleet fidelity | Endurance, recall, docking, service, ammo and carriers | Lifecycle baseline delivered in 0.1.166; see PHASE_4_FIGHTERS_AND_FLEETS.md. Full loadouts, physical recall, free dock servicing, carrier recovery and validated deployed-wing persistence covered. Exact original endurance/AI timing remains an explicit comparison limit. |
| 5. Bribes and secrets | Bribery formulas, willingness, title modifiers and Satellite of Love | Baseline delivered in 0.1.174; see PHASE_5_BRIBES_AND_SECRETS.md. Source wallet/government quotes, willingness/negotiation, About modifiers and retained Satellite presentation verified; comparison limits documented. |
| 6. Full-game acceptance and release | Manual campaign paths, unusual cases, standalone acceptance and GitHub release | Acceptance/release candidate prepared in 0.1.178; see PHASE_6_ACCEPTANCE.md. Full-suite runner, unusual-case coverage and standalone packaging are tracked separately from pending manual campaign comparisons, Intel execution and clean-machine checks. Candidate publication is a prerelease, not a full-parity signoff. |
