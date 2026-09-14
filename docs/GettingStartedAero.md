# Getting started: aerofoil sections and car aero data

This is the starting guide for the **aero sub-team**. Your job is to
work out what range of whole-car Cl (downforce), Cd (drag) and aero
balance (front/rear split) is actually achievable from real wing
choices — the performance sub-team needs that range to know what's
worth chasing.

## The tool: XFoil

Under the hood, this project uses **XFoil**, a widely-used 2D panel-method
solver for aerofoil sections. Give it a shape and an angle of attack and
it computes the resulting lift and drag coefficients (Cl, Cd) for that
2D section — this is a real viscous solve, not a lookup table, so it can
fail to converge for some AoA/section combinations (more on this below).
You never call XFoil directly; `api.naca4Aero` wraps it for you.

## From a wing choice to Cl/Cd

A wing shape here is a **NACA 4-digit section**, e.g. `'2412'`:

- 1st digit: max camber, as %chord (`2` = 2%)
- 2nd digit: position of max camber, in tenths of chord (`4` = 40%)
- 3rd/4th digits: max thickness, as %chord (`12` = 12%)

`'0012'` is a symmetric section (no camber); a cambered section like
`'2412'` naturally generates more lift for the same angle of attack.

Two functions matter for you:

```matlab
[Cl, Cd] = api.naca4Aero(section, AoA)
```
Runs one wing section at one (or several) angles of attack and returns
its 2D Cl/Cd. Useful for understanding one section in isolation. **AoA
is NEGATIVE for downforce** — every wing in this project is modelled
mounted upside down to generate downforce (a NACA code can't express
negative camber directly, so this is how it's done instead), and that's
the default behaviour, so you don't need to set anything extra to get it.

```matlab
[CL, CD, aeroBalance] = api.genCarAeroData(frontSection, frontAoA, rearSection, rearAoA)
```
The function you'll actually use. Give it a front wing and a rear wing
choice and it returns the **whole-car** Cl, Cd and aero balance — already
converted for wing area, already including a fixed body/floor
contribution and induced drag, and already in the right sign convention
to feed straight into the performance sub-team's simulation. Same
convention as above: `frontAoA`/`rearAoA` are negative for downforce.
See `help api.genCarAeroData` for the full set of options (wing
chord/span, body aero, etc.) if you want to go beyond the defaults.

Two more functions help you look before you leap:

```matlab
api.plotNACA(section, AoA)   % plots exactly what that section/AoA looks like — instant, no XFoil
api.genAeroPolar(section)    % sweeps AoA and plots Cl, Cd and the drag polar
```

`api.plotNACA` draws the section mounted upside down and pitched at
`AoA`, matching exactly what `api.naca4Aero` is analysing underneath —
run it on your chosen section/AoA before spending time on a real polar,
just to sanity-check you're picturing the right thing.

## Suggested first steps

1. Run `api.plotNACA(section, AoA)` on a few candidate section/AoA
   combinations to see what they actually look like.
2. Run `api.genAeroPolar` on one or two sections to see how Cl and Cd
   respond to AoA — this is your first sensitivity study. Look for
   where the curve goes ragged or stops: that's stall/non-convergence.
3. Pick a front and rear section and sweep AoA through
   `api.genCarAeroData` for each, building up a table of achievable
   [CL, CD, aeroBalance] combinations. This is the design space you'll
   hand to the performance sub-team.
4. Try a small design-of-experiments (DOE) style sweep — vary front AoA,
   rear AoA, and/or section choice systematically rather than one at a
   time — to map out the achievable Cl/Cd/aero-balance space more
   efficiently than a manual search.

## A few things to expect

- **XFoil sometimes won't converge**, especially at negative AoA on a
  cambered section, or near stall. `api.naca4Aero`/`api.genCarAeroData`
  return `NaN` when this happens rather than erroring — treat `NaN` as
  "not achievable," not as a bug. Sweeping many AoA values in one go and
  filtering out `NaN` afterward is easier than chasing every failure
  individually.
- **More downforce always costs more drag** — partly the section's own
  Cd rising with AoA, partly *induced* drag (a real, finite wing pays a
  drag cost for the lift it generates, roughly proportional to Cl²).
  There's no way to raise Cl for free; the question is how steep that
  trade-off is for a given section, which is exactly what your
  sensitivity study should reveal.
- **Front and rear AoA together set aero balance**, not just total
  downforce — the performance sub-team needs both the achievable
  Cl/Cd range *and* how balance moves within it, not just a single
  best point.
