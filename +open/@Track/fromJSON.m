function obj = fromJSON(filepath)
    % Track.fromJSON - load a Track previously saved with saveToJSON.
    raw = fileread(filepath) ;
    s = jsondecode(raw) ;
    obj = open.Track.fromStruct(s) ;
end
