function v = maxCorneringSpeed(M, r, Wy, Wz, D, df, da, muy, dmy, Ny, p)
    % maxCorneringSpeed - maximum steady-state cornering speed for a
    % two-axle (bicycle model) car: solves each axle's own grip-limited
    % speed independently (front share df/da, rear share (1-df)/(1-da),
    % each required to carry its moment-balance share df / (1-df) of the
    % total cornering force) and returns whichever is lower, i.e.
    % whichever axle saturates first.
    v_front = open.solveAxleCorneringSpeed(M, r, Wy, Wz, D, df, da, df, muy, dmy, Ny, p) ;
    v_rear = open.solveAxleCorneringSpeed(M, r, Wy, Wz, D, 1-df, 1-da, 1-df, muy, dmy, Ny, p) ;
    v = min(v_front, v_rear) ;
end
