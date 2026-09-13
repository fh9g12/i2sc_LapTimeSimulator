function driveline = computeDrivelineModel(raw, torqueCurveTable)
    % engine curves
    driveline.en_speed_curve = table2array(torqueCurveTable(:,1)) ; % [rpm]
    driveline.en_torque_curve = table2array(torqueCurveTable(:,2)) ; % [N*m]
    driveline.en_power_curve = driveline.en_torque_curve.*driveline.en_speed_curve*2*pi/60 ; % [W]

    nog = raw.nog ;
    n = length(driveline.en_speed_curve) ;

    % wheel speed / vehicle speed / wheel torque per gear, per engine speed sample
    driveline.wheel_speed_gear = zeros(n,nog) ;
    driveline.vehicle_speed_gear = zeros(n,nog) ;
    driveline.wheel_torque_gear = zeros(n,nog) ;
    for i = 1:nog
        driveline.wheel_speed_gear(:,i) = driveline.en_speed_curve/raw.ratio_primary/raw.ratio_gearbox(i)/raw.ratio_final ;
        driveline.vehicle_speed_gear(:,i) = driveline.wheel_speed_gear(:,i)*2*pi/60*raw.tyre_radius ;
        driveline.wheel_torque_gear(:,i) = driveline.en_torque_curve*raw.ratio_primary*raw.ratio_gearbox(i)*raw.ratio_final*raw.n_primary*raw.n_gearbox*raw.n_final ;
    end

    driveline.v_min = min(driveline.vehicle_speed_gear,[],'all') ;
    driveline.v_max = max(driveline.vehicle_speed_gear,[],'all') ;

    % fine speed mesh
    dv = 0.5/3.6 ;
    vehicle_speed = linspace(driveline.v_min, driveline.v_max, (driveline.v_max-driveline.v_min)/dv)' ;

    gear = zeros(length(vehicle_speed),1) ;
    fx_engine = zeros(length(vehicle_speed),1) ;
    fx = zeros(length(vehicle_speed),nog) ;
    for i = 1:length(vehicle_speed)
        for j = 1:nog
            fx(i,j) = interp1(driveline.vehicle_speed_gear(:,j), driveline.wheel_torque_gear(:,j)/raw.tyre_radius, vehicle_speed(i), 'linear', 0) ;
        end
        [fx_engine(i),gear(i)] = max(fx(i,:)) ;
    end

    % prepend 0-speed point for interpolation at low speeds
    vehicle_speed = [0;vehicle_speed] ;
    gear = [gear(1);gear] ;
    fx_engine = [fx_engine(1);fx_engine] ;

    driveline.vehicle_speed = vehicle_speed ;
    driveline.gear = gear ;
    driveline.fx_engine = fx_engine ;
    driveline.fx = fx ;

    driveline.engine_speed = raw.ratio_final*raw.ratio_gearbox(gear)*raw.ratio_primary.*vehicle_speed/raw.tyre_radius*60/2/pi ;
    driveline.wheel_torque = fx_engine*raw.tyre_radius ;
    driveline.engine_torque = driveline.wheel_torque/raw.ratio_final./raw.ratio_gearbox(gear)/raw.ratio_primary/raw.n_primary/raw.n_gearbox/raw.n_final ;
    driveline.engine_power = driveline.engine_torque.*driveline.engine_speed*2*pi/60 ;
end
