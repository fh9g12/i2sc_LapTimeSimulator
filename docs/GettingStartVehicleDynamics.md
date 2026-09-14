# Getting started: lap simulation and vehicle performance

This is the starting guide for the **performance sub-team**. Your job is
to work out which Cl/Cd/aero-balance/gear-ratio combination is fastest —
first over one race, then over the full season.

## Running a lap simulation

Two functions, both returning lap (and sector) times:

```matlab
api.simulate_race(api.RaceNames.Monza, Cl, Cd, AeroBalance, GearRatioScale, TeamName)   % one track, plots the result
api.runSeason2025(Cl, Cd, AeroBalance, GearRatioScale, TeamName)                        % all 24 tracks
```

`Cl` is negative for downforce, `Cd` is positive (ordinary drag
convention). `AeroBalance` is the front fraction of downforce (0–1).
`GearRatioScale` scales the car's gearing relative to the baseline car
(`1` = unchanged, `>1` = shorter/more acceleration/lower top speed,
`<1` = taller/less acceleration/higher top speed). These are exactly the
`[CL, CD, aeroBalance]` the aero sub-team's `api.genCarAeroData` produces
— feed its output straight in.

## The vehicle model, very briefly

You don't need the details, just the shape of it: the simulator builds a
**GGV surface** for your car — a map of the maximum acceleration it can
sustain in every direction (braking, accelerating, cornering, and blends
of the two) at every speed. This is the car's "limit of grip" envelope.
Then, at every point around the track, the lap simulation works out how
fast the car can go while (a) staying on or inside that grip envelope and
(b) turning at the rate the track's curvature actually demands at that
speed. The lap time is just the result of doing that all the way around,
sector by sector.

If a GGV (or "GG") diagram is new to you, these two are a good, quick
introduction:

- Video: [Understanding the G-G-V Diagram](https://www.youtube.com/watch?v=zMOz6-cHmBk)
- Article: [f1technical.net — The GGV diagram](https://www.f1technical.net/features/10697)

You can also visualise your *own* car's GGV envelope directly:

```matlab
api.plotGGV(Cl, Cd, AeroBalance, GearRatioScale)
api.compareGGV(Cl1, Cd1, AeroBalance1, GearRatioScale1, 'Car A', ...
               Cl2, Cd2, AeroBalance2, GearRatioScale2, 'Car B')
```

`api.compareGGV` overlays two setups on one plot — a quick way to *see*
what "more downforce enlarges the envelope" (or what a gear ratio change
does to it) actually looks like, rather than just reading it off a lap
time.

## What your four parameters do

- **Cl (downforce)**: more downforce enlarges the GGV envelope —
  especially cornering and braking grip — so the car goes faster through
  corners. It does *not* come free.
- **Cd (drag)**: more drag lowers top speed and slows acceleration on
  straights. Cl and Cd are not independent choices — more downforce
  (from the aero sub-team's side) generally comes bundled with more
  drag, so the real question is never "how much downforce" alone, it's
  "how much lap time does this downforce cost in drag, track by track."
- **Aero balance**: shifts downforce between the front and rear axle.
  Push it too far from the car's mechanical (weight) balance and one
  axle runs out of grip before the other — there's a genuine sweet spot,
  not a "more front is always better" direction.
- **Gear ratio scale**: sets how the engine's power is deployed against
  road speed. Shorter gearing helps corner-exit acceleration but caps
  top speed sooner; taller gearing does the opposite. The right choice
  depends on your Cd (a high-drag car needs shorter gearing to still
  accelerate) and on the track (a high-speed track rewards taller
  gearing more than a stop-start one does).

None of these four are independent of the others — that's the point of
running studies rather than guessing.

## Suggested workflow

You don't have real aero data on day one, so start simple and add
complexity only once you've learned something from the previous step.

1. **One-at-a-time baseline sweeps.** Fix Cl and Cd at a sensible
   baseline (`Cl = -4`, `Cd = 1.2` is a reasonable starting point) and a
   nominal gear ratio scale of `1`. On a single track, sweep aero balance
   on its own with `api.simulate_race`, holding everything else fixed,
   and see where its optimum lies. Then do the same for gear ratio scale
   on its own. This is quick, and gives you a feel for both parameters
   before you complicate things by varying everything together.

2. **Collapse Cl and Cd into a single dial.** Cl and Cd are not
   independent — more downforce always costs more drag — so rather than
   sweeping them as two separate numbers, link them with a simple
   placeholder equation and sweep the *one* parameter that controls both:

   ```
   Cl(x) = -(4 + x)
   Cd(x) = 1.2 + alpha*x
   ```

   Start with `alpha = 0.1` as an arbitrary first guess (you don't have
   real aero data yet) and run a sensitivity sweep over `x` itself. This
   is a real simplification — it assumes a straight-line trade-off,
   which is unlikely to be exactly right — but it turns "how much
   downforce vs. how much drag" into one dimension instead of two, and
   it's easy to revisit: once the aero sub-team's own Cl/Cd sensitivity
   study is available, come back and refine `alpha` (or drop the
   equation altogether and sweep their real achievable pairs directly).

3. **Optimise for one race first.** Pick a single, fairly "normal"
   track to start with — Silverstone is a sensible choice — and search
   over your now-three parameters (`x`, aero balance, gear ratio scale).
   A full grid search gets expensive fast in three dimensions, so try a
   **Monte Carlo DOE** instead: sample a batch of random combinations
   across sensible ranges, run each through `api.simulate_race`, and see
   which region of the parameter space comes out fastest. This is quick,
   gives you a rough sense of where the optimum lives, and is a useful
   first taste of DOE-style thinking before committing to a finer
   sensitivity study around whatever region looks best.

4. **Repeat across a few different track types, then race a season.** A
   high-speed track (e.g. Monza), a twisty one (e.g. Monaco) and a
   mixed circuit will likely want different trims — that trade-off is
   exactly what the competition is designed to reward. Once you have a
   shortlist of promising candidates from a few individual tracks, run
   each one over the full season with `api.runSeason2025` and see how
   they actually score once every track counts.

5. **Close the loop with the aero sub-team.** By this point you should
   have a rough sense of the Cl/Cd/aero-balance region you want. Take it
   back to the aero sub-team, compare it against what's actually
   achievable from a real wing choice, and iterate: run one final, tight
   sensitivity study around a couple of real candidate wing choices, and
   pick your submission from there.

## A word of warning

Not every Cl/Cd/aeroBalance combination you'd like to run is physically
achievable from a real wing choice — some are just outside what any
sensible NACA section/AoA combination can produce, and some XFoil simply
won't converge for. Treat the aero sub-team's achievable-range results as
a hard constraint on your search, not a suggestion: it's on both of you
to work together and narrow in on a feasible, fast combination, not to
each optimise separately and hope the answers overlap.

## A note on strategy and time

- **You're racing other teams, not just the simulator.** If every team
  converges on the same "optimal" setup, the season is decided almost
  entirely by who searched most thoroughly, not by who thought most
  cleverly about the trade-offs. A team that deliberately picks a
  different strategy — trading average pace for being unusually strong
  on two or three specific track types — might win races nobody else
  does, without ever finding "the" single optimum. Worth discussing as a
  team before you commit to chasing one global best.
- **Don't spend the whole term chasing the last half a percent.** It's
  easy to burn a lot of time convincing yourself you've found the true
  optimum, when a good-enough answer found quickly leaves you more time
  for the report — and for actually understanding *why* your car is
  fast, which is worth more than its last tenth of a second. As a guide,
  budget somewhere around **8–12 hours total** for this exercise. As
  Voltaire put it: perfect is the enemy of good.
