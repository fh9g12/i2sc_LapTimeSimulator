function obj = withGearRatioScale(obj, scale)
    % withGearRatioScale - returns a copy of this Vehicle with its final
    % drive ratio scaled by "scale" (scale>1 = shorter gearing, more
    % acceleration, lower top speed; scale<1 = taller gearing, less
    % acceleration, higher top speed), with every quantity derived from
    % gearing (driveline curves, shift points, force model, GGV map)
    % recomputed to match -- exactly as FromExcelFile would for a
    % hand-edited final drive ratio in the source Excel file.
    %
    % Scaling ratio_final has an identical effect on every gear's
    % speed/rpm relationship as scaling the whole ratio_gearbox array by
    % the same factor (they only ever appear multiplied together), so
    % this single number is enough to re-gear the whole car while
    % leaving the relative spacing between gears untouched.
    %
    % This is deliberately a manual knob, not solved for automatically:
    % picking gearing to suit a given Cl/Cd is meant to be part of the
    % exercise. See Vehicle.withOptimalGearing for the theoretical best
    % answer, useful as a reference to check your own choice against.
    arguments
        obj (1,1) open.Vehicle
        scale (1,1) double {mustBePositive} = 1
    end

    obj.ratio_final = obj.ratio_final*scale ;
    obj = rebuildDriveline(obj) ;
end
