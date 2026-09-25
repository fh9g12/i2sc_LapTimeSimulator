function [info, coarse] = loadLoggedTrackData(filename, filter_dt, log_mode, lambda)
    % Reads an "OpenTRACK Logged Data tmp.csv"-format telemetry file,
    % converts its units, and filters/smooths it into the same coarse
    % track representation that preprocessShapeData produces (position
    % vectors xx/xe/xb/xg/xs paired with value vectors r/el/bk/gf/sc,
    % plus the total track length L). Logged channels share one common
    % sample grid, so xe, xb, xg and xs all equal xx here.

    [head,data] = readLoggedData(filename) ;
    info.name = head(2,2) ;
    info.country = head(3,2) ;
    info.city = head(4,2) ;
    info.type = head(5,2) ;
    info.config = head(6,2) ;
    info.direction = head(7,2) ;
    info.mirror = head(8,2) ;
    % frequency
    freq = str2double(head(9,2)) ;
    % data columns
    col_dist = 1 ;
    col_vel = 2 ;
    col_yaw = 3 ;
    col_ay = 4 ;
    col_el = 5 ;
    col_bk = 6 ;
    col_gf = 7 ;
    col_sc = 8 ;
    units = head(12,:) ;
    % extracting data
    x = data(:,col_dist) ;
    v = data(:,col_vel) ;
    w = data(:,col_yaw) ;
    ay = data(:,col_ay) ;
    el = data(:,col_el) ;
    bk = data(:,col_bk) ;
    gf = data(:,col_gf) ;
    sc = data(:,col_sc) ;
    % converting units
    if units(col_dist)~="m"
        switch units(col_dist) % target is [m]
            case 'km'
                x = x*1000 ;
            case 'miles'
                x = x*1609.34 ;
            case 'ft'
                x = x*0.3048 ;
            otherwise
                warning('Check distance units.')
        end
    end
    if units(col_vel)~="m/s"
        switch units(col_vel) % target is [m/s]
            case 'km/h'
                v = v/3.6 ;
            case 'mph'
                v = v*0.44704 ;
            otherwise
                warning('Check speed units.')
        end
    end
    if units(col_yaw)~="rad/s"
        switch units(col_yaw) % target is [rad/s]
            case 'deg/s'
                w = w*2*pi/360 ;
            case 'rpm'
                w = w*2*pi/60 ;
            case 'rps'
                w = w*2*pi ;
            otherwise
                warning('Check yaw velocity units.')
        end
    end
    if units(col_ay)~="m/s/s"
        switch units(col_ay) % target is [m/s2]
            case 'G'
                ay = ay*9.81 ;
            case 'ft/s/s'
                ay = ay*0.3048 ;
            otherwise
                warning('Check lateral acceleration units.')
        end
    end
    if units(col_el)~="m"
        switch units(col_el) % target is [m]
            case 'km'
                el = el*1000 ;
            case 'miles'
                el = el*1609.34 ;
            case 'ft'
                el = el*0.3048 ;
            otherwise
                warning('Check elevation units.')
        end
    end
    if units(col_bk)~="deg"
        switch units(col_bk) % target is [m]
            case 'rad'
                bk = bk/2/pi*360 ;
            otherwise
                warning('Check banking units.')
        end
    end

    % getting unique points
    [x,rows_to_keep,~] = unique(x) ;
    v = open.smooth(v(rows_to_keep),round(freq*filter_dt)) ;
    w = open.smooth(w(rows_to_keep),round(freq*filter_dt)) ;
    ay = open.smooth(ay(rows_to_keep),round(freq*filter_dt)) ;
    el = open.smooth(el(rows_to_keep),round(freq*filter_dt)) ;
    bk = open.smooth(bk(rows_to_keep),round(freq*filter_dt)) ;
    gf = gf(rows_to_keep) ;
    sc = sc(rows_to_keep) ;
    % shifting position vector for 0 value at start
    x = x-x(1) ;
    % curvature
    switch log_mode
        case 'speed & yaw'
            r = lambda*w./v ;
        case 'speed & latacc'
            r = lambda*ay./v.^2 ;
    end
    r = open.smooth(r,round(freq*filter_dt)) ;
    % mirroring if needed
    if strcmp(info.mirror,'On')
        r = -r ;
    end

    coarse.xx = x ;
    coarse.r = r ;
    coarse.L = x(end) ;
    coarse.xe = x ;
    coarse.el = el ;
    coarse.xb = x ;
    coarse.bk = bk ;
    coarse.xg = x ;
    coarse.gf = gf ;
    coarse.xs = x ;
    coarse.sc = sc ;
end
