# Codebase overview (for an agent picking this up cold)

This is a MATLAB lap-time simulator, refactored from the original
procedural OpenLAP/OpenVEHICLE/OpenTRACK/OpenDRAG project (Michael
Halkiopoulos) into an OOP class library, then extended into a teaching
exercise: students pick a front/rear wing (NACA 4-digit section +
incidence angle), get a whole-car Cl/Cd/aero-balance out of it, pick a
gear ratio to suit, and compete over a 24-track 2025 F1 calendar on lap
time. This file exists so a fresh agent doesn't have to re-derive the
architecture, the sign conventions, or the history of bugs already found
and fixed.

**If something here looks stale, trust the code over this doc** and
update this file — it was written at a point in time, the code keeps
moving (see "Known loose ends" at the end, and don't be surprised if
some file layout has shifted again).

## Two namespaces: `+open` (engine) vs `+api` (student-facing)

- **`+open/`** is the actual physics/simulation engine: the classes
  (`Vehicle`, `Track`, `LapSimulation`, `DragSimulation`, `SeasonResult`),
  shared physics helper functions, the XFoil wrapper, and build/example
  scripts (in `+open/+build/` and `+open/+examples/`).
- **`+api/`** is a thin, student-facing layer: `simulate_race`,
  `runSeason2025`, `genCarAeroData`, `naca4Aero`, `genAeroPolar`,
  `RaceNames` (an enum of the 24 track names), `official_evaluation`
  (WIP, see below). Several of these files (`naca4Aero.m`,
  `genCarAeroData.m`, `genAeroPolar.m`) are **byte-identical duplicates**
  of an `+open/` counterpart — when you edit one, `cp` it over the other
  and `diff` to confirm. This duplication is deliberate (keeps `+api`
  simple/flat for students) but means it's easy to fix one copy and
  forget the other; always check both.
- **`+util/`** has one file so far: `spider_plot.m` (a radar-chart
  plotting utility, used to compare two teams' lap times across all 24
  tracks at once — see `estimate_seasonPerformance.m`).
- **`data/cars/Formula_1_car.mat`** and **`data/tracks/*.mat`** are the
  built artifacts everything loads by default (one `Vehicle`, 24
  `Track`s). Source Excel files live in `+open/+examples/` (the vehicle,
  plus a couple of demo tracks) and `+open/+build/tracks_2025/` (the 24
  season tracks' source `.xlsx` files, generated from OpenF1 data) and
  `+open/+build/` (the two blank "tmp" templates for building new
  vehicles/tracks from scratch). `+open/+build/buildTracks2025.m` is the
  batch script that turns the `tracks_2025/*.xlsx` into `data/tracks/*.mat`.

## The five core classes (`+open`)

All are **value classes** (no `< handle`), living in **MATLAB class
folders** (`@ClassName/`), which matters for how methods are declared —
see "MATLAB class-folder conventions" below before adding a method.

### `Vehicle` (`+open/@Vehicle/`)
Everything about the car: raw Excel inputs (mass, tyre model, engine
torque curve, gearbox ratios, aero coefficients, brakes) plus every
derived quantity (driveline curves, shift points, force model, GGV
map), flattened into one big property list (~70 properties, no nested
structs except `shifting` (a table) and `info`-style metadata on
`Track`).

- `Vehicle.FromExcelFile(filename)` — build from an OpenVEHICLE-format
  Excel file (`Info` + `Torque Curve` sheets).
- `withAero('Cl',Cl,'Cd',Cd,'da',da)`, `withMass(M)`,
  `withGearRatioScale(scale)`, `withOptimalGearing()` — all return a
  **modified copy** (value semantics), each recomputing exactly the
  derived properties that actually depend on what changed (see
  `private/rebuildDriveline.m` for the gearing-dependent recompute
  path, shared by `withGearRatioScale`/`withOptimalGearing`). Setting a
  property directly (`veh.Cl = -5`) is *not* safe in general — several
  derived properties (`factor_drive`/`factor_aero`, the GGV map, the
  cached engine power-limit interpolant) are baked in at construction
  time and would silently go stale. **Always use a `with*` method.**
- `withOptimalGearing()` is a reference/oracle only — never called
  automatically anywhere (picking gearing to suit your aero package is
  meant to be part of the exercise). `withGearRatioScale(scale)` is the
  one students actually use (scales `ratio_final`; `scale=1` = original).
- `saveToMat`/`loadFromMat` (primary, lossless — MATLAB's native object
  serialisation, plus a `loadobj` hook, see below) and
  `saveToJSON`/`fromJSON` (secondary, human-readable; flattens the 3-D
  `GGV` array and drops the non-serialisable cached interpolant, both
  reconstructed on load).
- `plotModel()` — the 4-panel diagnostic figure (engine curve, gearing,
  traction model, GGV map).

**Performance note:** `Vehicle.enginePowerLimitInterp` is a cached
`griddedInterpolant` (built once, whenever the driveline is (re)built)
replacing what used to be a raw `interp1(vehicle_speed, ...)` call
inside the hot lap-solver loop (`vehicleModelLat`/`vehicleModelComb`),
which profiling showed was ~38% of solve time due to `interp1`'s
per-call argument-parsing overhead at 300k+ calls/season. Don't
reintroduce a bare `interp1` call against `vehicle_speed`/`fx_engine`
in the solver — use `veh.enginePowerLimitInterp(v)` instead (`'linear'`
interpolation, `'none'` extrapolation = NaN outside the grid; the one
call site needing 0-instead-of-NaN extrapolation, in
`vehicleModelComb.m`, does `isnan(...)` → 0 manually afterward).

### `Track` (`+open/@Track/`)
Track geometry: mesh, curvature, banking, elevation, sectors, apexes,
map coordinates, the finish-line arrow.

- `Track.FromShapeFile(filename)` — from an OpenTRACK-format Excel file
  (segment list + elevation/banking/grip/sector breakpoints).
- `Track.FromLoggedFile(filename)` — from telemetry (distance/speed/yaw
  or lat-acc CSV). **This path is untested** — no sample logged-data CSV
  exists in the repo, only the shape-file path has ever been run.
- Same save/load pattern as `Vehicle`. `plotModel()`, `printAsciiMap()`.

### `LapSimulation` (`+open/@LapSimulation/`)
The actual point-mass lap-time solver (`private/runSolver.m` plus
`vehicleModelLat.m`/`vehicleModelComb.m`/`nextPoint.m`/etc. — this is
where almost all the CPU time goes). `LapSimulation.Run(veh, tr)` runs
it. Properties mirror the original OpenLAP `sim` struct almost exactly
(one property per channel, each a `struct('data',...,'unit',...)`) —
`exportCSV(veh,tr,filepath,freq)` and `plotModel(veh,tr)` both need the
`Vehicle`/`Track` passed back in alongside the result, since track
geometry and the GGV envelope aren't part of `LapSimulation` itself.

**Cornering physics is a two-axle (front/rear) model**, not a single
lumped 4-wheel friction circle — see `+open/maxAxleLimitedLateralForce.m`,
`axleNormalLoads.m`, `solveAxleCorneringSpeed.m`, `maxCorneringSpeed.m`
(package-level functions, not private to one class, since both `Vehicle`
(GGV map) and `LapSimulation` need them). The key result: for
steady-state cornering, moment balance about the CG fixes the
*required* front/rear force split at `df:(1-df)` (mechanical weight
distribution) regardless of aero, while `da` (aero balance) only changes
each axle's *available* grip — so whichever axle's required share first
exceeds what it can produce sets the car's cornering limit. This is why
`da` has a genuine interior optimum (near `da≈df`) rather than being a
one-way lever, verified empirically during development.

### `DragSimulation` (`+open/@DragSimulation/`)
Straight-line accel/brake simulation (`DragSimulation.Run(veh)`).
Independent of `LapSimulation`; used for 0-60/0-100/braking-distance
style analysis, not part of the season-competition pipeline.

### `SeasonResult` (`+open/@SeasonResult/`)
One team/car setup's lap times across all 24 tracks (built by
`runSeason2025`). `comparePositions([team1,team2,...])` is the static
method that combines several `SeasonResult`s into a race-by-race
position table + heatmap. Also carries `fuelPerLap`/`raceLaps`/
`estimatedRaceFuel_kg` — informational only, a *naive* (not mass-
corrected) extrapolation; see "Fuel modelling" below for why it's
naive on purpose.

## MATLAB class-folder conventions (read this before adding a method)

Every class above is a **class folder** (`@ClassName/`), not a single
`classdef` file, so methods can live in their own files:

- A method with **default attributes** (ordinary public instance
  method) just needs its own file in the class folder — **do not**
  declare it in the `classdef` block at all.
- A method with **non-default attributes** (`Static`, non-public, etc.)
  needs a **bare signature** (no `function`...`end` body!) listed in the
  classdef's `methods (Static)` block, e.g. `obj = FromExcelFile(filename)`
  — not `function obj = FromExcelFile(filename)\nend`. Getting this
  wrong (wrapping it in `function`/`end`) silently makes MATLAB use the
  *empty* body in the classdef file as the real implementation instead
  of the separate file, and every call returns nothing. This bit us
  once; don't reintroduce it.
- Files in `@ClassName/private/` are plain functions (not real class
  methods), callable only from other files inside that same class
  folder — this is where the "section" helper functions live (e.g.
  `Vehicle/private/computeGGVMap.m`, `Track/private/computeMesh.m`).
  They are **not** shared across different classes' class folders. Where
  physics genuinely needs to be shared across classes (e.g. the two-axle
  cornering model, needed by both `Vehicle` and `LapSimulation`), it
  lives as a plain package-level function directly in `+open/` instead
  (e.g. `+open/maxAxleLimitedLateralForce.m`), callable as
  `open.functionName(...)` from anywhere.
- **`Vehicle.loadobj`** exists specifically for MATLAB's *class
  evolution* problem: `load()`-ing an object from a `.mat` file uses
  MATLAB's native deserialisation and **bypasses the constructor
  entirely**. When `enginePowerLimitInterp` was added as a new property,
  old `.mat` files (saved before it existed) loaded back with that
  property at its empty default, and the constructor's own
  "auto-build if missing" logic never got a chance to run. `loadobj` is
  the correct hook for "fix up an object on load regardless of how old
  the saved file is" — if you add another property with this kind of
  auto-derived/cached nature, you may need to update `loadobj` too, not
  just the constructor.

## THE sign convention — read this before touching any aero/drag code

**As of this session's last major change: `Cl` is negative for
downforce, `Cd` is positive (a drag magnitude).** This is the ordinary
aerodynamics convention. It was **not** always true here — the original
OpenLAP-derived `Vehicle` stored *both* `Cl` and `Cd` as negative, an
implementation detail of force-summation code that just *adds* aero
terms (`ax_drag = Aero_Dr + Roll_Dr + Wx`) rather than subtracting them,
which only works if `Cd` (and `Cr`, rolling resistance) are themselves
negative going in. That was fixed at the source: the Excel file's
`Cd`/`Cr` are now positive, and every formula that computes a drag-like
quantity from them (`Aero_Dr`, `Roll_Dr`, `fx_aero`, `fx_roll`,
`Fx_aero`, `Fx_roll`, and the cubic-equation coefficients in
`withOptimalGearing.m`) has a **leading `-` inserted** so the computed
*intermediate* stays numerically identical to before — i.e. `Cd`/`Cr`
becoming positive did not change any physics, only the stored sign of
the raw input. If you're adding a new formula that reads `veh.Cd` or
`veh.Cr` directly, remember it needs that same leading negative sign to
produce a "opposes motion" quantity.

`Vehicle.Cl` was **already** negative for downforce and did not change.

**`+api.simulate_race`/`+api.runSeason2025`** now pass `Cl`/`Cd` straight
through to `Vehicle.withAero` with **no sign flip at all** — they used
to negate both (when `Vehicle.Cd` was still negative), then briefly
negated only `Cd`, then settled on no negation once `Vehicle.Cd`'s own
sign was fixed. If you see a stale comment or an old commit implying
otherwise, the *current* code (both functions) does a plain pass-through
— verify against the actual `veh.withAero(...)` line, not a comment.

**`open.naca4Aero`'s `InvertWing` option** is the mechanism for
modelling a downforce wing (a NACA 4-digit code can't express negative
camber directly, so there's no way to "just flip the geometry"). It
mirrors the angle of attack for the actual XFoil solve and negates the
reported `Cl` — physically correct (not just a cosmetic sign flip)
because inverting a wing mirrors its whole flow field, including which
stall boundary applies for a cambered section. **Convention: negative
input `AoA` to `naca4Aero(...,'InvertWing',true)` means "downforce
incidence"** (matches the XFoil-angle-mirroring math directly) —
verified: `naca4Aero('2412',-10,'InvertWing',true)` gives exactly
`-naca4Aero('2412',10)`'s `Cl`, same `Cd`.

**`open.genCarAeroData`** wraps two `naca4Aero(...,'InvertWing',true)`
calls (front + rear wing) plus a fixed body/floor baseline
(`CL_body`/`CD_body`, defaults -3/1) into a whole-car `[CL,CD,aeroBalance]`,
already reference-area-converted (each wing's force scaled by its own
planform area vs the car's frontal area, not just averaged) and already
correctly signed to drop straight into `Vehicle.withAero`,
`api.simulate_race`, or `api.runSeason2025` with **zero further
conversion**. Its own `frontAoA`/`rearAoA` inputs are **POSITIVE for
downforce** (the opposite convention from `naca4Aero`'s raw `InvertWing`
input!) — `genCarAeroData` negates internally
(`naca4Aero(section,-frontAoA,'InvertWing',true)`) specifically so its
own interface is the intuitive "bigger number = more downforce" for a
caller who isn't thinking about the AoA-mirroring mechanics underneath.
**This double-negative (naca4Aero wants negative-in, genCarAeroData
wants positive-in) is a real, easy place to get confused — it was
implemented wrong on the first pass in this exact session** (forgot the
negation, caught it by testing `aeroBalance` shifting the wrong
direction for an asymmetric wing choice) — if you touch this function,
re-verify with the same test: make one wing bigger, confirm
`aeroBalance` moves *toward* that wing, not away.

## Fuel modelling (`open.simulateFuelCorrectedRace`)

A **separate, optional, expensive** (~10x a single lap sim — it's a
fixed-point iteration sampling ~5 mass points × ~2-3 outer iterations)
race simulation that accounts for the car getting lighter as fuel burns
off. **Deliberately not part of `runSeason2025`/`SeasonResult`'s main
lap-time metric** — empirically, across the 2025 season, it shifts the
optimal downforce trim on only ~3/24 tracks and doesn't change the
overall season-wide spread of optimal trims, so it wasn't judged worth
paying for on every team/track evaluation. `SeasonResult.fuelPerLap`
(from the ordinary single-lap sim, free) and `estimatedRaceFuel_kg`
(naive `fuelPerLap × raceLaps`, no mass feedback) exist so the *number*
is visible without paying the 10x cost — the gap between that naive
number and a real `simulateFuelCorrectedRace` run is intentionally left
as a "limitations" discussion point for students, not something to
silently correct for them.

`Vehicle.n_thermal` (engine thermal efficiency) was recalibrated from
0.35 (a generic/older non-hybrid engine figure) to 0.50 (representative
of a modern hybrid F1 power unit) specifically because fuel burn is
directly inversely proportional to it, and 0.35 was overshooting real
race fuel loads by ~25-30%.

## Known loose ends (verify before relying on these)

- **`example_estimateCarAeroData.m`** calls `api.genCarAeroData('0015',-10,...)`
  — **negative** AoA. Per the convention above, `genCarAeroData` expects
  *positive* AoA for downforce, so this example may currently be
  requesting **lift, not downforce**, silently. Worth checking whether
  this is a stale example (predates the sign-convention fixes) or a
  sign of the convention still being unsettled in practice — verify by
  checking whether `cl1`/`cl2` come out negative when actually run.
- **`+api/official_evaluation.m`** looks unfinished: its docstring is a
  verbatim copy of `runSeason2025`'s (never updated for its own
  signature), and the top-level `official_evaluation.m` script that
  calls it only passes 1 of the function's 6 required arguments. Likely
  intended as a single combined "wing choice → season result" entry
  point (folding `genCarAeroData` + `runSeason2025` into one call) but
  not wired up yet.
- `Track.FromLoggedFile` (logged-telemetry track building) has never
  been exercised end-to-end — no sample CSV exists in the repo.
- If you add a new `Vehicle`/`Track`/etc. property that's derived from
  others (cached, computed, non-serialisable, etc.), check whether it
  needs the same three-part treatment `enginePowerLimitInterp` got:
  auto-build in the constructor, explicit rebuild wherever its inputs
  change, and a `loadobj` fallback for old `.mat` files.

## Quick orientation for common tasks

- **Run one lap sim:** `+open/+examples/example_lapSimulation.m`
- **Run one drag sim:** `+open/+examples/example_dragSimulation.m`
- **Build a vehicle/track from Excel:** `example_loadVehicle.m` /
  `example_loadTrack.m` in `+open/+examples/`
- **Rebuild all 24 season tracks:** `+open/+build/buildTracks2025.m`
- **Run one team's season:** `api.runSeason2025(Cl,Cd,AeroBalance,GearRatioScale,TeamName)`
- **Run one team on one track (with a plot):** `api.simulate_race(api.RaceNames.Monza,Cl,Cd,AeroBalance,GearRatioScale,TeamName)`
- **Turn a wing choice into Cl/Cd:** `api.genCarAeroData(frontSection,frontAoA,rearSection,rearAoA)`
- **Compare two teams' seasons:** `open.SeasonResult.comparePositions([res1,res2])`
  or the `util.spider_plot` radar-chart approach in `estimate_seasonPerformance.m`
- **Check XFoil convergence directly:** `api.naca4Aero(section,AoA)` (add
  `'iterCap',1000` if it's failing to converge — but note some
  AoA/Reynolds combinations, especially at negative AoA on a cambered
  section, genuinely don't converge no matter the iteration cap; that's
  real aerodynamics, not a bug)
