function result = official_evaluation(frontSection,frontAoA,rearSection,rearAoA,GearRatioScale,TeamName)
    % official_evaluation - turn a team's raw submitted parameters
    % (front/rear wing section + AoA, gear ratio scale) straight into a
    % season result, in one call: combines api.genCarAeroData with
    % api.runSeason2025 rather than repeating the season loop here, so the
    % two functions can't drift out of sync with each other.
    %
    % result = api.official_evaluation(frontSection,frontAoA,rearSection,rearAoA,GearRatioScale,TeamName)
    %
    % See api.genCarAeroData for the wing/AoA parameters and
    % api.runSeason2025 for GearRatioScale, TeamName and the returned
    % open.SeasonResult.
    arguments
        frontSection (1,1) string
        frontAoA (1,1) double
        rearSection (1,1) string
        rearAoA (1,1) double
        GearRatioScale (1,1) double {mustBePositive}
        TeamName (1,1) string
    end

    [Cl,Cd,AeroBalance] = api.genCarAeroData(frontSection,frontAoA,rearSection,rearAoA) ;
    if isnan(Cl)
        error('official_evaluation:invalidAero', ...
            '%s: chosen wing/AoA combination did not converge in XFoil.',TeamName) ;
    end

    result = api.runSeason2025(Cl,Cd,AeroBalance,GearRatioScale,TeamName) ;
end
