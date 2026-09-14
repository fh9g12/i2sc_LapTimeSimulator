function fig = compareGGV(Cl1,Cd1,AeroBalance1,GearRatioScale1,Name1,Cl2,Cd2,AeroBalance2,GearRatioScale2,Name2,options)
% compareGGV - overlay two cars' GGV maps (grip envelopes) on the same
% axes, to see directly how a parameter choice changes the car's limit
% of grip at every speed.
%
% api.compareGGV(Cl1,Cd1,AeroBalance1,GearRatioScale1,'Car A', ...
%                Cl2,Cd2,AeroBalance2,GearRatioScale2,'Car B')
%
% Same [Cl,Cd,AeroBalance] convention as api.simulate_race/
% api.runSeason2025 for both cars. Name1/Name2 label the two surfaces in
% the legend (e.g. "high downforce" vs "low downforce", or your setup
% vs. a rival team's).
%
% Name-value options: VehicleFile (default "data/cars/Formula_1_car.mat")
    arguments
        Cl1 (1,1) double
        Cd1 (1,1) double
        AeroBalance1 (1,1) double
        GearRatioScale1 (1,1) double {mustBePositive}
        Name1 (1,1) string
        Cl2 (1,1) double
        Cd2 (1,1) double
        AeroBalance2 (1,1) double
        GearRatioScale2 (1,1) double {mustBePositive}
        Name2 (1,1) string
        options.VehicleFile (1,1) string = "data/cars/Formula_1_car.mat"
    end

    veh1 = open.Vehicle.loadFromMat(options.VehicleFile) ;
    veh1 = veh1.withAero('Cl',Cl1,'Cd',Cd1,'da',AeroBalance1) ;
    veh1 = veh1.withGearRatioScale(GearRatioScale1) ;

    veh2 = open.Vehicle.loadFromMat(options.VehicleFile) ;
    veh2 = veh2.withAero('Cl',Cl2,'Cd',Cd2,'da',AeroBalance2) ;
    veh2 = veh2.withGearRatioScale(GearRatioScale2) ;

    fig = figure('Name','GGV Map Comparison') ;
    ax = axes(fig) ; %#ok<LAXES>
    hold(ax,'on') ;
    title(ax,'GGV Map Comparison')
    xlabel(ax,'Lat acc [m/s^2]','Interpreter','none')
    ylabel(ax,'Long acc [m/s^2]','Interpreter','none')
    zlabel(ax,'Speed [m/s]','Interpreter','none')
    grid(ax,'on')
    view(ax,105,5)
    set(ax,'DataAspectRatio',[1 1 0.8])

    open.plotGGV(veh1,'ax',ax,'FaceColor',[0 0.4470 0.7410],'FaceAlpha',0.6,'DisplayName',Name1) ;
    open.plotGGV(veh2,'ax',ax,'FaceColor',[0.8500 0.3250 0.0980],'FaceAlpha',0.6,'DisplayName',Name2) ;
    legend(ax,'show','Location','best') ;
end
