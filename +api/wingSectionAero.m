function [ClF,CdF,ClR,CdR] = wingSectionAero(frontSection,frontAoA,rearSection,rearAoA,p)
% wingSectionAero - 2D section cl/cd for front and rear wings via XFoil.
%
%   [ClF,CdF,ClR,CdR] = api.wingSectionAero("2412",-4,"4515",-8)
%   [ClF,CdF,ClR,CdR] = api.wingSectionAero(..., p)     % p = api.CarAeroParams
%
% AoA negative = downforce (api.naca4Aero InvertWing default), so Cl comes
% back negative. Chord from p sets the Reynolds number. A non-converged
% AoA returns NaN.
arguments
    frontSection (1,1) string
    frontAoA (1,1) double
    rearSection (1,1) string
    rearAoA (1,1) double
    p (1,1) api.CarAeroParams = api.CarAeroParams()
end
[ClF,CdF] = api.naca4Aero(frontSection,frontAoA,'chord_m',p.frontChord_m) ;
[ClR,CdR] = api.naca4Aero(rearSection, rearAoA, 'chord_m',p.rearChord_m) ;
end