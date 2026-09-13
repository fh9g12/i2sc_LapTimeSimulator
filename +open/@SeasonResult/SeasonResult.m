classdef SeasonResult
    % SeasonResult - lap times for one car/team setup across a set of
    % tracks (built by runSeason2025).
    %
    % Build one from runSeason2025, then persist it with
    % saveToMat/loadFromMat (primary, lossless) or saveToJSON/fromJSON
    % (secondary, human-readable) so results from different sessions can
    % be combined later with the static method comparePositions.

    properties
        teamName    % name of this car/team setup
        track       % string array of track names, one per race
        file        % string array of source track .mat filenames
        laptime     % lap time per race [s]
        sectorTimes % cell array of per-sector time vectors [s], one per race
    end

    methods
        function obj = SeasonResult(params)
            arguments
                params (1,1) struct = struct()
            end
            fields = fieldnames(params) ;
            for k = 1:numel(fields)
                obj.(fields{k}) = params.(fields{k}) ;
            end
        end
    end

    % These are Static methods (non-default attribute), so their
    % signatures must be declared here; the bodies live in their own
    % files elsewhere in this class folder.
    methods (Static)
        obj = fromStruct(s)
        obj = loadFromMat(filepath)
        obj = fromJSON(filepath)
        [positionTable, lapTimeTable, fig] = comparePositions(teams)
    end

    % toStruct, saveToMat and saveToJSON are ordinary public instance
    % methods (default attributes), so MATLAB discovers their separate
    % files in this class folder without needing a signature declared
    % here.
end
