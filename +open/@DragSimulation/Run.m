function obj = Run(veh, options)
    % DragSimulation.Run - run the acceleration + braking drag simulation
    % for a Vehicle.
    %
    % Name-value options:
    %   Dt        (default 1e-3)                          - time step [s]
    %   TMax      (default 60)                             - max sim time [s]
    %   AxSens    (default 0.05)                            - drag-limit sensitivity [m/s2]
    %   SpeedTrap (default [50 100 150 200 250 300 350]km/h) - speed trap targets [m/s]
    %   Bank      (default 0)                               - track bank angle [deg]
    %   Incl      (default 0)                               - track inclination [deg]
    arguments
        veh (1,1) open.Vehicle
        options.Dt (1,1) double = 1E-3
        options.TMax (1,1) double = 60
        options.AxSens (1,1) double = 0.05
        options.SpeedTrap (:,1) double = [50;100;150;200;250;300;350]/3.6
        options.Bank (1,1) double = 0
        options.Incl (1,1) double = 0
    end

    total_timer = tic ;

    printBanner(veh.name) ;

    vp = preprocessVehicleForDrag(veh, options.Bank, options.Incl) ;

    accelResult = runAcceleration(vp, options.Dt, options.TMax, options.AxSens, options.SpeedTrap) ;
    decelResult = runDeceleration(vp, options.Dt, options.SpeedTrap, accelResult) ;

    disp('===============================================================================')
    disp('Simulation completed successfully.')
    toc(total_timer)

    % results compression: dropping the unused preallocated tail
    T = decelResult.T ; X = decelResult.X ; V = decelResult.V ; A = decelResult.A ;
    RPM = decelResult.RPM ; TPS = decelResult.TPS ; BPS = decelResult.BPS ;
    GEAR = decelResult.GEAR ; MODE = decelResult.MODE ;
    to_delete = T==-1 ;
    T(to_delete) = [] ;
    X(to_delete) = [] ;
    V(to_delete) = [] ;
    A(to_delete) = [] ;
    RPM(to_delete) = [] ;
    TPS(to_delete) = [] ;
    BPS(to_delete) = [] ;
    GEAR(to_delete) = [] ;
    MODE(to_delete) = [] ;

    params.vehicleName = veh.name ;
    params.dt = options.Dt ;
    params.t_max = options.TMax ;
    params.ax_sens = options.AxSens ;
    params.speed_trap = options.SpeedTrap ;
    params.bank = options.Bank ;
    params.incl = options.Incl ;
    params.T = T ;
    params.X = X ;
    params.V = V ;
    params.A = A ;
    params.RPM = RPM ;
    params.TPS = TPS ;
    params.BPS = BPS ;
    params.GEAR = GEAR ;
    params.MODE = MODE ;
    params.accel_avg_g = accelResult.accel_avg_g ;
    params.accel_peak_g = accelResult.accel_peak_g ;
    params.decel_avg_g = decelResult.decel_avg_g ;
    params.decel_peak_g = decelResult.decel_peak_g ;

    obj = open.DragSimulation(params) ;
end
