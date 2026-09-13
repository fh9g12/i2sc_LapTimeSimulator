function arrow = computeFinishArrow(X, Y, Z)
    % Builds the 3-point finish-line direction arrow (used by plotModel
    % and by OpenLAP's track-map plot) pointing back from the start.
    factor_scale = 25 ;
    half_angle = 40 ;
    scale = max([max(X)-min(X);max(Y)-min(Y)])/factor_scale ;
    arrow_n = [X(1)-X(2);Y(1)-Y(2);Z(1)-Z(2)]/norm([X(1)-X(2);Y(1)-Y(2);Z(1)-Z(2)]) ;
    arrow_1 = scale*rotz(half_angle)*arrow_n+[X(1);Y(1);Z(1)] ;
    arrow_c = [X(1);Y(1);Z(1)] ;
    arrow_2 = scale*rotz(-half_angle)*arrow_n+[X(1);Y(1);Z(1)] ;
    arrow_x = [arrow_1(1);arrow_c(1);arrow_2(1)] ;
    arrow_y = [arrow_1(2);arrow_c(2);arrow_2(2)] ;
    arrow_z = [arrow_1(3);arrow_c(3);arrow_2(3)] ;
    arrow = [arrow_x,arrow_y,arrow_z] ;
end
