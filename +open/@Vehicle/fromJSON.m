function obj = fromJSON(filepath)
    % Vehicle.fromJSON - load a Vehicle previously saved with saveToJSON,
    % reconstructing the "shifting" table and 3-D "GGV" array that
    % saveToJSON had to flatten.
    raw = fileread(filepath) ;
    s = jsondecode(raw) ;

    n = numel(s.shifting.shift_points) ;
    rownames = cell(n,1) ;
    for i = 1:n
        rownames{i} = sprintf('%d-%d', i, i+1) ;
    end
    s.shifting = table(s.shifting.shift_points, s.shifting.arrive_points, s.shifting.rev_drops, ...
        'VariableNames', {'shift_points','arrive_points','rev_drops'}, 'RowNames', rownames) ;

    sz = reshape(s.GGV.size, 1, []) ;
    s.GGV = reshape(s.GGV.data, sz(1), sz(2), sz(3)) ;

    obj = open.Vehicle.fromStruct(s) ;
end
