function Fy_max = maxAxleLimitedLateralForce(muy, dmy, Ny, Wz, Aero_Df, df, da)
    % maxAxleLimitedLateralForce - maximum unsigned TOTAL lateral force
    % the car can generate in steady-state cornering.
    %
    % For steady-state cornering, moment balance about the centre of
    % mass fixes the REQUIRED front/rear force split at df:(1-df),
    % regardless of aero (this depends only on where the mechanical
    % weight, and hence the CG, sits). What aero balance (da) changes is
    % each axle's AVAILABLE grip, via how much downforce sits on it.
    % So the achievable total force is set by whichever axle's required
    % share (df or 1-df of the total) first exceeds what that axle can
    % actually produce -- i.e. the car is front- or rear-limited,
    % exactly like a real understeer/oversteer balance.
    [Nf,Nr] = open.axleNormalLoads(Wz, Aero_Df, df, da) ;
    Fyf_max = open.axleLateralForceMax(muy, dmy, Ny, Nf) ;
    Fyr_max = open.axleLateralForceMax(muy, dmy, Ny, Nr) ;
    Fy_max = min(Fyf_max/df, Fyr_max/(1-df)) ;
end
