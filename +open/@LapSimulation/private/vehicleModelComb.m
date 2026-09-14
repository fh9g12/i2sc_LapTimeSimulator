function [v_next, ax, ay, tps, bps, overshoot] = vehicleModelComb(veh, tr, v, v_max_next, j, mode)
    % Combined (longitudinal + lateral) point-mass vehicle model: advances
    % speed from point j to the next point, one solver step at a time.

    %% initialisation
    overshoot = false ;
    dx = tr.dx(j) ;
    r = tr.r(j) ;
    incl = tr.incl(j) ;
    bank = tr.bank(j) ;
    factor_grip = tr.factor_grip(j)*veh.factor_grip ;
    g = 9.81 ;
    if mode==1
        factor_drive = veh.factor_drive ;
        factor_aero = veh.factor_aero ;
        driven_wheels = veh.driven_wheels ;
    else
        factor_drive = 1 ;
        factor_aero = 1 ;
        driven_wheels = 4 ;
    end

    %% external forces
    M = veh.M ;
    Wz = M*g*cosd(bank)*cosd(incl) ;
    Wy = -M*g*sind(bank) ;
    Wx = M*g*sind(incl) ;
    Aero_Df = 1/2*veh.rho*veh.factor_Cl*veh.Cl*veh.A*v^2 ;
    Aero_Dr = -1/2*veh.rho*veh.factor_Cd*veh.Cd*veh.A*v^2 ; % Cd now positive (see Vehicle.m); leading '-' keeps this negative
    Roll_Dr = -veh.Cr*(-Aero_Df+Wz) ; % Cr now positive too
    Wd = (factor_drive*Wz+(-factor_aero*Aero_Df))/driven_wheels ;

    %% overshoot acceleration
    ax_max = mode*(v_max_next^2-v^2)/2/dx ;
    ax_drag = (Aero_Dr+Roll_Dr+Wx)/M ;
    ax_needed = ax_max-ax_drag ;

    %% current lat acc
    ay = v^2*r+g*sind(bank) ;

    %% tyre forces
    dmy = factor_grip*veh.sens_y ;
    muy = factor_grip*veh.mu_y ;
    Ny = veh.mu_y_M*g ;
    dmx = factor_grip*veh.sens_x ;
    mux = factor_grip*veh.mu_x ;
    Nx = veh.mu_x_M*g ;
    if sign(ay)~=0 % in corner or compensating for banking
        ay_max = 1/M*(sign(ay)*open.maxAxleLimitedLateralForce(muy,dmy,Ny,Wz,Aero_Df,veh.df,veh.da)+Wy) ;
        if abs(ay/ay_max)>1 % checking if vehicle overshot (should not happen, but check exists to exclude complex numbers in solution from friction ellipse)
            ellipse_multi = 0 ;
        else
            ellipse_multi = sqrt(1-(ay/ay_max)^2) ; % friction ellipse
        end
    else % in straight or no compensation for banking needed
        ellipse_multi = 1 ;
    end

    %% calculating driver inputs
    if ax_needed>=0 % need tps
        ax_tyre_max = 1/M*(mux+dmx*(Nx-Wd))*Wd*driven_wheels ;
        ax_tyre = ax_tyre_max*ellipse_multi ;
        enginePower = veh.enginePowerLimitInterp(v) ; % NaN outside veh.vehicle_speed's range
        if isnan(enginePower)
            enginePower = 0 ; % outside the engine's speed range: no power available
        end
        ax_power_limit = 1/M*enginePower ;
        scale = min([ax_tyre,ax_needed]/ax_power_limit) ;
        tps = max([min([1,scale]),0]) ; % making sure its positive
        bps = 0 ; % setting brake pressure to 0
        ax_com = tps*ax_power_limit ;
    else % need braking
        ax_tyre_max = -1/M*(mux+dmx*(Nx-(Wz-Aero_Df)/4))*(Wz-Aero_Df) ;
        ax_tyre = ax_tyre_max*ellipse_multi ;
        fx_tyre = min(-[ax_tyre,ax_needed])*M ;
        bps = max([fx_tyre,0])*veh.beta ; % making sure its positive
        tps = 0 ; % seting throttle to 0
        ax_com = -min(-[ax_tyre,ax_needed]) ;
    end

    %% final results
    ax = ax_com+ax_drag ;
    v_next = sqrt(v^2+2*mode*ax*tr.dx(j)) ;
    if tps>0 && v/veh.v_max>=0.999
        tps = 1 ;
    end

    %% checking for overshoot
    if v_next/v_max_next>1
        overshoot = true ;
        v_next = inf ;
        ax = 0 ;
        ay = 0 ;
        tps = -1 ;
        bps = -1 ;
        return
    end
end
