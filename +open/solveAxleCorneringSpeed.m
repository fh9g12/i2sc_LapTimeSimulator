function v = solveAxleCorneringSpeed(M, r, Wy, Wz, D, Fmech, Faero, Freq_frac, muy, dmy, Ny, p)
    % solveAxleCorneringSpeed - speed at which ONE axle's own grip limit
    % is reached, given:
    %   Fmech, Faero - that axle's share of mechanical weight and aero
    %                  downforce (e.g. df, da for the front axle)
    %   Freq_frac    - that axle's REQUIRED share of the total cornering
    %                  force from moment balance (df for front, 1-df for
    %                  rear -- see maxAxleLimitedLateralForce)
    %
    % Solves axleLateralForceMax(muy,dmy,Ny, Fmech*Wz+Faero*D*v^2) ==
    % Freq_frac*(M*r*v^2-Wy) for v: the same 2nd-degree-polynomial-in-v^2
    % construction (and root selection) as the original single-axle
    % OpenLAP formula, generalised to an arbitrary load/force share. With
    % Fmech=Faero=Freq_frac=1 and the /2 below read as /4 (i.e. a whole
    % 4-wheel axle instead of a 2-wheel one) this reduces exactly to the
    % original whole-car formula.
    k = 1/2 ; % 2 wheels per axle
    a = -sign(r)*dmy*k*Faero^2*D^2 ;
    b = sign(r)*(muy*Faero*D+dmy*Ny*Faero*D-2*dmy*k*Fmech*Faero*Wz*D)-Freq_frac*M*r ;
    c = sign(r)*(muy*Fmech*Wz+dmy*Ny*Fmech*Wz-dmy*k*Fmech^2*Wz^2)+Freq_frac*Wy ;
    if a==0
        v = sqrt(-c/b) ;
    elseif b^2-4*a*c>=0
        if (-b+sqrt(b^2-4*a*c))/2/a>=0
            v = sqrt((-b+sqrt(b^2-4*a*c))/2/a) ;
        elseif (-b-sqrt(b^2-4*a*c))/2/a>=0
            v = sqrt((-b-sqrt(b^2-4*a*c))/2/a) ;
        else
            error(['No real roots at point index: ',num2str(p)])
        end
    else
        error(['Discriminant <0 at point index: ',num2str(p)])
    end
end
