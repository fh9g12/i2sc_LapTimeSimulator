function [ClF,ClR] = wingClsForTarget(CL,aeroBalance,p)
% wingClsForTarget - front and rear section cl needed to reach a target
% whole-car CL and aero balance. Element-wise.
%
%   [ClF,ClR] = api.wingClsForTarget(-3.6, 0.4295)
%
% With dCL = CL - CL_body and delta = (AB - b)*CL_body:
%   CL_front_car = AB*dCL + delta
%   CL_rear_car  = (1-AB)*dCL - delta
%   Cl_wing      = CL_wing_car * A / S
arguments
    CL double
    aeroBalance double {mustBeInRange(aeroBalance,0,1)}
    p (1,1) api.CarAeroParams = api.CarAeroParams()
end
A     = p.carFrontalArea_m2 ;
dCL   = CL - p.CL_body ;
delta = (aeroBalance - p.bodyAeroBalance)*p.CL_body ;
ClF = (aeroBalance.*dCL + delta)     * A / p.S_front ;
ClR = ((1-aeroBalance).*dCL - delta) * A / p.S_rear ;
end