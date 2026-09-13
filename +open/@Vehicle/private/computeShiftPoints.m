function shifting = computeShiftPoints(driveline, nog)
    gear_change = diff(driveline.gear) ; % gear change appears as 1
    gear_change = logical([gear_change;0]+[0;gear_change]) ;
    engine_speed_gear_change = driveline.engine_speed(gear_change) ;

    shift_points = engine_speed_gear_change(1:2:length(engine_speed_gear_change)) ;
    arrive_points = engine_speed_gear_change(2:2:length(engine_speed_gear_change)) ;
    rev_drops = shift_points-arrive_points ;

    rownames = cell(nog-1,1) ;
    for i = 1:nog-1
        rownames(i) = {[num2str(i,'%d'),'-',num2str(i+1,'%d')]} ;
    end
    shifting = table(shift_points, arrive_points, rev_drops, 'RowNames', rownames) ;
end
