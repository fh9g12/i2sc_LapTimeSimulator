function obj = fromStruct(s)
    % Vehicle.fromStruct - build a Vehicle from a scalar struct whose
    % fields match Vehicle's property names.
    obj = open.Vehicle(s) ;
end
