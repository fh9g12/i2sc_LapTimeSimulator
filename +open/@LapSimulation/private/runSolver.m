function sim = runSolver(veh, tr)
    % The OpenLAP velocity-profile solver: finds the maximum speed at
    % every track point under pure cornering, then works forwards
    % (accelerating) and backwards (braking) from every apex until the
    % whole lap is covered, then post-processes the result into named,
    % unit-tagged channels.

    %% initialisation
    timer_solver_start = tic ;
    disp('Simulation started.')

    %% maximum speed curve (assuming pure lateral condition)
    v_max = single(zeros(tr.n,1)) ;
    bps_v_max = single(zeros(tr.n,1)) ;
    tps_v_max = single(zeros(tr.n,1)) ;
    for i=1:tr.n
        [v_max(i),tps_v_max(i),bps_v_max(i)] = vehicleModelLat(veh,tr,i) ;
    end
    disp('Maximum speed calculated at all points.')

    %% finding apexes
    [v_apex,apex] = findpeaks(-v_max) ; % findpeaks works for maxima, so need to flip values
    v_apex = -v_apex ; % flipping to get positive values
    % setting up standing start for open track configuration
    if strcmp(tr.info.config,'Open')
        if apex(1)~=1 % if index 1 is not already an apex
            apex = [1;apex] ; % inject index 1 as apex
            v_apex = [0;v_apex] ; % inject standing start
        else % index 1 is already an apex
            v_apex(1) = 0 ; % set standing start at index 1
        end
    end
    % checking if no apexes found and adding one if needed
    if isempty(apex)
        [v_apex,apex] = min(v_max) ;
    end
    % reordering apexes for solver time optimisation
    apex_table = sortrows([v_apex,apex],1) ;
    v_apex = apex_table(:,1) ;
    apex = apex_table(:,2) ;
    % getting driver inputs at apexes
    tps_apex = tps_v_max(apex) ;
    bps_apex = bps_v_max(apex) ;
    disp('Found all apexes on track.')

    %% simulation
    N = uint32((length(apex))) ; % number of apexes
    flag = false(tr.n,2) ; % flag for checking that speed has been correctly evaluated
    % 1st matrix dimension equal to number of points in track mesh
    % 2nd matrix dimension equal to number of apexes
    % 3rd matrix dimension equal to 2 if needed (1 copy for acceleration and 1 for deceleration)
    v = single(inf*ones(tr.n,N,2)) ;
    ax = single(zeros(tr.n,N,2)) ;
    ay = single(zeros(tr.n,N,2)) ;
    tps = single(zeros(tr.n,N,2)) ;
    bps = single(zeros(tr.n,N,2)) ;

    disp('Starting acceleration and deceleration.')
    prg_size = 30 ;
    fprintf(['Running: [',repmat(' ',1,prg_size),'] '])
    fprintf('% 3.0f',0)
    fprintf(' [%%]')

    % running simulation
    for i=1:N % apex number
        for k=uint8(1:2) % mode number
            switch k
                case 1 % acceleration
                    mode = 1 ;
                    k_rest = 2 ;
                case 2 % deceleration
                    mode = -1 ;
                    k_rest = 1 ;
            end
            if ~(strcmp(tr.info.config,'Open') && mode==-1 && i==1) % does not run in decel mode at standing start in open track
                % getting other apex for later checking
                [i_rest] = otherPoints(i,N) ;
                if isempty(i_rest)
                    i_rest = i ;
                end
                % getting apex index
                j = uint32(apex(i)) ;
                % saving speed & latacc & driver inputs from presolved apex
                v(j,i,k) = v_apex(i) ;
                ay(j,i,k) = v_apex(i)^2*tr.r(j) ;
                tps(j,:,1) = tps_apex(i)*ones(1,N) ;
                bps(j,:,1) = bps_apex(i)*ones(1,N) ;
                tps(j,:,2) = tps_apex(i)*ones(1,N) ;
                bps(j,:,2) = bps_apex(i)*ones(1,N) ;
                % setting apex flag
                flag(j,k) = true ;
                % getting next point index
                [~,j_next] = nextPoint(j,tr.n,mode,tr.info.config) ;
                if ~(strcmp(tr.info.config,'Open') && mode==1 && i==1) % if not in standing start
                    % assuming same speed right after apex
                    v(j_next,i,k) = v(j,i,k) ;
                    % moving to next point index
                    [j_next,j] = nextPoint(j,tr.n,mode,tr.info.config) ;
                end
                while 1
                    % calculating speed, accelerations and driver inputs from vehicle model
                    [v(j_next,i,k),ax(j,i,k),ay(j,i,k),tps(j,i,k),bps(j,i,k),overshoot] = vehicleModelComb(veh,tr,v(j,i,k),v_max(j_next),j,mode) ;
                    % checking for limit
                    if overshoot
                        break
                    end
                    % checking if point is already solved in other apex iteration
                    if flag(j,k) || flag(j,k_rest)
                        if max(v(j_next,i,k)>=v(j_next,i_rest,k)) || max(v(j_next,i,k)>v(j_next,i_rest,k_rest))
                            break
                        end
                    end
                    % updating flag and progress bar
                    flag = flagUpdate(flag,j,k,prg_size) ;
                    % moving to next point index
                    [j_next,j] = nextPoint(j,tr.n,mode,tr.info.config) ;
                    % checking if lap is completed
                    switch tr.info.config
                        case 'Closed'
                            if j==apex(i) % made it to the same apex
                                break
                            end
                        case 'Open'
                            if j==tr.n % made it to the end
                                flag = flagUpdate(flag,j,k,prg_size) ;
                                break
                            end
                            if j==1 % made it to the start
                                break
                            end
                    end
                end
            end
        end
    end

    progressBar(max(flag,[],2),prg_size) ;
    fprintf('\n')
    disp('Velocity profile calculated.')
    disp(['Solver time is: ',num2str(toc(timer_solver_start)),' [s]']) ;
    disp('Post-processing initialised.')

    %% post-processing results

    % result preallocation
    V = zeros(tr.n,1) ;
    AX = zeros(tr.n,1) ;
    AY = zeros(tr.n,1) ;
    TPS = zeros(tr.n,1) ;
    BPS = zeros(tr.n,1) ;
    % solution selection
    for i=1:tr.n
        IDX = length(v(i,:,1)) ;
        [V(i),idx] = min([v(i,:,1),v(i,:,2)]) ; % order of k in v(i,:,k) inside min() must be the same as mode order to not miss correct values
        if idx<=IDX % solved in acceleration
            AX(i) = ax(i,idx,1) ;
            AY(i) = ay(i,idx,1) ;
            TPS(i) = tps(i,idx,1) ;
            BPS(i) = bps(i,idx,1) ;
        else % solved in deceleration
            AX(i) = ax(i,idx-IDX,2) ;
            AY(i) = ay(i,idx-IDX,2) ;
            TPS(i) = tps(i,idx-IDX,2) ;
            BPS(i) = bps(i,idx-IDX,2) ;
        end
    end
    disp('Correct solution selected from modes.')

    % laptime calculation
    if strcmp(tr.info.config,'Open')
        time = cumsum([tr.dx(2)./V(2);tr.dx(2:end)./V(2:end)]) ;
    else
        time = cumsum(tr.dx./V) ;
    end
    sector_time = zeros(max(tr.sector),1) ;
    for i=1:max(tr.sector)
        sector_time(i) = max(time(tr.sector==i))-min(time(tr.sector==i)) ;
    end
    laptime = time(end) ;
    disp('Laptime calculated.')

    % calculating forces
    M = veh.M ;
    g = 9.81 ;
    A = sqrt(AX.^2+AY.^2) ;
    Fz_mass = -M*g*cosd(tr.bank).*cosd(tr.incl) ;
    Fz_aero = 1/2*veh.rho*veh.factor_Cl*veh.Cl*veh.A*V.^2 ;
    Fz_total = Fz_mass+Fz_aero ;
    Fx_aero = -1/2*veh.rho*veh.factor_Cd*veh.Cd*veh.A*V.^2 ; % Cd now positive (see Vehicle.m); leading '-' keeps this negative
    Fx_roll = -veh.Cr*abs(Fz_total) ; % Cr now positive too
    disp('Forces calculated.')

    % calculating yaw motion, vehicle slip angle and steering input
    yaw_rate = V.*tr.r ;
    delta = zeros(tr.n,1) ;
    beta = zeros(tr.n,1) ;
    for i=1:tr.n
        B = [M*V(i)^2*tr.r(i)+M*g*sind(tr.bank(i));0] ;
        sol = veh.C\B ;
        delta(i) = sol(1)+atand(veh.L*tr.r(i)) ;
        beta(i) = sol(2) ;
    end
    steer = delta*veh.rack ;
    disp('Yaw motion calculated.')
    disp('Steering angles calculated.')
    disp('Vehicle slip angles calculated.')

    % calculating engine metrics
    wheel_torque = TPS.*interp1(veh.vehicle_speed,veh.wheel_torque,V,'linear','extrap') ;
    Fx_eng = wheel_torque/veh.tyre_radius ;
    engine_torque = TPS.*interp1(veh.vehicle_speed,veh.engine_torque,V,'linear','extrap') ;
    engine_power = TPS.*interp1(veh.vehicle_speed,veh.engine_power,V,'linear','extrap') ;
    engine_speed = interp1(veh.vehicle_speed,veh.engine_speed,V,'linear','extrap') ;
    gear = interp1(veh.vehicle_speed,veh.gear,V,'nearest','extrap') ;
    fuel_cons = cumsum(wheel_torque/veh.tyre_radius.*tr.dx/veh.n_primary/veh.n_gearbox/veh.n_final/veh.n_thermal/veh.fuel_LHV) ;
    fuel_cons_total = fuel_cons(end) ;
    disp('Engine metrics calculated.')

    % calculating kpis
    percent_in_corners = sum(tr.r~=0)/tr.n*100 ;
    percent_in_accel = sum(TPS>0)/tr.n*100 ;
    percent_in_decel = sum(BPS>0)/tr.n*100 ;
    percent_in_coast = sum(and(BPS==0,TPS==0))/tr.n*100 ;
    percent_in_full_tps = sum(tps==1)/tr.n*100 ;
    percent_in_gear = zeros(veh.nog,1) ;
    for i=1:veh.nog
        percent_in_gear(i) = sum(gear==i)/tr.n*100 ;
    end
    energy_spent_fuel = fuel_cons*veh.fuel_LHV ;
    energy_spent_mech = energy_spent_fuel*veh.n_thermal ;
    gear_shifts = sum(abs(diff(gear))) ;
    [~,i] = max(abs(AY)) ;
    ay_max = AY(i) ;
    ax_max = max(AX) ;
    ax_min = min(AX) ;
    sector_v_max = zeros(max(tr.sector),1) ;
    sector_v_min = zeros(max(tr.sector),1) ;
    for i=1:max(tr.sector)
        sector_v_max(i) = max(V(tr.sector==i)) ;
        sector_v_min(i) = min(V(tr.sector==i)) ;
    end
    disp('KPIs calculated.')
    disp('Post-processing finished.')

    %% saving results in sim structure
    sim.distance.data = tr.x ;
    sim.distance.unit = 'm' ;
    sim.time.data = time ;
    sim.time.unit = 's' ;
    sim.N.data = N ;
    sim.N.unit = [] ;
    sim.apex.data = apex ;
    sim.apex.unit = [] ;
    sim.speed_max.data = v_max ;
    sim.speed_max.unit = 'm/s' ;
    sim.flag.data = flag ;
    sim.flag.unit = [] ;
    sim.v.data = v ;
    sim.v.unit = 'm/s' ;
    sim.Ax.data = ax ;
    sim.Ax.unit = 'm/s/s' ;
    sim.Ay.data = ay ;
    sim.Ay.unit = 'm/s/s' ;
    sim.tps.data = tps ;
    sim.tps.unit = [] ;
    sim.bps.data = bps ;
    sim.bps.unit = [] ;
    sim.elevation.data = tr.Z ;
    sim.elevation.unit = 'm' ;
    sim.speed.data = V ;
    sim.speed.unit = 'm/s' ;
    sim.yaw_rate.data = yaw_rate ;
    sim.yaw_rate.unit = 'rad/s' ;
    sim.long_acc.data = AX ;
    sim.long_acc.unit = 'm/s/s' ;
    sim.lat_acc.data = AY ;
    sim.lat_acc.unit = 'm/s/s' ;
    sim.sum_acc.data = A ;
    sim.sum_acc.unit = 'm/s/s' ;
    sim.throttle.data = TPS ;
    sim.throttle.unit = 'ratio' ;
    sim.brake_pres.data = BPS ;
    sim.brake_pres.unit = 'Pa' ;
    sim.brake_force.data = BPS*veh.phi ;
    sim.brake_force.unit = 'N' ;
    sim.steering.data = steer ;
    sim.steering.unit = 'deg' ;
    sim.delta.data = delta ;
    sim.delta.unit = 'deg' ;
    sim.beta.data = beta ;
    sim.beta.unit = 'deg' ;
    sim.Fz_aero.data = Fz_aero ;
    sim.Fz_aero.unit = 'N' ;
    sim.Fx_aero.data = Fx_aero ;
    sim.Fx_aero.unit = 'N' ;
    sim.Fx_eng.data = Fx_eng ;
    sim.Fx_eng.unit = 'N' ;
    sim.Fx_roll.data = Fx_roll ;
    sim.Fx_roll.unit = 'N' ;
    sim.Fz_mass.data = Fz_mass ;
    sim.Fz_mass.unit = 'N' ;
    sim.Fz_total.data = Fz_total ;
    sim.Fz_total.unit = 'N' ;
    sim.wheel_torque.data = wheel_torque ;
    sim.wheel_torque.unit = 'N.m' ;
    sim.engine_torque.data = engine_torque ;
    sim.engine_torque.unit = 'N.m' ;
    sim.engine_power.data = engine_power ;
    sim.engine_power.unit = 'W' ;
    sim.engine_speed.data = engine_speed ;
    sim.engine_speed.unit = 'rpm' ;
    sim.gear.data = gear ;
    sim.gear.unit = [] ;
    sim.fuel_cons.data = fuel_cons ;
    sim.fuel_cons.unit = 'kg' ;
    sim.fuel_cons_total.data = fuel_cons_total ;
    sim.fuel_cons_total.unit = 'kg' ;
    sim.laptime.data = laptime ;
    sim.laptime.unit = 's' ;
    sim.sector_time.data = sector_time ;
    sim.sector_time.unit = 's' ;
    sim.percent_in_corners.data = percent_in_corners ;
    sim.percent_in_corners.unit = '%' ;
    sim.percent_in_accel.data = percent_in_accel ;
    sim.percent_in_accel.unit = '%' ;
    sim.percent_in_decel.data = percent_in_decel ;
    sim.percent_in_decel.unit = '%' ;
    sim.percent_in_coast.data = percent_in_coast ;
    sim.percent_in_coast.unit = '%' ;
    sim.percent_in_full_tps.data = percent_in_full_tps ;
    sim.percent_in_full_tps.unit = '%' ;
    sim.percent_in_gear.data = percent_in_gear ;
    sim.percent_in_gear.unit = '%' ;
    sim.v_min.data = min(V) ;
    sim.v_min.unit = 'm/s' ;
    sim.v_max.data = max(V) ;
    sim.v_max.unit = 'm/s' ;
    sim.v_ave.data = mean(V) ;
    sim.v_ave.unit = 'm/s' ;
    sim.energy_spent_fuel.data = energy_spent_fuel ;
    sim.energy_spent_fuel.unit = 'J' ;
    sim.energy_spent_mech.data = energy_spent_mech ;
    sim.energy_spent_mech.unit = 'J' ;
    sim.gear_shifts.data = gear_shifts ;
    sim.gear_shifts.unit = [] ;
    sim.lat_acc_max.data = ay_max ;
    sim.lat_acc_max.unit = 'm/s/s' ;
    sim.long_acc_max.data = ax_max ;
    sim.long_acc_max.unit = 'm/s/s' ;
    sim.long_acc_min.data = ax_min ;
    sim.long_acc_min.unit = 'm/s/s' ;
    sim.sector_v_max.data = sector_v_max ;
    sim.sector_v_max.unit = 'm/s' ;
    sim.sector_v_min.data = sector_v_min ;
    sim.sector_v_min.unit = 'm/s' ;
    disp('Simulation results saved.')
    disp('Simulation completed.')
end
