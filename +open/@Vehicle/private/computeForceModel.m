function force = computeForceModel(raw, driveline)
    g = 9.81 ;
    switch raw.drive
        case 'RWD'
            force.factor_drive = (1-raw.df) ;
            force.factor_aero = (1-raw.da) ;
            force.driven_wheels = 2 ;
        case 'FWD'
            force.factor_drive = raw.df ;
            force.factor_aero = raw.da ;
            force.driven_wheels = 2 ;
        otherwise % AWD
            force.factor_drive = 1 ;
            force.factor_aero = 1 ;
            force.driven_wheels = 4 ;
    end

    v = driveline.vehicle_speed ;
    force.fz_mass = -raw.M*g ;
    force.fz_aero = 1/2*raw.rho*raw.factor_Cl*raw.Cl*raw.A*v.^2 ;
    force.fz_total = force.fz_mass+force.fz_aero ;
    force.fz_tyre = (force.factor_drive*force.fz_mass+force.factor_aero*force.fz_aero)/force.driven_wheels ;

    force.fx_aero = -1/2*raw.rho*raw.factor_Cd*raw.Cd*raw.A*v.^2 ; % Cd is now a positive drag magnitude (see Vehicle.m); leading '-' keeps this force negative (opposing motion), matching every consumer's existing expectations
    force.fx_roll = -raw.Cr*abs(force.fz_total) ; % same: Cr is now positive
    force.fx_tyre = force.driven_wheels*(raw.mu_x+raw.sens_x*(raw.mu_x_M*g-abs(force.fz_tyre))).*abs(force.fz_tyre) ;
end
