function obj = Run(veh, tr)
    % LapSimulation.Run - run the OpenLAP velocity-profile solver for a
    % Vehicle around a Track, and print the resulting laptime/sector
    % times to the console.
    arguments
        veh (1,1) open.Vehicle
        tr (1,1) open.Track
    end

    printBanner(veh.name, tr.info.name) ;

    simStruct = runSolver(veh, tr) ;
    obj = open.LapSimulation(simStruct) ;

    disp(['Laptime:  ',num2str(obj.laptime.data,'%3.3f'),' [s]'])
    for i=1:max(tr.sector)
        disp(['Sector ',num2str(i),': ',num2str(obj.sector_time.data(i),'%3.3f'),' [s]'])
    end
end
