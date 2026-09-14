classdef RaceNames
    % RaceNames - enum of the 24 tracks on the 2025 season calendar, one
    % member per data/tracks/*.mat file. Pass a member to
    % api.simulate_race to run a single race, e.g. api.RaceNames.Monza.

    enumeration
        Austin
        Baku
        Catalunya
        Hungaroring
        Imola
        Interlagos
        Jeddah
        Las_Vegas
        Lusail
        Melbourne
        Mexico_City
        Miami
        Monte_Carlo
        Montreal
        Monza
        Sakhir
        Shanghai
        Silverstone
        Singapore
        Spa_Francorchamps
        Spielberg
        Suzuka
        Yas_Marina_Circuit
        Zandvoort
    end
end