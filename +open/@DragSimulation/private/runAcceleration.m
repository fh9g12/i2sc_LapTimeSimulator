function result = runAcceleration(vp, dt, t_max, ax_sens, speed_trap)
    % Straight-line acceleration phase: full throttle from a standing
    % start, shifting up through the gears, until the engine speed limit
    % or a drag-limited top speed is reached.

    N = t_max/dt ;
    T = -ones(N,1) ;
    X = -ones(N,1) ;
    V = -ones(N,1) ;
    A = -ones(N,1) ;
    RPM = -ones(N,1) ;
    TPS = -ones(N,1) ;
    BPS = -ones(N,1) ;
    GEAR = -ones(N,1) ;
    MODE = -ones(N,1) ;
    % initial time
    t = 0 ;
    t_start = 0 ;
    % initial distance
    x = 0 ;
    x_start = 0 ;
    % initial velocity
    v = 0 ;
    % initial acceleration
    a = 0 ;
    % initial gears
    gear = 1 ;
    gear_prev = 1 ;
    % shifting condition
    shifting = false ;
    % initial rpm
    rpm = 0 ;
    % initial tps
    tps = 0 ;
    % initial trap number
    trap_number = 1 ;
    % speed trap checking condition
    check_speed_traps = true ;
    % iteration number
    i = 1 ;

    disp('Acceleration simulation started:')
    disp(['Initial Speed: ',num2str(v*3.6),' km/h'])
    disp('|_______Comment________|_Speed_|_Accel_|_EnRPM_|_Gear__|_Tabs__|_Xabs__|_Trel__|_Xrel_|')
    disp('|______________________|[km/h]_|__[G]__|_[rpm]_|__[#]__|__[s]__|__[m]__|__[s]__|_[m]__|')

    acceleration_timer = tic ;
    while true
        % saving values
        MODE(i) = 1 ;
        T(i) = t ;
        X(i) = x ;
        V(i) = v ;
        A(i) = a ;
        RPM(i) = rpm ;
        TPS(i) = tps ;
        BPS(i) = 0 ;
        GEAR(i) = gear ;
        % checking if rpm limiter is on or if out of memory
        if v>=vp.v_max
            fprintf('Engine speed limited\t')
            hud(v,a,rpm,gear,t,x,t_start,x_start)
            break
        elseif i==N
            disp(['Did not reach maximum speed at time ',num2str(t),' s'])
            break
        end
        % check if drag limited (ax/ax_drag are from the previous
        % iteration; harmless on i==1 since tps starts at 0)
        if tps==1 && ax+ax_drag<=ax_sens
            fprintf('Drag limited        \t')
            hud(v,a,rpm,gear,t,x,t_start,x_start)
            break
        end
        % checking speed trap
        if check_speed_traps
            if v>=speed_trap(trap_number)
                fprintf('%s%3d %3d%s ','Speed Trap #',trap_number,round(speed_trap(trap_number)*3.6),'km/h')
                hud(v,a,rpm,gear,t,x,t_start,x_start)
                trap_number = trap_number+1 ;
                if trap_number>length(speed_trap)
                    check_speed_traps = false ;
                end
            end
        end
        % aero forces
        Aero_Df = 1/2*vp.rho*vp.factor_Cl*vp.Cl*vp.A*v^2 ;
        Aero_Dr = -1/2*vp.rho*vp.factor_Cd*vp.Cd*vp.A*v^2 ; % Cd now positive (see Vehicle.m); leading '-' keeps this negative
        % rolling resistance
        Roll_Dr = -vp.Cr*(-Aero_Df+vp.Wz) ; % Cr now positive too
        % normal load on driven wheels
        Wd = (vp.factor_drive*vp.Wz+(-vp.factor_aero*Aero_Df))/vp.driven_wheels ;
        % drag acceleration
        ax_drag = (Aero_Dr+Roll_Dr+vp.Wx)/vp.M ;
        % rpm calculation
        if gear==0 % shifting gears
            rpm = vp.rf*vp.rg(gear_prev)*vp.rp*v/vp.Rt*60/2/pi ;
            rpm_shift = vp.shift_points(gear_prev) ;
        else % gear change finished
            rpm = vp.rf*vp.rg(gear)*vp.rp*v/vp.Rt*60/2/pi ;
            rpm_shift = vp.shift_points(gear) ;
        end
        % checking for gearshifts
        if rpm>=rpm_shift && ~shifting % need to change gears
            if gear==vp.nog % maximum gear number
                fprintf('Engine speed limited\t')
                hud(v,a,rpm,gear,t,x,t_start,x_start)
                break
            else % higher gear available
                shifting = true ;
                t_shift = t ;
                ax = 0 ;
                gear_prev = gear ;
                gear = 0 ; % neutral for duration of gearshift
            end
        elseif shifting % currently shifting gears
            ax = 0 ;
            if t-t_shift>vp.shift_time
                fprintf('%s%2d\t','Shifting to gear #',gear_prev+1)
                hud(v,a,rpm,gear_prev+1,t,x,t_start,x_start)
                shifting = false ;
                gear = gear_prev+1 ;
            end
        else % no gearshift
            ax_tyre_max_acc = 1/vp.M*(vp.mux+vp.dmx*(vp.Nx-Wd))*Wd*vp.driven_wheels ;
            engine_torque = interp1(vp.rpm_curve,vp.torque_curve,rpm) ;
            wheel_torque = engine_torque*vp.rf*vp.rg(gear)*vp.rp*vp.nf*vp.ng*vp.np ;
            ax_power_limit = 1/vp.M*wheel_torque/vp.Rt ;
            ax = min([ax_power_limit,ax_tyre_max_acc]) ;
        end
        % tps
        tps = ax/ax_power_limit ;
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
    result.i_end = i ;
    a_acc_ave = v/t ;
    disp(['Average acceleration:    ',num2str(a_acc_ave/9.81,'%6.3f'),' [G]'])
    disp(['Peak acceleration   :    ',num2str(max(A)/9.81,'%6.3f'),' [G]'])
    toc(acceleration_timer)

    result.T = T ;
    result.X = X ;
    result.V = V ;
    result.A = A ;
    result.RPM = RPM ;
    result.TPS = TPS ;
    result.BPS = BPS ;
    result.GEAR = GEAR ;
    result.MODE = MODE ;
    result.accel_avg_g = a_acc_ave/9.81 ;
    result.accel_peak_g = max(A)/9.81 ;
    % final state, to seed the deceleration phase
    result.finalState = struct('t',t,'x',x,'v',v,'a',a,'gear',gear,'rpm',rpm,'i',i) ;
end
