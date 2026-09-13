classdef LapSimulation
    % LapSimulation - lap time simulation result for a Vehicle driven
    % around a Track, using a simple point mass model (the OpenLAP
    % solver).
    %
    % Build one with open.LapSimulation.Run(veh, tr), then persist it
    % with saveToMat/loadFromMat (primary, lossless) or saveToJSON/
    % fromJSON (secondary, human-readable). Each property is a struct
    % with a .data field and a .unit field (empty where dimensionless),
    % matching the channel layout exportCSV writes out.
    %
    % plotModel and exportCSV additionally need the Vehicle and Track
    % used to produce this result (for track geometry, the GGV envelope,
    % and labelling), so pass them in alongside this object.

    properties
        distance
        time
        N
        apex
        speed_max
        flag
        v
        Ax
        Ay
        tps
        bps
        elevation
        speed
        yaw_rate
        long_acc
        lat_acc
        sum_acc
        throttle
        brake_pres
        brake_force
        steering
        delta
        beta
        Fz_aero
        Fx_aero
        Fx_eng
        Fx_roll
        Fz_mass
        Fz_total
        wheel_torque
        engine_torque
        engine_power
        engine_speed
        gear
        fuel_cons
        fuel_cons_total
        laptime
        sector_time
        percent_in_corners
        percent_in_accel
        percent_in_decel
        percent_in_coast
        percent_in_full_tps
        percent_in_gear
        v_min
        v_max
        v_ave
        energy_spent_fuel
        energy_spent_mech
        gear_shifts
        lat_acc_max
        long_acc_max
        long_acc_min
        sector_v_max
        sector_v_min
    end

    methods
        function obj = LapSimulation(params)
            arguments
                params (1,1) struct = struct()
            end
            fields = fieldnames(params) ;
            for k = 1:numel(fields)
                obj.(fields{k}) = params.(fields{k}) ;
            end
        end
    end

    % These are Static methods (non-default attribute), so their
    % signatures must be declared here; the bodies live in their own
    % files elsewhere in this class folder.
    methods (Static)
        obj = Run(veh, tr)
        obj = fromStruct(s)
        obj = loadFromMat(filepath)
        obj = fromJSON(filepath)
    end

    % toStruct, saveToMat, saveToJSON, plotModel and exportCSV are
    % ordinary public instance methods (default attributes), so MATLAB
    % discovers their separate files in this class folder without
    % needing a signature declared here.
end
