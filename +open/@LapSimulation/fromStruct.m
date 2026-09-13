function obj = fromStruct(s)
    % LapSimulation.fromStruct - build a LapSimulation from a scalar
    % struct whose fields match LapSimulation's property names.
    obj = open.LapSimulation(s) ;
end
