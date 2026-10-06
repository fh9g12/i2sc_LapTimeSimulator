function [CL,CD,aeroBalance,parts] = carAeroFromSections(ClF,CdF,ClR,CdR,p)
% carAeroFromSections - whole-car CL, CD and aero balance from 2D wing
% section coefficients. Element-wise: inputs may be scalars or equal-size
% arrays (for sweeps). No XFoil calls.
%
%   [CL,CD,AB] = api.carAeroFromSections(ClF,CdF,ClR,CdR)
%   [CL,CD,AB,parts] = api.carAeroFromSections(..., p)   % p = api.CarAeroParams
%
% Model (A = carFrontalArea_m2, S = chord*span, AR = span/chord):
%   CDi_wing     = Cl^2 / (pi*e*AR)                 induced drag (2D-referenced)
%   CL_wing_car  = Cl * S/A
%   CD_wing_car  = (Cd + CDi) * S/A
%   CL = CL_body + CL_front_car + CL_rear_car
%   CD = CD_body + CD_front_car + CD_rear_car
%   AB = (CL_body*bodyAeroBalance + CL_front_car) / CL
% Equivalent span form of induced drag: CDi_car = CL_wing_car^2*A/(pi*e*span^2).
% NaN inputs propagate. NOT MODELLED: finite-wing lift-slope reduction.
arguments
    ClF double
    CdF double
    ClR double
    CdR double
    p (1,1) api.CarAeroParams = api.CarAeroParams()
end
A  = p.carFrontalArea_m2 ;
e  = p.oswaldEfficiency ;

CDiF = ClF.^2 ./ (pi*e*p.AR_front) ;
CDiR = ClR.^2 ./ (pi*e*p.AR_rear) ;

CLf = ClF .* (p.S_front/A) ;
CLr = ClR .* (p.S_rear /A) ;
CDf = (CdF + CDiF) .* (p.S_front/A) ;
CDr = (CdR + CDiR) .* (p.S_rear /A) ;

CLbF = p.CL_body*p.bodyAeroBalance ;
CLbR = p.CL_body*(1 - p.bodyAeroBalance) ;

CL = CLbF + CLbR + CLf + CLr ;
CD = p.CD_body + CDf + CDr ;
aeroBalance = (CLbF + CLf) ./ CL ;

if nargout > 3
    parts = struct('CL_front_car',CLf,'CL_rear_car',CLr, ...
        'CD_front_car',CDf,'CD_rear_car',CDr, ...
        'CDi_front_car',CDiF.*(p.S_front/A), ...
        'CDi_rear_car', CDiR.*(p.S_rear /A)) ;
end
end