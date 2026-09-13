classdef Vehicle
    % Vehicle - racing vehicle model for use with OpenLAP and OpenDRAG.
    %
    % Build one with open.Vehicle.FromExcelFile(filename), then persist it
    % with saveToMat/loadFromMat (primary, lossless) or saveToJSON/fromJSON
    % (secondary, human-readable) for use later in OpenLAP/OpenDRAG.

    properties
        % info
        name
        type

        % mass, weight distribution, wheelbase, steering
        M           % mass [kg]
        df          % front weight distribution [-]
        L           % wheelbase [m]
        rack        % steering rack ratio [-]

        % aerodynamics
        Cl          % lift coefficient [-]
        Cd          % drag coefficient [-]
        factor_Cl   % lift scaling factor [-]
        factor_Cd   % drag scaling factor [-]
        da          % aero balance (front) [-]
        A           % frontal area [m2]
        rho         % air density [kg/m3]

        % brakes (raw inputs)
        br_disc_d   % disc diameter [m]
        br_pad_h    % pad height [m]
        br_pad_mu   % pad friction coefficient [-]
        br_nop      % number of pistons per caliper [-]
        br_pist_d   % piston diameter [mm]
        br_mast_d   % master cylinder diameter [mm]
        br_ped_r    % pedal ratio [-]

        % tyres
        factor_grip % grip scaling factor [-]
        tyre_radius % [m]
        Cr          % rolling resistance coefficient [-]
        mu_x        % long. friction coefficient [-]
        mu_x_M      % long. friction sensitivity to load [1/kg]
        sens_x      % long. friction sensitivity [-]
        mu_y        % lat. friction coefficient [-]
        mu_y_M      % lat. friction sensitivity to load [1/kg]
        sens_y      % lat. friction sensitivity [-]
        CF          % front cornering stiffness [N/deg]
        CR          % rear cornering stiffness [N/deg]

        % engine
        factor_power % power scaling factor [-]
        n_thermal    % thermal efficiency [-]
        fuel_LHV     % fuel lower heating value [J/kg]

        % drivetrain
        drive         % 'RWD' | 'FWD' | 'AWD'
        shift_time    % [s]
        n_primary     % primary efficiency [-]
        n_final       % final drive efficiency [-]
        n_gearbox     % gearbox efficiency [-]
        ratio_primary
        ratio_final
        ratio_gearbox
        nog           % number of gears

        % brake model
        br_pist_a % caliper piston area [m2]
        br_mast_a % master cylinder area [m2]
        beta      % [Pa/N] per wheel
        phi       % [-] for both systems

        % steering model
        a % distance of front axle from centre of mass [m]
        b % distance of rear axle from centre of mass [m]
        C % steering model matrix

        % driveline model
        en_speed_curve     % [rpm]
        en_torque_curve    % [N*m]
        en_power_curve     % [W]
        wheel_speed_gear   % vehicle wheel speed per gear per engine speed sample
        vehicle_speed_gear % vehicle speed per gear per engine speed sample
        wheel_torque_gear  % wheel torque per gear per engine speed sample
        v_min              % [m/s]
        v_max              % [m/s]
        vehicle_speed      % [m/s]
        gear               % selected gear at each vehicle_speed sample
        fx_engine          % engine tractive force at each vehicle_speed sample [N]
        fx                 % engine tractive force per gear [N]
        wheel_torque       % [N*m]
        engine_torque      % [N*m]
        engine_power       % [W]
        engine_speed       % [rpm]

        % shift points
        shifting % table: shift_points, arrive_points, rev_drops per gear change

        % force model
        factor_drive   % driven-axle weight distribution [-]
        factor_aero    % driven-axle aero distribution [-]
        driven_wheels  % number of driven wheels [-]
        fz_mass        % static normal load [N]
        fz_aero        % aero downforce [N]
        fz_total       % total normal load [N]
        fz_tyre        % normal load per driven tyre [N]
        fx_aero        % aero drag [N]
        fx_roll        % rolling resistance [N]
        fx_tyre        % max tyre tractive force [N]

        % GGV map
        GGV % [speed index, friction-circle index, {ax, ay, v}]

        % Cached engine power-limit lookup: a griddedInterpolant over
        % (vehicle_speed, factor_power*fx_engine), 'linear' with 'none'
        % extrapolation (NaN outside the grid, matching the plain
        % interp1(...) call this replaces). vehicleModelLat/
        % vehicleModelComb call this many tens of thousands of times per
        % lap solve; interp1 re-parses/re-validates its inputs on every
        % single call, which profiling showed as ~40% of total solve
        % time -- building the interpolant ONCE here instead removes
        % that overhead, and since it depends only on vehicle_speed/
        % factor_power/fx_engine (not aero, not mass), it survives
        % unchanged through withAero/withMass and is reused across an
        % entire season sweep or fuel-mass convergence against the same
        % vehicle. Only gearing changes (withGearRatioScale/
        % withOptimalGearing, via rebuildDriveline.m) invalidate it, and
        % rebuildDriveline.m rebuilds it explicitly there. Not usefully
        % JSON-serialisable (saveToJSON drops it); the constructor below
        % rebuilds it automatically whenever it's missing but
        % vehicle_speed is present, so a JSON round-trip regenerates it
        % for free, and a .mat round-trip (which CAN serialise it
        % natively) just reuses the loaded one.
        enginePowerLimitInterp
    end

    methods
        function obj = Vehicle(params)
            arguments
                params (1,1) struct = struct()
            end
            fields = fieldnames(params) ;
            for k = 1:numel(fields)
                obj.(fields{k}) = params.(fields{k}) ;
            end
            if isempty(obj.enginePowerLimitInterp) && ~isempty(obj.vehicle_speed)
                obj.enginePowerLimitInterp = griddedInterpolant( ...
                    obj.vehicle_speed, obj.factor_power*obj.fx_engine, 'linear', 'none') ;
            end
        end
    end

    % These are Static methods (non-default attribute), so their
    % signatures must be declared here; the bodies live in their own
    % files elsewhere in this class folder.
    methods (Static)
        obj = FromExcelFile(filename)
        obj = fromStruct(s)
        obj = loadFromMat(filepath)
        obj = fromJSON(filepath)
        obj = loadobj(s)
    end

    % toStruct, saveToMat, saveToJSON and plotModel are ordinary public
    % instance methods (default attributes), so MATLAB discovers their
    % separate files in this class folder without needing a signature
    % declared here.
end
