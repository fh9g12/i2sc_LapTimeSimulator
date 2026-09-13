function obj = fromStruct(s)
    % Track.fromStruct - build a Track from a scalar struct whose fields
    % match Track's property names.
    obj = open.Track(s) ;
end
