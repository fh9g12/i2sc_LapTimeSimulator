function ClF = frontClForBalance(ClR,aeroBalance,p)
% frontClForBalance - front section cl giving a target aero balance for a
% given rear section cl (exact inverse of the balance equation). Element-wise.
%
%   ClF = api.frontClForBalance(ClR, 0.4295)
%
%   AB = (b*CLb + ClF*Sf/A) / (CLb + ClF*Sf/A + ClR*Sr/A)
%   => ClF = (AB*(CLb + ClR*Sr/A) - b*CLb) * A / (Sf*(1-AB))
arguments
    ClR double
    aeroBalance double {mustBeInRange(aeroBalance,0,1,'exclude-upper')}
    p (1,1) api.CarAeroParams = api.CarAeroParams()
end
A = p.carFrontalArea_m2 ;
ClF = (aeroBalance.*(p.CL_body + ClR*p.S_rear/A) - p.bodyAeroBalance*p.CL_body) ...
    .* A ./ (p.S_front*(1 - aeroBalance)) ;
end