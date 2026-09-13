function obj = fromStruct(s)
    % DragSimulation.fromStruct - build a DragSimulation from a scalar
    % struct whose fields match DragSimulation's property names.
    obj = open.DragSimulation(s) ;
end
