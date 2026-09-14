function result = runSeason2025(Cl, Cd, AeroBalance, GearRatioScale, TeamName, options)
    % runSeason2025 - loads the Formula 1 vehicle, overrides its Cl, Cd,
    % aero balance and final drive ratio, then runs a lap simulation on
    % every 2025 track (as built by buildTracks2025.m) and returns the
    % lap/sector times as an open.SeasonResult for this car/team setup.
    %
    % result = runSeason2025(Cl, Cd, AeroBalance, GearRatioScale, TeamName)
    % runs with the given lift coefficient, drag coefficient, front aero
    % balance (a fraction 0-1, same convention as Vehicle.da), and final
    % drive ratio scale (see Vehicle.withGearRatioScale -- 1 = the
    % vehicle's original gearing, >1 shorter/more accel/lower top speed,
    % <1 taller/less accel/higher top speed) on the default vehicle and
    % 2025 tracks folder, labelling the result with TeamName.
    %
    % SIGN CONVENTION: Cl is NEGATIVE for downforce, Cd is POSITIVE (a
    % drag magnitude) -- the ordinary aerodynamics convention, and
    % exactly Vehicle.Cl/Cd's own (e.g. the baseline vehicle is Cl=-4.8,
    % Cd=1.2), so both are passed straight through with no sign flip.
    % Feed open.genCarAeroData's [CL,CD,aeroBalance] straight in here.
    %
    % Gearing is deliberately NOT optimised for you: pairing it with your
    % chosen Cd is part of the exercise. Vehicle.withOptimalGearing gives
    % the theoretical best answer, useful only as a reference to check
    % your own choice against.
    %
    % Name-value options:
    %   VehicleFile   (default "data/cars/Formula_1_car.mat")
    %   TracksFolder  (default "data/tracks/")
    %
    % A track that fails to load or simulate is skipped with a warning
    % rather than stopping the whole run. Save the result (result.saveToMat(...))
    % to compare it against other teams later with
    % open.SeasonResult.comparePositions.
    %
    % Each result also reports fuel burn (SeasonResult.fuelPerLap etc.)
    % for information only -- it plays no part in the lap times or in
    % comparePositions. fuelPerLap comes for free from the same lap
    % simulation already being run; estimatedRaceFuel_kg is a naive
    % fuelPerLap*raceLaps extrapolation that does NOT account for the
    % car getting lighter (and so burning slightly less per lap) as a
    % real race goes on. A full mass-corrected race simulation exists
    % (open.simulateFuelCorrectedRace) but costs ~10x a single lap per
    % track -- worth running yourself on individual cases, but not
    % worth paying for across a whole season sweep for the modest
    % effect it has on the optimum.
    arguments
        Cl (1,1) double
        Cd (1,1) double
        AeroBalance (1,1) double
        GearRatioScale (1,1) double {mustBePositive}
        TeamName (1,1) string
        options.VehicleFile (1,1) string = "data/cars/Formula_1_car.mat"
        options.TracksFolder (1,1) string = "data/tracks/"
    end

    veh = open.Vehicle.loadFromMat(options.VehicleFile) ;
    veh = veh.withAero('Cl',Cl,'Cd',Cd,'da',AeroBalance) ;
    veh = veh.withGearRatioScale(GearRatioScale) ;

    files = dir(fullfile(options.TracksFolder,'*.mat')) ;

    track = strings(0,1) ;
    file = strings(0,1) ;
    laptime = zeros(0,1) ;
    sectorTimes = {} ;

    for i = 1:numel(files)
        filepath = fullfile(files(i).folder,files(i).name) ;
        try
            tr = open.Track.loadFromMat(filepath) ;
            sim = open.LapSimulation.Run(veh, tr) ;

            track(end+1,1) = tr.info.name ; %#ok<AGROW>
            file(end+1,1) = string(files(i).name) ; %#ok<AGROW>
            laptime(end+1,1) = sim.laptime.data ; %#ok<AGROW>
            sectorTimes{end+1,1} = sim.sector_time.data ; %#ok<AGROW>
        catch ME
            warning(['Failed to simulate ',files(i).name,': ',ME.message])
        end
    end

    params.teamName = TeamName ;
    params.track = track ;
    params.file = file ;
    params.laptime = laptime ;
    params.sectorTimes = sectorTimes ;
    result = open.SeasonResult(params) ;

    disp('====================================================================')
    disp(TeamName+": "+numel(track)+" of "+numel(files)+" tracks simulated successfully.")
end
