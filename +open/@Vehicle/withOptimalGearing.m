function obj = withOptimalGearing(obj)
    % withOptimalGearing - returns a copy of this Vehicle with its top
    % gear ratio re-picked so the engine reaches redline exactly at the
    % car's aero-equilibrium terminal velocity (the speed at which
    % available thrust equals aero drag + rolling resistance), for its
    % CURRENT Cl/Cd/mass. Every quantity derived from gearing (driveline
    % curves, shift points, force model, GGV map) is recomputed to
    % match, exactly as FromExcelFile would for a hand-edited top gear
    % ratio in the source Excel file.
    %
    % This is the theoretical BEST possible gearing for the current
    % Cl/Cd, useful as a reference/oracle (e.g. to sanity-check a
    % student's own choice via withGearRatioScale) -- it is not applied
    % automatically anywhere, since picking gearing to suit an aero
    % package is meant to be part of the exercise, not solved for you.
    g = 9.81 ;
    Wz = obj.M*g ; % flat, level reference condition, matching v_max's own convention (see computeGGVMap)

    % Solve factor_power*P_redline/v + Aero_Dr(v) + Roll_Dr(v) = 0 for v,
    % i.e. thrust (assuming the engine sits at redline, so available
    % power is constant) balances drag + rolling resistance. Multiplying
    % through by v gives a cubic alpha*v^3 + beta*v + gamma = 0 with
    % exactly one positive real root (alpha, beta < 0 and gamma > 0 for
    % any physically sensible car, so the positive branch is unique).
    P_redline = obj.en_torque_curve(end)*(obj.en_speed_curve(end)*2*pi/60)*obj.n_primary*obj.n_gearbox*obj.n_final ;
    % Cd and Cr are positive drag magnitudes (see Vehicle.m's sign
    % convention notes), so alpha and beta carry a leading '-' to turn
    % them back into "opposes motion" terms; Cl's sign is unchanged.
    alpha = -(1/2*obj.rho*obj.A*(obj.factor_Cd*obj.Cd - obj.Cr*obj.factor_Cl*obj.Cl)) ;
    beta = -(obj.Cr*Wz) ;
    gamma = obj.factor_power*P_redline ;

    r = roots([alpha,0,beta,gamma]) ;
    r = r(abs(imag(r))<1E-6 & real(r)>0) ;
    if isempty(r)
        error('open:Vehicle:withOptimalGearing', 'Could not find a positive real terminal speed for this Cl/Cd/mass combination.')
    end
    v_term = real(r(1)) ;

    redline_rad_s = obj.en_speed_curve(end)*2*pi/60 ;
    ratio_top_new = redline_rad_s*obj.tyre_radius/(obj.ratio_final*obj.ratio_primary*v_term) ;
    if obj.nog>1 && ratio_top_new>=obj.ratio_gearbox(end-1)
        warning('open:Vehicle:withOptimalGearing', ...
            'Optimal top gear ratio (%.3f) is not shorter than the previous gear (%.3f); this car is very high-drag for its gearbox spacing.', ...
            ratio_top_new, obj.ratio_gearbox(end-1)) ;
    end
    obj.ratio_gearbox(end) = ratio_top_new ;
    obj = rebuildDriveline(obj) ;
end
