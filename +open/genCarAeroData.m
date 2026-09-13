function [CL,CD,aeroBalance] = genCarAeroData(frontSection,frontAoA,rearSection,rearAoA,options)
% genCarAeroData - combine independently-chosen front and rear wing
% sections/angles-of-attack into a whole-car CL, CD and aero balance,
% referenced and signed so the result drops STRAIGHT into
% Vehicle.withAero('Cl',CL,'Cd',CD,'da',aeroBalance),
% api.simulate_race(RaceName,CL,CD,aeroBalance,...) or
% api.runSeason2025(CL,CD,aeroBalance,...) with no further conversion --
% all three now use the SAME convention (see "Returns" below).
%
% [CL,CD,aeroBalance] = open.genCarAeroData(frontSection,frontAoA,rearSection,rearAoA)
% [CL,CD,aeroBalance] = open.genCarAeroData("0012",4,"2334",2)
% [CL,CD,aeroBalance] = open.genCarAeroData("0012",4,"2334",2,'frontSpan_m',1.6,'CD_body',0.7)
%
%   frontSection, rearSection   NACA 4-digit code, as a 4-character
%                                string, e.g. "2412" (camber 2%, camber
%                                position 40%chord, thickness 12%chord)
%   frontAoA, rearAoA           angle of attack for that wing [deg],
%                                POSITIVE for a downforce-generating
%                                incidence (both wings are run through
%                                open.naca4Aero with InvertWing=true --
%                                see there for what that means physically)
%
% options (all optional):
%   .frontChord_m, .frontSpan_m   front wing chord and span [m], default
%                                 0.3 and 1.8 -- rough orders of magnitude
%                                 for a modern F1 front wing (wide span,
%                                 modest chord), NOT measured from a real
%                                 car. frontChord_m is also forwarded to
%                                 open.naca4Aero as its chord_m, so the
%                                 Reynolds number used for the XFoil
%                                 solve stays consistent with the same
%                                 chord used for the area conversion below
%                                 -- don't set them independently.
%   .rearChord_m, .rearSpan_m     same, for the rear wing, default 0.3
%                                 and 1.0 (regulations cap rear wing span
%                                 much tighter than front).
%   .oswaldEfficiency    finite-wing (Oswald) efficiency factor, default
%                         0.8 -- a generic "reasonably good, no special
%                         end-plate treatment" value; real wings with
%                         well-designed end plates or ground effect can
%                         do better, but this is a placeholder either way.
%   .CL_body, .CD_body   fixed lift/drag coefficients for everything on
%                         the car that ISN'T the two wings -- floor,
%                         diffuser and bodywork for CL_body; body, the
%                         exposed wheels on an open-wheel car, radiators/
%                         cooling and suspension/interference for CD_body.
%                         Default CL_body=-3 (downforce, negative -- same
%                         convention as the wings, see Returns below),
%                         CD_body=1 (drag, positive): a deliberately
%                         simple, ROUND-NUMBER baseline the wings then
%                         build on top of for this exercise -- not a claim
%                         about any specific real car (a current-generation
%                         F1 floor alone typically generates considerably
%                         more of the car's total downforce than its wings
%                         do, but this project's 2D-section wing model
%                         can't reach anywhere near that scale regardless
%                         -- see NOT MODELLED below). Both are added once
%                         to the whole car, independent of wing choice,
%                         ALREADY referenced to carFrontalArea_m2 (i.e.
%                         treat them as "using the SAME frontal area as
%                         the rest of this function", not standalone
%                         real-car figures).
%   .bodyAeroBalance     front fraction of CL_body specifically (0-1),
%                         default 0.5 -- the floor/bodywork's downforce
%                         isn't generated at a single point the way a
%                         wing's is, so this is just a placeholder split;
%                         override it if you want the body to be
%                         front- or rear-biased.
%   .carFrontalArea_m2   reference area whole-car CL/CD are expressed
%                         against, default 1.0 -- matches Vehicle.A on
%                         this project's own baseline "Formula 1.xlsx"
%                         vehicle (data/cars/Formula_1_car.mat); set this
%                         to match whatever vehicle you're actually
%                         feeding the result into if it differs.
%
% Returns:
%   CL, CD         whole-car lift/drag coefficients: CL is NEGATIVE for
%                  downforce, CD is POSITIVE (a drag magnitude -- drag
%                  has no sign, it always opposes motion). This is
%                  Vehicle.Cl/Cd's OWN convention exactly (e.g. the
%                  baseline vehicle is Cl=-4.8, Cd=1.2) and also
%                  api.simulate_race/api.runSeason2025's (both pass Cl/Cd
%                  straight through to Vehicle.withAero, no sign flip
%                  anywhere) -- so this function's output drops straight
%                  into any of the three with no conversion needed, and
%                  none of them require you to remember a sign convention
%                  that's different from ordinary aerodynamics.
%                  MECHANISM: both wings are analysed via open.naca4Aero
%                  with InvertWing=true, which runs XFoil at the MIRRORED
%                  angle on the unchanged section geometry and negates
%                  the resulting Cl -- the physically correct way to
%                  model a wing mounted upside down to generate downforce
%                  (see open.naca4Aero's own InvertWing doc for why this
%                  is more than a cosmetic sign flip: it also picks the
%                  correct, mirrored stall boundary for a cambered
%                  section). That means ClF/ClR here are ALREADY negative
%                  coming out of naca4Aero -- this function does not
%                  negate anything itself, it just combines already-
%                  correctly-signed quantities.
%   aeroBalance    front fraction of total downforce [-] (0-1) -- this is
%                  exactly Vehicle.da's own convention (see
%                  computeForceModel.m: factor_aero = da for FWD,
%                  1-da for RWD). Sign-independent (a ratio of two
%                  same-signed quantities), so unaffected by any of the
%                  above.
%
% WHY CD_body AND INDUCED DRAG WERE ADDED: without them, CD here was just
% the two wings' raw 2D XFoil section Cd -- profile (skin friction +
% pressure) drag on an ISOLATED, INFINITE-SPAN aerofoil, which stays low
% (order 0.01-0.03) right up until stall. That structurally cannot
% reproduce why real wings can't just run maximum incidence: a real,
% finite-span wing pays INDUCED drag for the lift it generates (from
% wingtip vortices), roughly Cl^2/(pi*e*AR) -- usually the dominant drag
% cost of a high-downforce wing, and completely absent from a 2D section
% analysis (which assumes infinite span, i.e. no wingtips at all). Adding
% it here is what makes "more downforce costs more drag, faster than
% linearly" show up at all. CD_body is separate: it's everything ON THE
% CAR that isn't the wings, which a wing-only analysis never included in
% the first place regardless of span.
%
% WHY THE REFERENCE-AREA CONVERSION WAS ADDED: a wing's actual force
% scales with ITS OWN planform area (chord*span), not the car's frontal
% area -- a bigger wing at the same 2D section Cl simply produces more
% downforce. Converting each wing's 2D-section coefficient to a car-level
% contribution via (wing area)/(carFrontalArea_m2) before combining is
% what makes that show up, and (as a side effect) means the front and
% rear wings no longer have to be assumed equal-sized: CL and CD are now
% SUMS of each wing's own car-level contribution (plus the body baseline),
% not an average of two same-weighted 2D coefficients:
%   CL_front_car = Cl_front*(frontChord_m*frontSpan_m)/carFrontalArea_m2   (already negative -- see Returns)
%   CL_rear_car  = Cl_rear *(rearChord_m *rearSpan_m )/carFrontalArea_m2   (already negative)
%   CD_front_car = (Cd_front+CDi_front)*(frontChord_m*frontSpan_m)/carFrontalArea_m2
%   CD_rear_car  = (Cd_rear +CDi_rear )*(rearChord_m *rearSpan_m )/carFrontalArea_m2
%   CL_body_front = CL_body*bodyAeroBalance ; CL_body_rear = CL_body*(1-bodyAeroBalance)
%   CL = CL_body_front + CL_body_rear + CL_front_car + CL_rear_car   (straight sum -- everything going in is already correctly signed)
%   CD = CD_body + CD_front_car + CD_rear_car
%   aeroBalance = (CL_body_front+CL_front_car) / (CL_body_front+CL_body_rear+CL_front_car+CL_rear_car)
% NOT MODELLED: the induced AoA a finite wing sees also slightly reduces
% its effective lift slope relative to the 2D section (the classic
% finite-wing lift correction) -- CL_wing here is approximated as equal
% to the 2D section Cl, i.e. only the DRAG side of the finite-wing
% correction is applied. Good enough to get the right ORDER of magnitude
% and the right shape of trade-off; if you need the lift-side correction
% too, this is the function to extend next. Also not modelled: a real
% floor's downforce (and a real wing's, for that matter) is speed- and
% ride-height-dependent in ways this constant-coefficient CL_body doesn't
% capture -- it's a fixed baseline the wings build on top of, by design,
% for this exercise.
%
% Each wing's 2D XFoil section polar is run viscous via open.naca4Aero
% (and open.xfoil underneath) -- see those for Re/Mach defaults and
% convergence behaviour. A wing whose chosen AoA fails to converge comes
% back as NaN from open.naca4Aero (with its own warning already naming
% the section/AoA/Re/Mach) and simply propagates through to CL, CD and
% aeroBalance here -- this function does not additionally error, so a
% sweep over many (frontAoA,rearAoA) combinations can just check for NaN
% afterward rather than needing a try/catch around every call.
    arguments
        frontSection (1,1) string
        frontAoA (1,1) double
        rearSection (1,1) string
        rearAoA (1,1) double
        options.frontChord_m (1,1) double {mustBePositive} = 0.3
        options.frontSpan_m (1,1) double {mustBePositive} = 1.8
        options.rearChord_m (1,1) double {mustBePositive} = 0.3
        options.rearSpan_m (1,1) double {mustBePositive} = 1.0
        options.oswaldEfficiency (1,1) double {mustBePositive} = 0.8
        options.CL_body (1,1) double {mustBeNonpositive} = -3
        options.CD_body (1,1) double {mustBeNonnegative} = 1
        options.bodyAeroBalance (1,1) double {mustBeInRange(options.bodyAeroBalance,0,1)} = 0.5
        options.carFrontalArea_m2 (1,1) double {mustBePositive} = 1.0
    end

    frontAR = options.frontSpan_m/options.frontChord_m ;
    rearAR = options.rearSpan_m/options.rearChord_m ;
    S_front = options.frontChord_m*options.frontSpan_m ;
    S_rear = options.rearChord_m*options.rearSpan_m ;

    % InvertWing=true: models each wing mounted upside down to generate
    % downforce -- ClF/ClR come back ALREADY NEGATIVE (see open.naca4Aero's
    % own InvertWing doc for the physics of why this is more than a sign
    % flip). Cd is unaffected by InvertWing (drag doesn't care which way
    % up the wing is). Note the '-' on frontAoA/rearAoA here: naca4Aero's
    % own InvertWing convention takes a NEGATIVE input AoA to mean
    % "downforce incidence" (it's the angle actually mirrored before
    % solving) -- this function's frontAoA/rearAoA are kept POSITIVE for
    % downforce instead, since that's the more natural, intuitive
    % direction for a caller who isn't thinking about the mirroring
    % mechanics underneath, so the negation happens here rather than
    % pushing that convention difference onto every caller.
    [ClF,CdF] = open.naca4Aero(frontSection,-frontAoA,'chord_m',options.frontChord_m,'InvertWing',true) ;
    [ClR,CdR] = open.naca4Aero(rearSection,-rearAoA,'chord_m',options.rearChord_m,'InvertWing',true) ;

    % induced drag: the drag a FINITE wing pays for the lift it generates
    % (wingtip vortices), which a 2D section polar cannot capture at all.
    % Cl is squared, so its (now negative) sign doesn't matter here. NaN
    % (non-convergent) Cl propagates naturally through this simple
    % arithmetic -- no special-casing needed.
    CDi_front = ClF.^2/(pi*options.oswaldEfficiency*frontAR) ;
    CDi_rear = ClR.^2/(pi*options.oswaldEfficiency*rearAR) ;

    CD_front_2D = CdF+CDi_front ;
    CD_rear_2D = CdR+CDi_rear ;

    % reference-area conversion: each wing's force scales with ITS OWN
    % planform area, not the car's frontal area -- convert to a car-level
    % contribution before combining, so a bigger wing correctly counts
    % for more than a smaller one at the same 2D section coefficient.
    CL_front_car = ClF*S_front/options.carFrontalArea_m2 ; % already negative (ClF is)
    CL_rear_car = ClR*S_rear/options.carFrontalArea_m2 ; % already negative
    CD_front_car = CD_front_2D*S_front/options.carFrontalArea_m2 ;
    CD_rear_car = CD_rear_2D*S_rear/options.carFrontalArea_m2 ;

    % fixed floor/bodywork baseline, independent of wing choice -- the
    % wings then build on top of this (see options.CL_body/.CD_body above)
    CL_body_front = options.CL_body*options.bodyAeroBalance ; % already negative (CL_body is)
    CL_body_rear = options.CL_body*(1-options.bodyAeroBalance) ;

    aeroBalance = (CL_body_front+CL_front_car)/(CL_body_front+CL_body_rear+CL_front_car+CL_rear_car) ;

    % straight sums: every term above is already correctly signed
    % (negative for downforce, positive for drag), so no final sign flip
    % is needed here -- see "Returns" above.
    CL = CL_body_front+CL_body_rear+CL_front_car+CL_rear_car ;
    CD = options.CD_body+CD_front_car+CD_rear_car ;
end
