function obj = withMass(obj, M)
    % withMass - returns a copy of this Vehicle with mass M [kg]
    % overridden, and every quantity derived from it (the force model
    % and the GGV map) recomputed consistently.
    %
    % Note this is a narrower case than withAero's: LapSimulation's solver
    % (vehicleModelLat/vehicleModelComb) reads veh.M directly at every
    % point rather than through a cached property, so a bare obj.M=M
    % assignment WOULD already give correct lap times -- unlike da, whose
    % factor_aero/factor_drive genuinely are cached from construction and
    % silently go stale (see withAero.m). The recompute here matters for
    % everything else that reads the cached fields directly: fz_mass/
    % fz_total/fz_tyre/fx_roll/fx_tyre (private/computeForceModel.m) and
    % the whole GGV envelope (private/computeGGVMap.m, every ax/ay limit
    % divided through by mass) are baked in from M once at construction
    % time, so without this, Vehicle.plotModel's traction/GGV plots and
    % any GGV-vs-achieved-data comparison (e.g. LapSimulation.plotModel)
    % would silently show a stale mass even though the lap-time number
    % itself was already correct.
    %
    % Mass does NOT feed into the driveline model (engine curves, shift
    % points -- see rebuildDriveline.m), so unlike withGearRatioScale/
    % withOptimalGearing this only needs the force model + GGV map
    % recomputed, exactly like withAero.
    %
    % Intended use: modelling a fuel load. Build/load a Vehicle whose M
    % is the car's DRY mass (no fuel), then call
    % veh.withMass(dryMass + fuelRemaining_kg) at whatever fuel level
    % you want to simulate -- see open.simulateFuelCorrectedRace.m for a
    % worked example that sweeps this across a race distance.
    arguments
        obj (1,1) open.Vehicle
        M (1,1) double {mustBePositive}
    end

    obj.M = M ;

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
