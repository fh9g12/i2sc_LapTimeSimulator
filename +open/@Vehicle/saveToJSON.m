function saveToJSON(obj, filepath)
    % saveToJSON - secondary, human-readable export. jsonencode cannot
    % represent MATLAB tables or N-D arrays directly, so the "shifting"
    % table and the 3-D "GGV" array are flattened here; fromJSON reverses
    % the flattening on load. enginePowerLimitInterp (a griddedInterpolant
    % object, not JSON-serialisable either) is dropped entirely instead --
    % it's fully derivable from vehicle_speed/factor_power/fx_engine
    % (which ARE saved below), so Vehicle's constructor just rebuilds it
    % automatically on load.
    s = obj.toStruct() ;
    s = rmfield(s, 'enginePowerLimitInterp') ;

    s.shifting = struct( ...
        'shift_points', obj.shifting.shift_points, ...
        'arrive_points', obj.shifting.arrive_points, ...
        'rev_drops', obj.shifting.rev_drops) ;
    s.GGV = struct('size', size(obj.GGV), 'data', obj.GGV(:)) ;

    json = jsonencode(s, 'PrettyPrint', true) ;
    fid = fopen(filepath, 'w') ;
    if fid == -1
        error('open:Vehicle:saveToJSON', 'Could not open file for writing: %s', filepath) ;
    end
    cleanupObj = onCleanup(@() fclose(fid)) ; %#ok<NASGU>
    fwrite(fid, json, 'char') ;
end
