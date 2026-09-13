function obj = loadFromMat(filepath)
    % LapSimulation.loadFromMat - load a LapSimulation previously saved
    % with saveToMat.
    data = load(filepath, 'lapSimulation') ;
    obj = data.lapSimulation ;
end
