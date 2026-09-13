function result = runDeceleration(vp, dt, speed_trap, prevResult)
    % Straight-line braking phase, continuing on from where
    % runAcceleration left off (same time/distance arrays and budget, as
    % in the original single-loop OpenDRAG script).

    T = prevResult.T ;
    X = prevResult.X ;
    V = prevResult.V ;
    A = prevResult.A ;
    RPM = prevResult.RPM ;
    TPS = prevResult.TPS ;
    BPS = prevResult.BPS ;
    GEAR = prevResult.GEAR ;
    MODE = prevResult.MODE ;
    N = length(T) ;

    fs = prevResult.finalState ;
    t = fs.t ;
    x = fs.x ;
    v = fs.v ;
    a = fs.a ;
    gear = fs.gear ;
    rpm = fs.rpm ;
    i = fs.i ;
    i_acc = i ;

    t_start = t ;
    x_start = x ;
    check_speed_traps = true ;
    speed_trap_decel = speed_trap(speed_trap<=v) ;
    trap_number = length(speed_trap_decel) ;
    bps = 0 ;

    disp('===============================================================================')
    disp('Deceleration simulation started:')
    disp(['Initial Speed: ',num2str(v*3.6),' [km/h]'])
    disp('|_______Comment________|_Speed_|_Accel_|_EnRPM_|_Gear__|_Tabs__|_Xabs__|_Trel__|_Xrel_|')
    disp('|______________________|[km/h]_|__[G]__|_[rpm]_|__[#]__|__[s]__|__[m]__|__[s]__|_[m]__|')

    deceleration_timer = tic ;
    while true
        MODE(i) = 2 ;
        T(i) = t ;
        X(i) = x ;
        V(i) = v ;
        A(i) = a ;
        RPM(i) = rpm ;
        TPS(i) = 0 ;
        BPS(i) = bps ;
        GEAR(i) = gear ;
        % checking if stopped or if out of memory
        if v<=0
            v = 0 ;
            fprintf('Stopped             \t')
            hud(v,a,rpm,gear,t,x,t_start,x_start)
            break
        elseif i==N
            disp(['Did not stop at time ',num2str(t),' s'])
            break
        end
        % checking speed trap
        if check_speed_traps
            if v<=speed_trap_decel(trap_number)
                fprintf('%s%3d %3d%s ','Speed Trap #',trap_number,round(speed_trap(trap_number)*3.6),'km/h')
                hud(v,a,rpm,gear,t,x,t_start,x_start)
                trap_number = trap_number-1 ;
                if trap_number<1
                    check_speed_traps = false ;
                end
            end
        end
        % aero forces
        Aero_Df = 1/2*vp.rho*vp.factor_Cl*vp.Cl*vp.A*v^2 ;
        Aero_Dr = -1/2*vp.rho*vp.factor_Cd*vp.Cd*vp.A*v^2 ; % Cd now positive (see Vehicle.m); leading '-' keeps this negative
        % rolling resistance
        Roll_Dr = -vp.Cr*(-Aero_Df+vp.Wz) ; % Cr now positive too
        % drag acceleration
        ax_drag = (Aero_Dr+Roll_Dr+vp.Wx)/vp.M ;
        % gear & rpm from vehicle model
        gear = interp1(vp.vehicle_speed,vp.gear_curve,v) ;
        rpm = interp1(vp.vehicle_speed,vp.engine_speed_curve,v) ;
        % max long dec available from tyres
        ax_tyre_max_dec = -1/vp.M*(vp.mux+vp.dmx*(vp.Nx-(vp.Wz-Aero_Df)/4))*(vp.Wz-Aero_Df) ;
        ax = ax_tyre_max_dec ;
        % brake pressure
        bps = -vp.beta*vp.M*ax ;
        % longitudinal acceleration
        a = ax+ax_drag ;
        % new position
        x = x+v*dt+1/2*a*dt^2 ;
        % new velocity
        v = v+a*dt ;
        % new time
        t = t+dt ;
        % next iteration
        i = i+1 ;
    end
    a_dec_ave = V(i_acc)/(t-t_start) ;
    disp(['Average deceleration:    ',num2str(a_dec_ave/9.81,'%6.3f'),' [G]'])
    disp(['Peak deceleration   :    ',num2str(-min(A)/9.81,'%6.3f'),' [G]'])
    toc(deceleration_timer)

    result.T = T ;
    result.X = X ;
    result.V = V ;
    result.A = A ;
    result.RPM = RPM ;
    result.TPS = TPS ;
    result.BPS = BPS ;
    result.GEAR = GEAR ;
    result.MODE = MODE ;
    result.decel_avg_g = a_dec_ave/9.81 ;
    result.decel_peak_g = -min(A)/9.81 ;
end
