function obj = fromJSON(filepath)
    % SeasonResult.fromJSON - load a SeasonResult previously saved with
    % saveToJSON, reconstructing the flattened sectorTimes cell array and
    % restoring track/file to string arrays (jsondecode returns JSON
    % string arrays as cell arrays of char, not MATLAB string arrays).
    raw = fileread(filepath) ;
    s = jsondecode(raw) ;

    padded = s.sectorTimes.data ;
    counts = s.sectorTimes.counts ;
    n = numel(counts) ;
    sectorTimes = cell(n,1) ;
    for i = 1:n
        sectorTimes{i} = padded(i,1:counts(i))' ;
    end
    s.sectorTimes = sectorTimes ;
    s.track = string(s.track) ;
    s.file = string(s.file) ;

    obj = open.SeasonResult.fromStruct(s) ;
end
