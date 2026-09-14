# OpenLAP Lap-Time Simulator (Y2 MATLAB Teaching Edition)

A MATLAB point-mass lap-time simulator, used as the engine for a University
of Bristol Year 2 MATLAB teaching exercise: student teams design an F1 car
(front/rear wing + gear ratio), simulate it over the full 2025 F1 calendar,
and compete on lap time.

## What this is based on

This project is built on top of the **OpenLAP / OpenVEHICLE / OpenTRACK /
OpenDRAG** project by **Michael Halkiopoulos** (Cranfield University MSc
Advanced Motorsport Engineer), originally published on the MATLAB File
Exchange and GitHub ([github.com/mc12027](https://github.com/mc12027)),
licensed under GPL v3. The original procedural scripts implemented a
point-mass lap-time simulation for a racing vehicle from vehicle/track
Excel inputs.

For this teaching project, the original code was:

1. **Refactored** from standalone procedural scripts into an
   object-oriented class library (`Vehicle`, `Track`, `LapSimulation`,
   `DragSimulation`, `SeasonResult` — see [`+open/`](+open)).
2. **Extended** with an aerofoil/aero package (NACA 4-digit wing sections
   via an XFoil wrapper) so that a car's downforce/drag can be derived from
   a chosen wing geometry rather than set directly.
3. **Wrapped** in a thin, student-facing API (see [`+api/`](+api)) that
   hides the simulator internals behind a small set of functions
   (`simulate_race`, `runSeason2025`, `genCarAeroData`, etc.), and packaged
   into a competitive exercise across the 2025 F1 season calendar.

See [`docs/CODEBASE_OVERVIEW.md`](docs/CODEBASE_OVERVIEW.md) for the full
architecture writeup, and [`docs/Overview.md`](docs/Overview.md) for the
student-facing project brief.

## License

The original OpenLAP project is licensed under GPL v3 (see
[`+api/LICENSE`](+api/LICENSE)); this derivative work carries the same
license.
