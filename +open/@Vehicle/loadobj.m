function obj = loadobj(s)
    % Vehicle.loadobj - MATLAB calls this automatically whenever a
    % Vehicle is loaded from a .mat file (via bare load() as well as
    % loadFromMat), BYPASSING the normal constructor entirely -- which
    % matters here because a .mat file saved before enginePowerLimitInterp
    % existed on this class loads back with that property at its
    % uninitialised default ([]) rather than a real griddedInterpolant,
    % and the constructor's own auto-build check (see Vehicle.m) never
    % gets a chance to run for it. This repeats that same check here so
    % an old .mat file gets a working interpolant rebuilt on load instead
    % of an empty array that vehicleModelLat/vehicleModelComb would then
    % try to call as if it were one.
    %
    % s is normally already a valid Vehicle object; MATLAB only passes a
    % plain struct instead if the class has changed so much a Vehicle
    % couldn't be reconstructed at all, which routes it through the
    % ordinary constructor (and its own auto-build check) instead.
    if isstruct(s)
        obj = open.Vehicle(s) ;
    else
        obj = s ;
        if isempty(obj.enginePowerLimitInterp) && ~isempty(obj.vehicle_speed)
            obj.enginePowerLimitInterp = griddedInterpolant( ...
                obj.vehicle_speed, obj.factor_power*obj.fx_engine, 'linear', 'none') ;
        end
    end
end
