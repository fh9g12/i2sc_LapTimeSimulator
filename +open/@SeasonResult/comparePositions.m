function [positionTable, lapTimeTable, fig] = comparePositions(teams)
    % SeasonResult.comparePositions - combines several teams' results
    % (one SeasonResult per car/team setup, typically from separate
    % runSeason2025 calls) into a race-by-race position comparison.
    %
    % [positionTable, lapTimeTable, fig] = open.SeasonResult.comparePositions(teams)
    %
    % teams is an array of open.SeasonResult, e.g. [redBull, ferrari].
    % Tracks are matched by name across teams; a team missing a track
    % gets NaN for that race rather than stopping the comparison.
    %
    % Returns:
    %   positionTable - table, one row per track, one column per team,
    %                   values are finishing position (1 = fastest).
    %   lapTimeTable  - the same layout, with raw lap times [s] instead.
    %   fig           - a heatmap figure of positionTable (rows = tracks,
    %                   columns = teams, cell text = position).
    arguments
        teams (1,:) open.SeasonResult
    end

    % union of track names across all teams, in first-seen order
    allTracks = strings(0,1) ;
    for i = 1:numel(teams)
        newTracks = setdiff(teams(i).track(:), allTracks, 'stable') ;
        allTracks = [allTracks; newTracks] ; %#ok<AGROW>
    end
    nTracks = numel(allTracks) ;
    nTeams = numel(teams) ;
    teamNames = strings(1,nTeams) ;
    for j = 1:nTeams
        teamNames(j) = teams(j).teamName ;
    end

    % lap time matrix, NaN where a team has no result for a track
    lapTimes = nan(nTracks,nTeams) ;
    for j = 1:nTeams
        for i = 1:nTracks
            idx = find(teams(j).track(:)==allTracks(i), 1) ;
            if ~isempty(idx)
                lapTimes(i,j) = teams(j).laptime(idx) ;
            end
        end
    end

    % race position per row: rank ascending (fastest = 1), NaNs excluded
    positions = nan(nTracks,nTeams) ;
    for i = 1:nTracks
        row = lapTimes(i,:) ;
        valid = find(~isnan(row)) ;
        [~,order] = sort(row(valid)) ;
        positions(i,valid(order)) = 1:numel(valid) ;
    end

    validNames = matlab.lang.makeValidName(cellstr(teamNames)) ;
    lapTimeTable = array2table(lapTimes, 'RowNames', cellstr(allTracks), 'VariableNames', validNames) ;
    positionTable = array2table(positions, 'RowNames', cellstr(allTracks), 'VariableNames', validNames) ;

    fig = figure('Name','Team Positions by Race') ;
    h = heatmap(cellstr(teamNames), cellstr(allTracks), positions) ;
    h.Title = 'Team Position by Race (1 = fastest)' ;
    h.XLabel = 'Team' ;
    h.YLabel = 'Track' ;
    h.Colormap = flipud(parula) ;
    h.MissingDataLabel = 'DNF/no data' ;
end
