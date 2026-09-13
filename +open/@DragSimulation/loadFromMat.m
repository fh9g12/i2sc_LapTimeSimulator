function obj = loadFromMat(filepath)
    % DragSimulation.loadFromMat - load a DragSimulation previously saved
    % with saveToMat.
    data = load(filepath, 'dragSimulation') ;
    obj = data.dragSimulation ;
end
