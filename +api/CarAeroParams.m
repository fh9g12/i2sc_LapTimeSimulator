classdef CarAeroParams
    % CarAeroParams - car geometry/body parameters shared by the aero functions.
    %
    %   p = api.CarAeroParams()                          % defaults
    %   p = api.CarAeroParams('rearSpan_m',1.2,'CD_body',0.9)
    %
    % All coefficients use the Vehicle convention: CL negative = downforce,
    % CD positive. Car-level coefficients are referenced to carFrontalArea_m2.
    % frontChord_m / rearChord_m also set the XFoil Reynolds number in
    % api.wingSectionAero -- a section database must be built at the same chord.

    properties
        frontChord_m (1,1) double {mustBePositive} = 0.3
        frontSpan_m  (1,1) double {mustBePositive} = 1.8
        rearChord_m  (1,1) double {mustBePositive} = 0.3
        rearSpan_m   (1,1) double {mustBePositive} = 1.0
        oswaldEfficiency (1,1) double {mustBePositive} = 0.8
        CL_body (1,1) double {mustBeNonpositive} = -3
        CD_body (1,1) double {mustBeNonnegative} = 1
        bodyAeroBalance (1,1) double {mustBeInRange(bodyAeroBalance,0,1)} = 0.5
        carFrontalArea_m2 (1,1) double {mustBePositive} = 1.0
    end

    properties (Dependent, SetAccess = private)
        S_front     % front wing planform area [m^2]
        S_rear      % rear wing planform area [m^2]
        AR_front    % front wing aspect ratio [-]
        AR_rear     % rear wing aspect ratio [-]
    end

    methods
        function obj = CarAeroParams(nv)
            arguments
                nv.?api.CarAeroParams
            end
            for f = string(fieldnames(nv))'
                obj.(f) = nv.(f);
            end
        end
        function v = get.S_front(obj),  v = obj.frontChord_m*obj.frontSpan_m;  end
        function v = get.S_rear(obj),   v = obj.rearChord_m*obj.rearSpan_m;    end
        function v = get.AR_front(obj), v = obj.frontSpan_m/obj.frontChord_m;  end
        function v = get.AR_rear(obj),  v = obj.rearSpan_m/obj.rearChord_m;    end
    end
end