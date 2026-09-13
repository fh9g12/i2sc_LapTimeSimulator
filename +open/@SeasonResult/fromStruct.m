function obj = fromStruct(s)
    % SeasonResult.fromStruct - build a SeasonResult from a scalar struct
    % whose fields match SeasonResult's property names.
    obj = open.SeasonResult(s) ;
end
