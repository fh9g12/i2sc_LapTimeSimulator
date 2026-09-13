function obj = fromJSON(filepath)
    % DragSimulation.fromJSON - load a DragSimulation previously saved
    % with saveToJSON.
    raw = fileread(filepath) ;
    s = jsondecode(raw) ;
    obj = open.DragSimulation.fromStruct(s) ;
end
