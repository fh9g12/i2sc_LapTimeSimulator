function obj = withMass(obj, M)
    % withMass - returns a copy of this Vehicle with mass M [kg]
    % overridden, and every quantity derived from it (the force model
    % and the GGV map) recomputed consistently.
    %
    % LapSimulation's solver reads veh.M directly, so a bare obj.M=M
    % assignment would already give correct lap times -- but fz_mass/
    % fz_total/fz_tyre/fx_roll/fx_tyre (private/computeForceModel.m) and
    % the whole GGV envelope (private/computeGGVMap.m, every ax/ay limit
    % divided through by mass) are cached from M at construction time, so
    % skipping this recompute would leave Vehicle.plotModel's
    % traction/GGV plots (and any GGV-vs-achieved comparison, e.g.
    % LapSimulation.plotModel) showing a stale mass.
    %
    % Mass does not feed into the driveline model (engine curves, shift
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
