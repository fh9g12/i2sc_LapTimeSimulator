function [Cl,Cd] = naca4Aero(section,AoA,options)
% naca4Aero - viscous XFoil Cl/Cd for a NACA 4-series aerofoil section at
% one or more angles of attack.
%
% [Cl,Cd] = api.naca4Aero(section,AoA)
% [Cl,Cd] = api.naca4Aero(section,AoA,options)
% [Cl,Cd] = api.naca4Aero('0012',AoA)
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
% DEFAULT REYNOLDS NUMBER: derived from a reference chord (options.chord_m,
% default 0.5 m) and speed (options.speed_mph, default 100 mph) using
% sea-level ISA air properties. Override options.Re directly to bypass
% this derivation.
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
%   .hangIfNoConverge   TEACHING AID, default false. If true and any
%                requested AoA fails to converge, this call re-runs just
%                that operating point through open.xfoil with a hugely
%                raised iterCap (options.hangIterCap) instead of
%                returning NaN -- useful for demonstrating live, on
%                screen, what a genuinely non-convergent XFoil solve
%                looks like (it will run for a very long time; press
%                Ctrl+C to stop). Normal use should leave this false.
%   .hangIterCap  iteration cap used for the hangIfNoConverge re-run
%                (default 1e6, see above)
%   .InvertWing  models the section MOUNTED UPSIDE DOWN to generate
%                downforce instead of lift, default TRUE -- this project
%                is about downforce wings, so this is the convention
%                everything (api.genCarAeroData, api.plotNACA, the
%                example scripts) is built around; set it to false only
%                if you deliberately want a normal, lift-generating wing.
%                A NACA 4-digit code can't express negative camber
%                directly, so this is how a downforce wing is modelled:
%                inverting an aerofoil mirrors its whole flow field,
%                equivalent to negating both its camber and its angle of
%                attack together. Rather than negate camber (not
%                expressible), this negates AoA instead (runs XFoil at
%                -AoA on the unchanged geometry) and negates the reported
%                Cl to match -- this also selects the correct, mirrored
%                stall boundary for a cambered section, which a cambered
%                aerofoil's (non-symmetric) stall behaviour requires. Cd
%                is unaffected (drag doesn't care which way up the wing
%                is). With InvertWing=true (the default), AoA is the
%                wing's effective downforce-generating incidence and is
%                NEGATIVE for downforce, so
%                api.naca4Aero('2412',-10) means "10 degrees of
%                downforce-generating incidence" and returns a negative
%                Cl directly (see api.genCarAeroData, which uses exactly
%                this).
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
        options.InvertWing (1,1) logical = true
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

    % InvertWing: run XFoil at the mirrored angle on the unchanged
    % (non-inverted) geometry -- see the InvertWing option doc above.
    if options.InvertWing
        xfoilAoA = -AoA ;
    else
        xfoilAoA = AoA ;
    end
    pol = open.xfoil(code,xfoilAoA,Re,Mach,options.iterCap) ;

    % Match converged points back to the requested AoAs by value (xfoil.m
    % may return fewer rows than requested if any failed to converge),
    % filling the rest with NaN.
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
