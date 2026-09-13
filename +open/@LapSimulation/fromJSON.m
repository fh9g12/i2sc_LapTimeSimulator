function obj = fromJSON(filepath)
    % LapSimulation.fromJSON - load a LapSimulation previously saved with
    % saveToJSON, reconstructing the flattened 3-D v/Ax/Ay/tps/bps
    % channels.
    raw = fileread(filepath) ;
    s = jsondecode(raw) ;

    threeDChannels = ["v","Ax","Ay","tps","bps"] ;
    for k = 1:numel(threeDChannels)
        name = threeDChannels(k) ;
        sz = reshape(s.(name).data.size, 1, []) ;
        s.(name).data = reshape(s.(name).data.data, sz(1), sz(2), sz(3)) ;
    end

    obj = open.LapSimulation.fromStruct(s) ;
end
