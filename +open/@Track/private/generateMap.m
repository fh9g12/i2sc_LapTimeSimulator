function [X, Y] = generateMap(x, dx, r, L, info)
    % Integrates the curvature/mesh-step vectors into a 2D track map, with
    % a tangency correction so a closed track's heading returns exactly
    % to its starting value.
    n = length(x) ;
    X = zeros(n,1) ;
    Y = zeros(n,1) ;
    angle_seg = rad2deg(dx.*r) ;
    angle_head = cumsum(angle_seg) ;
    if strcmp(info.config,'Closed') % tangency correction for closed track
        dh = [...
            mod(angle_head(end),sign(angle_head(end))*360);...
            angle_head(end)-sign(angle_head(end))*360....
            ] ;
        [~,idx] = min(abs(dh)) ;
        dh = dh(idx) ;
        angle_head = angle_head-x/L*dh ;
    end
    angle_head = angle_head-angle_head(1) ;
    for i = 2:n
        p = [X(i-1);Y(i-1);0] ;
        xyz = open.rotz(angle_head(i-1))*[dx(i-1);0;0]+p ;
        X(i) = xyz(1) ;
        Y(i) = xyz(2) ;
    end
end
