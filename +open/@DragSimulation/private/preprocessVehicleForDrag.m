function vp = preprocessVehicleForDrag(veh, bank, incl)
    % Bundles the vehicle-derived quantities needed by runAcceleration and
    % runDeceleration, computed once per simulation.
    vp.M = veh.M ;
    vp.g = 9.81 ;
    % longitudinal tyre coefficients
    vp.dmx = veh.factor_grip*veh.sens_x ;
    vp.mux = veh.factor_grip*veh.mu_x ;
    vp.Nx = veh.mu_x_M*vp.g ;
    % normal load on all wheels
    vp.Wz = vp.M*vp.g*cosd(bank)*cosd(incl) ;
    % induced weight from banking and inclination
    vp.Wy = vp.M*vp.g*sind(bank) ;
    vp.Wx = vp.M*vp.g*sind(incl) ;
    % ratios
    vp.rf = veh.ratio_final ;
    vp.rg = veh.ratio_gearbox ;
    vp.rp = veh.ratio_primary ;
    % tyre radius
    vp.Rt = veh.tyre_radius ;
    % drivetrain efficiency
    vp.np = veh.n_primary ;
    vp.ng = veh.n_gearbox ;
    vp.nf = veh.n_final ;
    % engine curves
    vp.rpm_curve = [0;veh.en_speed_curve] ;
    vp.torque_curve = veh.factor_power*[veh.en_torque_curve(1);veh.en_torque_curve] ;
    % shift points
    vp.shift_points = table2array(veh.shifting(:,1)) ;
    vp.shift_points = [vp.shift_points;veh.en_speed_curve(end)] ;
    % aero & rolling resistance
    vp.rho = veh.rho ;
    vp.factor_Cl = veh.factor_Cl ;
    vp.Cl = veh.Cl ;
    vp.factor_Cd = veh.factor_Cd ;
    vp.Cd = veh.Cd ;
    vp.A = veh.A ;
    vp.Cr = veh.Cr ;
    % drive layout
    vp.factor_drive = veh.factor_drive ;
    vp.factor_aero = veh.factor_aero ;
    vp.driven_wheels = veh.driven_wheels ;
    % limits
    vp.v_max = veh.v_max ;
    vp.nog = veh.nog ;
    vp.shift_time = veh.shift_time ;
    % brakes
    vp.beta = veh.beta ;
    % speed-indexed curves (for deceleration phase)
    vp.vehicle_speed = veh.vehicle_speed ;
    vp.gear_curve = veh.gear ;
    vp.engine_speed_curve = veh.engine_speed ;
end
