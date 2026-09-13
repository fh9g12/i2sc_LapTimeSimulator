function fig = plotNACA(section,options)
% plotNACA - plots a NACA 4-series aerofoil's shape (upper/lower surface
% and camber line), using the same 4-digit code convention as
% api/open.naca4Aero and open.xfoil.
%
% fig = api.plotNACA(section)
% fig = api.plotNACA('0012')
% fig = api.plotNACA('2412')
%
%   section   NACA 4-digit code, as a 4-character string, e.g. '2412'
%             (camber 2%, camber position 40%chord, thickness 12%chord)
%
% This is PURE GEOMETRY, computed directly from the standard NACA 4-digit
% thickness/camber-line equations -- it does NOT run XFoil at all, so
% it's instant and has no convergence to worry about (unlike
% api.naca4Aero/api.genAeroPolar, which need a real viscous solve). Use
% this to see what a chosen section actually looks like before spending
% time running an aero polar on it.
%
% options:
%   .nPoints   points per surface (default 100), cosine-spaced (denser
%              near the leading and trailing edges, where curvature is
%              highest) -- standard practice for aerofoil coordinate
%              generation.
%
% Returns the figure handle; call savefig(fig,path) yourself if you want
% to keep it.
    arguments
        section
        options.nPoints (1,1) double {mustBeInteger,mustBeGreaterThanOrEqual(options.nPoints,10)} = 100
    end

    [camber,camberPos,thickness] = parseNaca4Code(section) ;
    m = camber/100 ;    % max camber, fraction of chord
    p = camberPos/10 ;  % camber position, fraction of chord
    t = thickness/100 ; % max thickness, fraction of chord

    % cosine spacing from leading (x=0) to trailing (x=1) edge
    beta = linspace(0,pi,options.nPoints) ;
    x = (1-cos(beta))/2 ;

    % symmetric thickness distribution (the standard NACA4 formula, with
    % the -0.1015 coefficient that gives a small non-zero trailing-edge
    % thickness -- the same convention XFoil's own NACA generator uses)
    yt = 5*t*(0.2969*sqrt(x)-0.1260*x-0.3516*x.^2+0.2843*x.^3-0.1015*x.^4) ;

    hasCamber = m>0 && p>0 ;
    if hasCamber
        yc = zeros(size(x)) ;
        dycdx = zeros(size(x)) ;
        front = x<p ;
        yc(front) = m/p^2*(2*p*x(front)-x(front).^2) ;
        dycdx(front) = 2*m/p^2*(p-x(front)) ;
        back = ~front ;
        yc(back) = m/(1-p)^2*((1-2*p)+2*p*x(back)-x(back).^2) ;
        dycdx(back) = 2*m/(1-p)^2*(p-x(back)) ;
        theta = atan(dycdx) ;
    else
        yc = zeros(size(x)) ;
        theta = zeros(size(x)) ;
    end

    % offset the symmetric thickness distribution perpendicular to the
    % camber line (reduces to +-yt directly above/below x for a symmetric
    % section, where theta=0)
    xu = x-yt.*sin(theta) ;
    yu = yc+yt.*cos(theta) ;
    xl = x+yt.*sin(theta) ;
    yl = yc-yt.*cos(theta) ;

    fig = figure('Name',sprintf('NACA %s',char(section))) ;
    hold on
    plot(xu,yu,'b-','LineWidth',1.5)
    plot(xl,yl,'b-','LineWidth',1.5)
    if hasCamber
        plot(x,yc,'r--')
        legend({'Upper surface','Lower surface','Camber line'},'Location','best')
    else
        legend({'Upper surface','Lower surface'},'Location','best')
    end
    axis equal
    grid on
    xlabel('x/c')
    ylabel('y/c')
    title(sprintf('NACA %s  (camber %d%%c @ %d0%%c, thickness %d%%c)',char(section),camber,camberPos,thickness),'Interpreter','none')
end

function [camber,camberPos,thickness] = parseNaca4Code(code)
    % mirrors naca4Aero.m's own parser, kept local here to keep this
    % pure-geometry function independent of the XFoil-calling one
    code = char(code) ;
    if numel(code)~=4 || ~all(isstrprop(code,'digit'))
        error('plotNACA:badCode', ...
            'NACA 4-digit code must be exactly 4 numeric characters, e.g. "2412" (got "%s").',code) ;
    end
    camber = str2double(code(1)) ;
    camberPos = str2double(code(2)) ;
    thickness = str2double(code(3:4)) ;
end
