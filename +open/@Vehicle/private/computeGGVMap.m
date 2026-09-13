function GGV = computeGGVMap(raw, driveline, force)
    g = 9.81 ;

    % track data (flat, level track assumed when building the vehicle model)
    bank = 0 ;
    incl = 0 ;

    % lateral tyre coefficients
    dmy = raw.factor_grip*raw.sens_y ;
    muy = raw.factor_grip*raw.mu_y ;
    Ny = raw.mu_y_M*g ;
    % longitudinal tyre coefficients
    dmx = raw.factor_grip*raw.sens_x ;
    mux = raw.factor_grip*raw.mu_x ;
    Nx = raw.mu_x_M*g ;

    % normal load on all wheels
    Wz = raw.M*g*cosd(bank)*cosd(incl) ;
    % induced weight from banking and inclination
    Wy = -raw.M*g*sind(bank) ; %#ok<NASGU>
    Wx = raw.M*g*sind(incl) ;

    % speed map vector
    dv = 2 ;
    v = (0:dv:driveline.v_max)' ;
    if v(end)~=driveline.v_max
        v = [v;driveline.v_max] ;
    end

    % friction ellipse points
    N = 45 ;
    GGV = zeros(length(v),2*N-1,3) ;
    for i = 1:length(v)
        Aero_Df = 1/2*raw.rho*raw.factor_Cl*raw.Cl*raw.A*v(i)^2 ;
        Aero_Dr = -1/2*raw.rho*raw.factor_Cd*raw.Cd*raw.A*v(i)^2 ; % Cd now positive (see Vehicle.m); leading '-' keeps this negative
        Roll_Dr = -raw.Cr*abs(-Aero_Df+Wz) ; % Cr now positive too
        Wd = (force.factor_drive*Wz+(-force.factor_aero*Aero_Df))/force.driven_wheels ;
        ax_drag = (Aero_Dr+Roll_Dr+Wx)/raw.M ;
        ay_max = 1/raw.M*open.maxAxleLimitedLateralForce(muy,dmy,Ny,Wz,Aero_Df,raw.df,raw.da) ;
        ax_tyre_max_acc = 1/raw.M*(mux+dmx*(Nx-Wd))*Wd*force.driven_wheels ;
        ax_tyre_max_dec = -1/raw.M*(mux+dmx*(Nx-(Wz-Aero_Df)/4))*(Wz-Aero_Df) ;
        ax_power_limit = 1/raw.M*(interp1(driveline.vehicle_speed, raw.factor_power*driveline.fx_engine, v(i))) ;
        ax_power_limit = ax_power_limit*ones(N,1) ;

        ay = ay_max*cosd(linspace(0,180,N))' ;
        ax_tyre_acc = ax_tyre_max_acc*sqrt(1-(ay/ay_max).^2) ; % friction ellipse
        ax_acc = min(ax_tyre_acc,ax_power_limit)+ax_drag ; % limited by engine power
        ax_dec = ax_tyre_max_dec*sqrt(1-(ay/ay_max).^2)+ax_drag ; % friction ellipse

        GGV(i,:,1) = [ax_acc',ax_dec(2:end)'] ;
        GGV(i,:,2) = [ay',flipud(ay(2:end))'] ;
        GGV(i,:,3) = v(i)*ones(1,2*N-1) ;
    end
end
