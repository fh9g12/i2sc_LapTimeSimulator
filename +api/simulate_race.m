function result = simulate_race(RaceName, Cl, Cd, AeroBalance, GearRatioScale, TeamName, options)
    % SIGN CONVENTION: Cl is NEGATIVE for downforce, Cd is POSITIVE (a
    % drag magnitude -- drag has no sign, it always opposes motion) --
    % the ordinary aerodynamics convention, and exactly Vehicle.Cl/Cd's
    % own (e.g. the baseline vehicle is Cl=-4.8, Cd=1.2), so both are
    % passed straight through with no sign flip. Matches
    % api.genCarAeroData's output exactly: feed its
    % [CL,CD,aeroBalance] straight in here as [Cl,Cd,AeroBalance].
    arguments
        RaceName (1,1) api.RaceNames
        Cl (1,1) double
        Cd (1,1) double
        AeroBalance (1,1) double
        GearRatioScale (1,1) double {mustBePositive}
        TeamName (1,1) string
        options.VehicleFile (1,1) string = "data/cars/Formula_1_car.mat"
        options.TracksFolder (1,1) string = "data/tracks/"
    end

    % ensure folder/file paths are relative to root of this package
    absPath = fullfile(fileparts(mfilename('fullpath')),'..');
    options.TracksFolder = fullfile(absPath, options.TracksFolder);
    options.VehicleFile = fullfile(absPath, options.VehicleFile);

    % load vehicle model and set custom paramters
    veh = open.Vehicle.loadFromMat(options.VehicleFile) ;
    veh = veh.withAero('Cl',Cl,'Cd',Cd,'da',AeroBalance) ;
    veh = veh.withGearRatioScale(GearRatioScale) ;

    file = [char(RaceName),'.mat'];
    filepath = fullfile(options.TracksFolder,file);

    try
        tr = open.Track.loadFromMat(filepath) ;
        sim = open.LapSimulation.Run(veh, tr) ;

        track = tr.info.name ;
        laptime = sim.laptime.data ;
        sectorTimes = sim.sector_time.data ;
        sim.plotModel(veh,tr);
    catch ME
        warning(['Failed to simulate ',char(RaceName),': ',ME.message])
    end

    params.teamName = TeamName ;
    params.track = track ;
    params.file = file ;
    params.laptime = laptime ;
    params.sectorTimes = sectorTimes ;
    result = open.SeasonResult(params) ;

    disp('====================================================================')
    disp(TeamName+": "+track + " simulated successfully.")
end