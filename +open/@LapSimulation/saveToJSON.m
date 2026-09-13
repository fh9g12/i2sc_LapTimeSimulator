function saveToJSON(obj, filepath)
    % saveToJSON - secondary, human-readable export. v, Ax, Ay, tps and
    % bps hold [n x apexCount x 2] solver-internal arrays, which
    % jsonencode cannot represent directly, so they are flattened here
    % and rebuilt by fromJSON. Every other channel is already a scalar
    % or a 1-D/2-D array and round-trips through jsonencode/jsondecode
    % directly.
    s = obj.toStruct() ;

    threeDChannels = ["v","Ax","Ay","tps","bps"] ;
    for k = 1:numel(threeDChannels)
        name = threeDChannels(k) ;
        s.(name).data = struct('size', size(obj.(name).data), 'data', obj.(name).data(:)) ;
    end

    json = jsonencode(s, 'PrettyPrint', true) ;
    fid = fopen(filepath, 'w') ;
    if fid == -1
        error('open:LapSimulation:saveToJSON', 'Could not open file for writing: %s', filepath) ;
    end
    cleanupObj = onCleanup(@() fclose(fid)) ; %#ok<NASGU>
    fwrite(fid, json, 'char') ;
end
