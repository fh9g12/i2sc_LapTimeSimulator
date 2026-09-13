function [v, tps, bps] = vehicleModelLat(veh, tr, p)
    % Maximum speed achievable at track point p under pure lateral
    % (cornering) acceleration.

    %% initialisation
    g = 9.81 ;
    r = tr.r(p) ;
    incl = tr.incl(p) ;
    bank = tr.bank(p) ;
    factor_grip = tr.factor_grip(p)*veh.factor_grip ;
    factor_drive = veh.factor_drive ;
    factor_aero = veh.factor_aero ;
    driven_wheels = veh.driven_wheels ;
    M = veh.M ;
    Wz = M*g*cosd(bank)*cosd(incl) ;
    Wy = -M*g*sind(bank) ;
    Wx = M*g*sind(incl) ;

    %% speed solution
    if r==0 % straight (limited by engine speed limit or drag)
        v = veh.v_max ;
        tps = 1 ; % full throttle
        bps = 0 ; % 0 brake
    else % corner (may be limited by engine, drag or cornering ability)
        %% initial speed solution
        D = -1/2*veh.rho*veh.factor_Cl*veh.Cl*veh.A ;
        dmy = factor_grip*veh.sens_y ;
        muy = factor_grip*veh.mu_y ;
        Ny = veh.mu_y_M*g ;
        dmx = factor_grip*veh.sens_x ;
        mux = factor_grip*veh.mu_x ;
        Nx = veh.mu_x_M*g ;
        % two-axle (bicycle model) cornering speed: whichever axle's
        % moment-balance-required share of grip saturates first
        v = open.maxCorneringSpeed(M, r, Wy, Wz, D, veh.df, veh.da, muy, dmy, Ny, p) ;
        v = min([v,veh.v_max]) ;
        %% adjusting speed for drag force compensation
        adjust_speed = true ;
        while adjust_speed
            Aero_Df = 1/2*veh.rho*veh.factor_Cl*veh.Cl*veh.A*v^2 ;
            Aero_Dr = -1/2*veh.rho*veh.factor_Cd*veh.Cd*veh.A*v^2 ; % Cd now positive (see Vehicle.m); leading '-' keeps this negative
            Roll_Dr = -veh.Cr*(-Aero_Df+Wz) ; % Cr now positive too
            Wd = (factor_drive*Wz+(-factor_aero*Aero_Df))/driven_wheels ;
            ax_drag = (Aero_Dr+Roll_Dr+Wx)/M ;
            ay_max = sign(r)/M*open.maxAxleLimitedLateralForce(muy,dmy,Ny,Wz,Aero_Df,veh.df,veh.da) ;
            ay_needed = v^2*r+g*sind(bank) ; % circular motion and track banking
            if ax_drag<=0 % need throttle to compensate for drag
                ax_tyre_max_acc = 1/M*(mux+dmx*(Nx-Wd))*Wd*driven_wheels ;
                ax_power_limit = 1/M*veh.enginePowerLimitInterp(v) ;
                ay = ay_max*sqrt(1-(ax_drag/ax_tyre_max_acc)^2) ; % friction ellipse
                ax_acc = ax_tyre_max_acc*sqrt(1-(ay_needed/ay_max)^2) ; % friction ellipse
                scale = min([-ax_drag,ax_acc])/ax_power_limit ;
                tps = max([min([1,scale]),0]) ; % making sure its positive
                bps = 0 ; % setting brake pressure to 0
            else % need brake to compensate for drag
                ax_tyre_max_dec = -1/M*(mux+dmx*(Nx-(Wz-Aero_Df)/4))*(Wz-Aero_Df) ;
                ay = ay_max*sqrt(1-(ax_drag/ax_tyre_max_dec)^2) ; % friction ellipse
                ax_dec = ax_tyre_max_dec*sqrt(1-(ay_needed/ay_max)^2) ; % friction ellipse
                fx_tyre = max([ax_drag,-ax_dec])*M ;
                bps = max([fx_tyre,0])*veh.beta ; % making sure its positive
                tps = 0 ; % setting throttle to 0
            end
            if ay/ay_needed<1 % not enough grip
                v = sqrt((ay-g*sind(bank))/r)-1E-3 ; % the (-1E-3 factor is there for convergence speed)
            else % enough grip
                adjust_speed = false ;
            end
        end
    end
end
