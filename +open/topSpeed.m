function v = topSpeed(veh)
% topSpeed - a vehicle's straight-line terminal speed [m/s]: the speed at
% which its available longitudinal acceleration (engine thrust minus
% aero drag and rolling resistance, at zero lateral load) first reaches
% zero.
%
% v = open.topSpeed(veh)
%
% Read directly off veh.GGV (interpolated to the point nearest ay=0 at
% each tabulated speed), so it reflects the vehicle's ACTUAL current
% aero and gearing. This is NOT the same as Vehicle.v_max, which is a
% purely mechanical ceiling set by top gear ratio and engine redline,
% independent of Cd -- v_max only sets how far the GGV table's speed
% axis extends, not how far the car can actually accelerate to.
    arguments
        veh (1,1) open.Vehicle
    end

    speeds = veh.GGV(:,1,3) ;
    nAy = size(veh.GGV,2) ;    % = 2N-1, columns 1:N are the acceleration branch
    N = (nAy+1)/2 ;

    axStraight = zeros(size(speeds)) ;
    for i = 1:numel(speeds)
        ayRow = veh.GGV(i,1:N,2) ;
        axRow = veh.GGV(i,1:N,1) ;
        [~,k] = min(abs(ayRow)) ; % column nearest zero lateral acceleration
        axStraight(i) = axRow(k) ;
    end

    idx = find(axStraight>=0,1,'last') ;
    if isempty(idx)
        v = speeds(1) ;
    elseif idx==numel(speeds)
        v = speeds(end) ; % never reaches zero within the tabulated speed range
    else
        v = interp1(axStraight([idx,idx+1]), speeds([idx,idx+1]), 0) ;
    end
end
