# Project overview: design an F1 season campaign in MATLAB

Welcome. In this project you're tasked with running the design office of
an F1 team for a season. As a 4-person team, you'll choose a front wing,
a rear wing and a gear ratio for your car, and race it over the full
2025 calendar (all 24 tracks) against every other team in the class.
It's built around a MATLAB lap-time simulator, and the point is twofold:

1. **Get comfortable with MATLAB** by adapting existing example scripts
   to run studies, rather than writing anything from scratch.
2. **Practise good engineering decision-making** — plotting, comparing
   options, and justifying a final choice with evidence.

You do **not** need to understand the simulator's internals. Everything
you need lives in the `api` package (functions like `api.genCarAeroData`,
`api.runSeason2025`, `api.simulate_race`) — treat it as a black box that
takes your parameters and returns lap times.

## What you're choosing

Four numbers, per team:

- **Front wing**: a NACA 4-digit aerofoil section + angle of attack (AoA)
- **Rear wing**: same, independently
- **Gear ratio scale**: how much shorter/taller to make the car's gearing
  relative to the baseline car

The wing choices determine your car's **Cl** (downforce), **Cd** (drag)
and **aero balance** (front/rear split of that downforce). Together with
gear ratio, these four quantities — Cl, Cd, aero balance, gear ratio —
are everything that separates one team's car from another's.

## Suggested team structure: two sub-teams

- **Aero sub-team**: explore aerofoil sections and angles of attack to
  work out what range of Cl/Cd/aero-balance combinations are actually
  achievable. Start here: [GettingStartedAero.md](GettingStartedAero.md)
- **Performance sub-team**: explore what Cl/Cd/aero-balance/gear-ratio
  combination is *fastest* — starting with a single race, then the full
  season. Start here:
  [GettingStartVehicleDynamics.md](GettingStartVehicleDynamics.md)

The two sub-teams need each other: aero can tell you what's physically
achievable, performance can tell you what's fast, but only the overlap of
the two is a real car. Expect to go back and forth — performance asking
aero "can we get more downforce without this much drag?", aero telling
performance "that Cl is only reachable at an AoA that also costs you
this much Cd." Budget time for that conversation; it's the actual
engineering content of the exercise, not a side effect of it.

## How the competition works

Submit your team's final parameters (front/rear wing section + AoA, gear
ratio scale) via the Microsoft Teams form. Each team's car is then run
over every track on the 2025 calendar. For each race, teams are ranked
by lap time (like qualifying) and awarded points on the standard F1
points system. The team with the most points after all 24 races wins.

A fast car everywhere beats a car that's brilliant at two tracks and
nowhere else — so once you have a candidate setup, check it across the
*whole* season, not just your favourite track.
