function obj = Run(veh, tr)
    % LapSimulation.Run - run the OpenLAP velocity-profile solver for a
    % Vehicle around a Track, and print the resulting laptime/sector
    % times to the console.
    arguments
        veh (1,1) open.Vehicle
        tr (1,1) open.Track
    end
    util.Log.debug(sprintf('Start sim: %s, %s',tr.info.city,tr.info.country),'High');
    if util.Log.instance.level<util.LogLevel.Debug
        printBanner(veh.name, tr.info.name) ;
    end

    simStruct = runSolver(veh, tr) ;
    obj = open.LapSimulation(simStruct) ;

    util.Log.debug(sprintf('Sim Complete: %s, %s',tr.info.city,tr.info.country),'High');
    util.Log.debug(['Laptime:  ',num2str(obj.laptime.data,'%3.3f'),' [s]'],'Mid')

    for i=1:max(tr.sector)
        util.Log.trace(['Sector ',num2str(i),': ',num2str(obj.sector_time.data(i),'%3.3f'),' [s]'])
    end
end
