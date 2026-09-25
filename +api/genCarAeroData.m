function [CL,CD,aeroBalance] = genCarAeroData(frontSection,frontAoA,rearSection,rearAoA,options)
% genCarAeroData - combine independently-chosen front and rear wing
% sections/angles-of-attack into a whole-car CL, CD and aero balance,
% ready to pass straight into Vehicle.withAero('Cl',CL,'Cd',CD,'da',aeroBalance),
% api.simulate_race(RaceName,CL,CD,aeroBalance,...) or
% api.runSeason2025(CL,CD,aeroBalance,...) with no further conversion.
%
% [CL,CD,aeroBalance] = api.genCarAeroData(frontSection,frontAoA,rearSection,rearAoA)
% [CL,CD,aeroBalance] = api.genCarAeroData("0012",-4,"2334",-2)
% [CL,CD,aeroBalance] = api.genCarAeroData("0012",-4,"2334",-2,'frontSpan_m',1.6,'CD_body',0.7)
%
%   frontSection, rearSection   NACA 4-digit code, as a 4-character
%                                string, e.g. "2412" (camber 2%, camber
%                                position 40%chord, thickness 12%chord)
%   frontAoA, rearAoA           angle of attack for that wing [deg],
%                                NEGATIVE for a downforce-generating
%                                incidence -- both wings are passed
%                                straight through to api.naca4Aero
%                                (InvertWing=true by default there), so
%                                this is exactly api.naca4Aero's own
%                                convention, with no extra sign flip
%                                applied here.
%
% options (all optional):
%   .frontChord_m, .frontSpan_m   front wing chord and span [m], default
%                                 0.3 and 1.8 (rough order-of-magnitude
%                                 figures, not measured from a real car).
%                                 frontChord_m also sets the Reynolds
%                                 number used for the XFoil solve, so
%                                 don't set chord and span independently
%                                 of each other without also checking Re.
%   .rearChord_m, .rearSpan_m     same, for the rear wing, default 0.3
%                                 and 1.0 (rear wing span is regulated
%                                 much tighter than front).
%   .oswaldEfficiency    finite-wing (Oswald) efficiency factor, default
%                         0.8 -- a generic "reasonably good" placeholder.
%   .CL_body, .CD_body   fixed lift/drag coefficients for everything on
%                         the car that ISN'T the two wings (floor,
%                         diffuser, bodywork, exposed wheels, cooling).
%                         Default CL_body=-3 (downforce, same convention
%                         as the wings -- see Returns), CD_body=1 (drag).
%                         A simple fixed baseline the wings build on top
%                         of; both are referenced to carFrontalArea_m2
%                         like everything else in this function, not
%                         standalone real-car figures. NOT MODELLED: a
%                         real floor's downforce is speed- and
%                         ride-height-dependent, which this constant
%                         coefficient doesn't capture.
%   .bodyAeroBalance     front fraction of CL_body specifically (0-1),
%                         default 0.5 -- a placeholder split, since the
%                         floor/bodywork's downforce isn't generated at a
%                         single point the way a wing's is.
%   .carFrontalArea_m2   reference area whole-car CL/CD are expressed
%                         against, default 1.0 -- matches Vehicle.A on
%                         this project's baseline vehicle
%                         (data/cars/Formula_1_car.mat); set this to
%                         match whatever vehicle you're feeding the
%                         result into if it differs.
%
% Returns:
%   CL, CD         whole-car lift/drag coefficients: CL is NEGATIVE for
%                  downforce, CD is POSITIVE (a drag magnitude). This is
%                  Vehicle.Cl/Cd's own convention (e.g. the baseline
%                  vehicle is Cl=-4.8, Cd=1.2) and also
%                  api.simulate_race/api.runSeason2025's (both pass
%                  Cl/Cd straight through to Vehicle.withAero), so this
%                  function's output drops straight into any of the
%                  three with no conversion needed.
%                  Both wings are analysed via api.naca4Aero (its
%                  InvertWing default models each mounted upside down to
%                  generate downforce), which returns an already-negative
%                  Cl for a negative input AoA -- this function does not
%                  negate anything itself, it only combines
%                  already-correctly-signed quantities.
%   aeroBalance    front fraction of total downforce [-] (0-1), matching
%                  Vehicle.da's own convention (factor_aero = da for FWD,
%                  1-da for RWD). A ratio of two same-signed quantities,
%                  so unaffected by the sign convention above.
%
% CD_body and induced drag: a raw 2D XFoil section Cd is only profile
% drag on an isolated, infinite-span wing, which stays low (~0.01-0.03)
% right up to stall -- it cannot show why real wings can't just run
% maximum incidence. A real, finite-span wing also pays INDUCED drag for
% the lift it generates (wingtip vortices), roughly Cl^2/(pi*e*AR), which
% is added here so "more downforce costs more drag, faster than
% linearly" actually shows up. CD_body separately covers everything on
% the car that isn't the wings.
%
% Reference-area conversion: a wing's force scales with ITS OWN planform
% area (chord*span), not the car's frontal area, so each wing's 2D
% section coefficient is converted to a car-level contribution via
% (wing area)/(carFrontalArea_m2) before combining -- this also means the
% front and rear wings need not be the same size:
%   CL_front_car = Cl_front*(frontChord_m*frontSpan_m)/carFrontalArea_m2   (already negative)
%   CL_rear_car  = Cl_rear *(rearChord_m *rearSpan_m )/carFrontalArea_m2   (already negative)
%   CD_front_car = (Cd_front+CDi_front)*(frontChord_m*frontSpan_m)/carFrontalArea_m2
%   CD_rear_car  = (Cd_rear +CDi_rear )*(rearChord_m *rearSpan_m )/carFrontalArea_m2
%   CL_body_front = CL_body*bodyAeroBalance ; CL_body_rear = CL_body*(1-bodyAeroBalance)
%   CL = CL_body_front + CL_body_rear + CL_front_car + CL_rear_car
%   CD = CD_body + CD_front_car + CD_rear_car
%   aeroBalance = (CL_body_front+CL_front_car) / CL
% NOT MODELLED: the finite-wing lift-side correction (induced AoA
% slightly reduces effective lift slope vs. the 2D section) -- only the
% drag-side correction is applied here.
%
% Each wing's 2D XFoil section polar is run viscous via api.naca4Aero
% (and open.xfoil underneath) -- see those for Re/Mach defaults and
% convergence behaviour. A wing whose chosen AoA fails to converge comes
% back as NaN from api.naca4Aero and propagates through to CL, CD and
% aeroBalance here without erroring, so a sweep over many
% (frontAoA,rearAoA) combinations can just check for NaN afterward.
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

    % naca4Aero's InvertWing default (true) models each wing mounted
    % upside down to generate downforce -- frontAoA/rearAoA are passed
    % straight through (negative = downforce), so ClF/ClR come back
    % already negative with no sign flip needed here.
    [ClF,CdF] = api.naca4Aero(frontSection,frontAoA,'chord_m',options.frontChord_m) ;
    [ClR,CdR] = api.naca4Aero(rearSection,rearAoA,'chord_m',options.rearChord_m) ;

    % Induced drag: the drag a finite wing pays for the lift it
    % generates. Cl is squared so its sign doesn't matter here.
    CDi_front = ClF.^2/(pi*options.oswaldEfficiency*frontAR) ;
    CDi_rear = ClR.^2/(pi*options.oswaldEfficiency*rearAR) ;

    CD_front_2D = CdF+CDi_front ;
    CD_rear_2D = CdR+CDi_rear ;

    % Reference-area conversion: scale each wing's 2D coefficient by its
    % own planform area relative to the car's frontal area.
    CL_front_car = ClF*S_front/options.carFrontalArea_m2 ; % already negative
    CL_rear_car = ClR*S_rear/options.carFrontalArea_m2 ; % already negative
    CD_front_car = CD_front_2D*S_front/options.carFrontalArea_m2 ;
    CD_rear_car = CD_rear_2D*S_rear/options.carFrontalArea_m2 ;

    % Fixed floor/bodywork baseline, independent of wing choice.
    CL_body_front = options.CL_body*options.bodyAeroBalance ; % already negative
    CL_body_rear = options.CL_body*(1-options.bodyAeroBalance) ;

    aeroBalance = (CL_body_front+CL_front_car)/(CL_body_front+CL_body_rear+CL_front_car+CL_rear_car) ;

    % Every term above is already correctly signed, so this is a
    % straight sum with no final sign flip.
    CL = CL_body_front+CL_body_rear+CL_front_car+CL_rear_car ;
    CD = options.CD_body+CD_front_car+CD_rear_car ;
end
