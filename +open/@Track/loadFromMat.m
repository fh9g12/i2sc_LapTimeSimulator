function obj = loadFromMat(filepath)
    % Track.loadFromMat - load a Track previously saved with saveToMat.
    data = load(filepath, 'track') ;
    obj = data.track ;
end
