function [alpha,Cl,Cd] = genAeroPolar(section,options)
% genAeroPolar - full Cl/Cd vs AoA polar for a NACA 4-series section,
% from -range to +range degrees, plotted as a 3-subplot figure.
%
% [alpha,Cl,Cd] = api.genAeroPolar(section)
% [alpha,Cl,Cd] = api.genAeroPolar(section,options)
% [alpha,Cl,Cd] = api.genAeroPolar('0012')
%
%   section   NACA 4-digit code, as a 4-character string, e.g. '0012'
%
% Runs TWO separate api.naca4Aero sweeps -- 0:step:range and
% 0:-step:-range -- each starting from AoA=0 and stepping outward, rather
% than one sweep straight across the whole range. XFoil uses the
% previous angle's converged solution as the initial guess for the next
% one, so stepping outward in both directions from a well-behaved
% starting point (0 deg, generally easy for XFoil regardless of camber)
% gives every step a much better initial guess than a single monotonic
% sweep from -range to +range would. The two sweeps are then spliced
% into one continuous ascending alpha array (the AoA=0 point, common to
% both, is only kept once).
%
% Returns alpha, Cl, Cd as equal-length row vectors from -range to
% +range. Any AoA XFoil fails to converge for comes back as NaN (with
% api.naca4Aero's own warning), consistent with the rest of this
% toolset -- the plotted lines will simply show a gap there.
%
% With the default InvertWing=true (matching api.naca4Aero's own
% default), negative alpha is a downforce-generating incidence, so the
% left half of this polar (alpha<0) is the one relevant to picking a
% downforce wing.
%
% options:
%   .range        sweep out to +-range degrees (default 12)
%   .step         AoA increment [deg] (default 1)
%   .InvertWing   forwarded to api.naca4Aero, default true (see above)
%   .chord_m, .speed_mph, .Re, .Mach, .iterCap  forwarded to
%            api.naca4Aero unchanged -- see there for defaults/meaning
    arguments
        section
        options.range (1,1) double {mustBePositive} = 16
        options.step (1,1) double {mustBePositive} = 1
        options.InvertWing (1,1) logical = true
        options.chord_m (1,1) double {mustBePositive} = 0.5
        options.speed_mph (1,1) double {mustBePositive} = 100
        options.Re double {mustBePositive} = []
        options.Mach double {mustBeNonnegative} = []
        options.iterCap (1,1) double {mustBePositive,mustBeInteger} = 500
    end

    naca4AeroArgs = {'chord_m',options.chord_m, 'speed_mph',options.speed_mph, ...
        'Re',options.Re, 'Mach',options.Mach, 'iterCap',options.iterCap, 'InvertWing',options.InvertWing} ;

    alphaPos = 0:options.step:options.range ;
    alphaNeg = 0:-options.step:-options.range ;

    [ClPos,CdPos] = api.naca4Aero(section,alphaPos,naca4AeroArgs{:}) ;
    [ClNeg,CdNeg] = api.naca4Aero(section,alphaNeg,naca4AeroArgs{:}) ;

    % Splice: negative sweep reversed into ascending order, with its own
    % AoA=0 point dropped (the positive sweep's AoA=0 point is kept).
    alpha = [fliplr(alphaNeg(2:end)), alphaPos] ;
    Cl    = [fliplr(ClNeg(2:end)),    ClPos] ;
    Cd    = [fliplr(CdNeg(2:end)),    CdPos] ;
    idx = ~isnan(Cl);
    alpha = alpha(idx);
    Cl = Cl(idx);
    Cd = Cd(idx);

    figure ;
    subplot(3,1,1) ;
    plot(alpha,Cl,'-o') ;
    xlabel('AoA [deg]') ; ylabel('Cl') ; grid on ;
    title(sprintf('NACA%s%s',char(section),repmat(' (inverted)',1,options.InvertWing))) ;

    subplot(3,1,2) ;
    plot(alpha,Cd,'-o') ;
    xlabel('AoA [deg]') ; ylabel('Cd') ; grid on ;

    subplot(3,1,3) ;
    plot(Cd,Cl,'-o') ;
    xlabel('Cd') ; ylabel('Cl') ; grid on ;
    title('Drag polar') ;
end
