function obj = rebuildDriveline(obj)
    % rebuildDriveline - recomputes everything derived from gearing
    % (driveline curves, shift points, force model, GGV map) after
    % ratio_gearbox and/or ratio_final have been changed directly on obj.
    % Shared by withOptimalGearing and withGearRatioScale, exactly
    % mirroring what FromExcelFile would produce for a hand-edited
    % gearbox spec in the source Excel file.
    raw = obj.toStruct() ;
    torqueCurveTable = table(obj.en_speed_curve, obj.en_torque_curve) ;
    driveline = computeDrivelineModel(raw, torqueCurveTable) ;
    fields = fieldnames(driveline) ;
    for k = 1:numel(fields)
        obj.(fields{k}) = driveline.(fields{k}) ;
    end

    % gearing just changed vehicle_speed/fx_engine, so the cached engine
    % power-limit interpolant (see Vehicle.m) is stale -- rebuild it here
    % explicitly, since this bypasses the constructor's own auto-build.
    obj.enginePowerLimitInterp = griddedInterpolant( ...
        obj.vehicle_speed, obj.factor_power*obj.fx_engine, 'linear', 'none') ;

    obj.shifting = computeShiftPoints(driveline, raw.nog) ;

    force = computeForceModel(raw, driveline) ;
    fields = fieldnames(force) ;
    for k = 1:numel(fields)
        obj.(fields{k}) = force.(fields{k}) ;
    end

    obj.GGV = computeGGVMap(raw, driveline, force) ;
end
