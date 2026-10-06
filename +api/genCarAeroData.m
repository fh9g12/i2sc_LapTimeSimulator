function [CL,CD,aeroBalance,wing] = genCarAeroData(frontSection,frontAoA,rearSection,rearAoA,options)
% genCarAeroData - whole-car CL, CD and aero balance from front/rear NACA
% 4-digit sections and AoAs. Output drops straight into
% Vehicle.withAero / api.simulate_race / api.runSeason2025.
%
%   [CL,CD,AB] = api.genCarAeroData("0012",-4,"2334",-2)
%   [CL,CD,AB] = api.genCarAeroData("0012",-4,"2334",-2,'frontSpan_m',1.6,'CD_body',0.7)
%   [CL,CD,AB,wing] = ...   % wing = struct of section ClF/CdF/ClR/CdR
%
% Name-value options: any property of api.CarAeroParams (chords, spans,
% oswaldEfficiency, CL_body, CD_body, bodyAeroBalance, carFrontalArea_m2).
%
% Equivalent to:
%   p = api.CarAeroParams(...);
%   [ClF,CdF,ClR,CdR] = api.wingSectionAero(frontSection,frontAoA,rearSection,rearAoA,p);
%   [CL,CD,AB]        = api.carAeroFromSections(ClF,CdF,ClR,CdR,p);
% See those for conventions and the model equations.
arguments
    frontSection (1,1) string
    frontAoA (1,1) double
    rearSection (1,1) string
    rearAoA (1,1) double
    options.?api.CarAeroParams
end
nv = namedargs2cell(options) ;
p  = api.CarAeroParams(nv{:}) ;

[ClF,CdF,ClR,CdR] = api.wingSectionAero(frontSection,frontAoA,rearSection,rearAoA,p) ;
[CL,CD,aeroBalance] = api.carAeroFromSections(ClF,CdF,ClR,CdR,p) ;

if nargout > 3
    wing = struct('ClF',ClF,'CdF',CdF,'ClR',ClR,'CdR',CdR) ;
end
end