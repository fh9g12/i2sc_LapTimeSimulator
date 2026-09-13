function obj = withAero(obj, options)
    % withAero - returns a copy of this Vehicle with Cl, Cd and/or the
    % aero balance (da) overridden, and every quantity that is derived
    % from them recomputed consistently (factor_drive/factor_aero/
    % driven_wheels, the force-model outputs, and the GGV map).
    %
    % Setting obj.Cl/obj.Cd/obj.da directly is NOT enough: factor_aero
    % and factor_drive are baked in from df/da/drive once at construction
    % time (see private/computeForceModel.m), so a bare property
    % assignment silently leaves them stale and an aero-balance sweep
    % would have no effect on the lap simulation.
    %
    % Name-value options: Cl, Cd, da (each defaults to its current value,
    % so omitted ones are left unchanged).
    arguments
        obj (1,1) open.Vehicle
        options.Cl (1,1) double = obj.Cl
        options.Cd (1,1) double = obj.Cd
        options.da (1,1) double = obj.da
    end

    obj.Cl = options.Cl ;
    obj.Cd = options.Cd ;
    obj.da = options.da ;

    raw = obj.toStruct() ;
    driveline.vehicle_speed = obj.vehicle_speed ;
    driveline.v_max = obj.v_max ;
    driveline.fx_engine = obj.fx_engine ;

    force = computeForceModel(raw, driveline) ;
    fields = fieldnames(force) ;
    for k = 1:numel(fields)
        obj.(fields{k}) = force.(fields{k}) ;
    end

    obj.GGV = computeGGVMap(raw, driveline, force) ;
end
