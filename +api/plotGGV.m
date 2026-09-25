function fig = plotGGV(Cl,Cd,AeroBalance,GearRatioScale,options)
% plotGGV - visualise a car's GGV map (its grip envelope: the maximum
% lateral/longitudinal acceleration it can sustain at every speed) for a
% given Cl/Cd/aero-balance/gear-ratio choice.
%
% api.plotGGV(Cl,Cd,AeroBalance,GearRatioScale)
%
% Same [Cl,Cd,AeroBalance] convention as api.simulate_race/
% api.runSeason2025 -- feed api.genCarAeroData's output straight in.
% To compare two parameter choices on one plot, use api.compareGGV
% instead.
%
% Name-value options: VehicleFile (default "data/cars/Formula_1_car.mat")
    arguments
        Cl (1,1) double
        Cd (1,1) double
        AeroBalance (1,1) double
        GearRatioScale (1,1) double {mustBePositive}
        options.VehicleFile (1,1) string = "data/cars/Formula_1_car.mat"
    end

    % ensure folder/file paths are relative to root of this package
    absPath = fullfile(fileparts(mfilename('fullpath')),'..');
    options.VehicleFile = fullfile(absPath, options.VehicleFile);

    veh = open.Vehicle.loadFromMat(options.VehicleFile) ;
    veh = veh.withAero('Cl',Cl,'Cd',Cd,'da',AeroBalance) ;
    veh = veh.withGearRatioScale(GearRatioScale) ;

    fig = open.plotGGV(veh) ;
end
