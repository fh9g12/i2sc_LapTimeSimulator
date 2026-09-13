function [Cl,Cd] = naca4Aero(section,AoA,options)
% naca4Aero - viscous XFoil Cl/Cd for a NACA 4-series aerofoil section at
% one or more angles of attack.
%
% [Cl,Cd] = open.naca4Aero(section,AoA)
% [Cl,Cd] = open.naca4Aero(section,AoA,options)
% [Cl,Cd] = open.naca4Aero('0012',AoA)
%
%   section   NACA 4-digit code, as a 4-character string, e.g. '2412'
%             (camber 2%, camber position 40%chord, thickness 12%chord)
%   AoA       angle(s) of attack [deg] -- scalar or vector
%
% Cl, Cd are returned the same size as AoA. An AoA XFoil fails to
% converge for comes back as NaN in both (with a warning from open.xfoil
% itself) rather than erroring the whole call -- check for NaN if you
% asked for several AoAs at once, e.g. a sweep approaching stall.
%
% DEFAULT REYNOLDS NUMBER: chosen to represent a small wing element
% (options.chord_m, default 0.5 m) at a typical car-park test speed
% (options.speed_mph, default 100 mph), using sea-level ISA air
% properties -- see the constants below. Override options.Re directly to
% bypass this derivation, e.g. for a different chord/speed combination
% than the two options below cover.
%
% options (all optional):
%   .chord_m     reference chord [m] used to derive the default Re (default 0.5)
%   .speed_mph   reference speed [mph] used to derive the default Re and
%                Mach (default 100)
%   .Re          override the derived Reynolds number directly (default
%                [] -> derive from chord_m/speed_mph)
%   .Mach        override the derived Mach number directly (default []
%                -> derive from speed_mph)
%   .iterCap     XFoil's per-operating-point Newton iteration cap
%                (default 150) -- XFoil's own default (~10) is often too
%                low to converge from a fresh viscous start at anything
%                but a small AoA; passed straight through to
%                open.xfoil's own iterCap parameter
%   .hangIfNoConverge   TEACHING AID, default false. If true and ANY
%                requested AoA fails to converge, this call never
%                returns: it RE-RUNS just that one failing operating
%                point through open.xfoil with a hugely raised iterCap
%                (options.hangIterCap), which for a genuinely
%                non-convergent/oscillating case (confirmed, not just
%                slow) keeps XFoil busy computing internally for a very
%                long time -- 1e6 iterations is ~36 minutes at the
%                ~2.2ms/iteration measured for this exact case, i.e.
%                effectively forever for a live demo. This deliberately
%                does NOT try to keep the ORIGINAL xfoil.exe process
%                alive by omitting its trailing 'quit' command -- tested
%                directly, and a piped stdin running dry crashes this
%                XFoil build immediately ('Fortran runtime error: End of
%                file'), it does not wait for more input. Re-running
%                with more iterations avoids that entirely, since XFoil
%                is never waiting on stdin -- it's just still computing.
%                Only triggers on a genuine failure (never for AoAs that
%                converge normally). Press Ctrl+C to stop; normally
%                (false) a non-convergent AoA just comes back as NaN
%                with a warning instead, the right behaviour for real
%                use. e.g. open.naca4Aero('2412',2,'hangIfNoConverge',true)
%                is a case confirmed to oscillate rather than converge
%                at the default Re.
%   .hangIterCap  iteration cap used for the hangIfNoConverge re-run
%                (default 1e6, see above)
%   .InvertWing  models the section MOUNTED UPSIDE DOWN to generate
%                downforce instead of lift, default false. A NACA 4-digit
%                code can't express negative camber directly (there's no
%                way to write "-2412"), so this is how a downforce wing
%                is actually modelled here: inverting an aerofoil mirrors
%                its whole flow field, which is equivalent to negating
%                BOTH its camber AND its angle of attack together -- so
%                rather than negate camber (not expressible), this negates
%                AoA instead (i.e. actually runs XFoil at -AoA on the
%                UNCHANGED geometry) and negates the reported Cl to match.
%                This is more than a cosmetic sign flip on the result: it
%                also picks the CORRECT (mirrored) stall boundary for a
%                cambered section, which a post-hoc "just negate whatever
%                Cl you got at +AoA" fudge would not -- a cambered
%                aerofoil's stall behaviour is NOT symmetric between its
%                two orientations. Cd is unaffected (drag doesn't care
%                which way up the wing is). With InvertWing=true, AoA is
%                the wing's effective downforce-generating incidence, so
%                open.naca4Aero('2412',10,'InvertWing',true) means "10
%                degrees of downforce-generating incidence" and returns a
%                NEGATIVE Cl directly -- no separate sign fudge needed
%                anywhere downstream (see open.genCarAeroData, which uses
%                exactly this).
    arguments
        section
        AoA (1,:) double
        options.chord_m (1,1) double {mustBePositive} = 0.5
        options.speed_mph (1,1) double {mustBePositive} = 100
        options.Re double {mustBePositive} = []
        options.Mach double {mustBeNonnegative} = []
        options.iterCap (1,1) double {mustBePositive,mustBeInteger} = 150
        options.hangIfNoConverge (1,1) logical = false
        options.hangIterCap (1,1) double {mustBePositive,mustBeInteger} = 1e6
        options.InvertWing (1,1) logical = false
    end

    [camber,camberPos,thickness] = parseNaca4Code(section) ;

    % ISA sea-level air properties
    RHO_SEA_LEVEL = 1.225 ;    % kg/m^3
    MU_AIR = 1.7894e-5 ;       % Pa.s, ~15 degC
    A_SOUND = 340.3 ;          % m/s, speed of sound at sea level
    MPH_TO_MS = 0.44704 ;

    V = options.speed_mph*MPH_TO_MS ;
    if isempty(options.Re)
        Re = RHO_SEA_LEVEL*V*options.chord_m/MU_AIR ;
    else
        Re = options.Re ;
    end
    if isempty(options.Mach)
        Mach = V/A_SOUND ;
    else
        Mach = options.Mach ;
    end

    code = sprintf('NACA%d%d%02d',camber,camberPos,thickness) ;

    % InvertWing: run XFoil at the MIRRORED angle on the unchanged
    % (non-inverted) geometry -- see the InvertWing option doc above for
    % why this, rather than just negating Cl at +AoA, is the physically
    % correct way to model a downforce-generating (upside-down) wing.
    if options.InvertWing
        xfoilAoA = -AoA ;
    else
        xfoilAoA = AoA ;
    end
    pol = open.xfoil(code,xfoilAoA,Re,Mach,options.iterCap) ;

    % Match converged points back to the requested (XFoil-space) AoAs by
    % value (xfoil.m may return fewer rows than requested if any failed
    % to converge -- not necessarily just the trailing ones), filling the
    % rest with NaN.
    Cl = nan(size(AoA)) ;
    Cd = nan(size(AoA)) ;
    for k = 1:numel(AoA)
        [d,m] = min(abs(pol.alpha-xfoilAoA(k))) ;
        if d < 1e-3
            Cl(k) = pol.CL(m) ;
            Cd(k) = pol.CD(m) ;
        end
    end

    if options.InvertWing
        Cl = -Cl ; % mirroring AoA mirrors the flow field -> negate the resulting lift; Cd is unaffected
    end

    if any(isnan(Cl))
        if options.hangIfNoConverge
            k = find(isnan(Cl),1) ;
            fprintf(['naca4Aero: %s did not converge at AoA=%g deg%s (Re=%.3g, Mach=%.3g).\n' ...
                     'hangIfNoConverge is set -- re-running JUST this operating point with ' ...
                     'iterCap=%g so XFoil genuinely keeps computing (this is a confirmed ' ...
                     'oscillation, not just slow, so it will not finish on its own in any ' ...
                     'practical time). This call will NOT return. Press Ctrl+C to stop.\n'], ...
                code, AoA(k), repmat(sprintf(' (XFoil AoA=%g, InvertWing=true)',xfoilAoA(k)),1,options.InvertWing), Re, Mach, options.hangIterCap) ;
            open.xfoil(code,xfoilAoA(k),Re,Mach,options.hangIterCap) ; %#ok<NASGU>
            return % unreachable in practice -- the line above blocks until Ctrl+C
        end
        warning('naca4Aero:noConverge', ...
            '%s: %d of %d requested AoA(s) did not converge (Re=%.3g, Mach=%.3g) -- see NaN entries.', ...
            code, nnz(isnan(Cl)), numel(AoA), Re, Mach) ;
    end
end

function [camber,camberPos,thickness] = parseNaca4Code(code)
    code = char(code) ;
    if numel(code)~=4 || ~all(isstrprop(code,'digit'))
        error('naca4Aero:badCode', ...
            'NACA 4-digit code must be exactly 4 numeric characters, e.g. "2412" (got "%s").',code) ;
    end
    camber = str2double(code(1)) ;
    camberPos = str2double(code(2)) ;
    thickness = str2double(code(3:4)) ;
end
