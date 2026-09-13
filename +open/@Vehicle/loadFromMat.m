function obj = loadFromMat(filepath)
    % Vehicle.loadFromMat - load a Vehicle previously saved with saveToMat.
    data = load(filepath, 'vehicle') ;
    obj = data.vehicle ;
end
