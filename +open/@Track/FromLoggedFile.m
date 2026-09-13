function obj = FromLoggedFile(filename, options)
    % Track.FromLoggedFile - build a Track from an "OpenTRACK Logged Data
    % tmp.csv"-format telemetry file (distance, speed, and either yaw
    % velocity or lateral acceleration, plus elevation/banking/grip/
    % sector channels).
    %
    % Name-value options:
    %   MeshSize (default 1)               - fine mesh spacing [m]
    %   Rotation (default 0)               - track map rotation [deg]
    %   FilterDt (default 0.1)             - smoothing filter duration [s]
    %   LogMode  (default "speed & latacc") - "speed & latacc" | "speed & yaw"
    %   Lambda   (default 1)               - curvature scale adjuster
    arguments
        filename
        options.MeshSize (1,1) double = 1
        options.Rotation (1,1) double = 0
        options.FilterDt (1,1) double = 0.1
        options.LogMode (1,1) string {mustBeMember(options.LogMode,["speed & latacc","speed & yaw"])} = "speed & latacc"
        options.Lambda (1,1) double = 1
    end

    [info,coarse] = loadLoggedTrackData(filename, options.FilterDt, char(options.LogMode), options.Lambda) ;

    printBanner(filename, 'File read successfully') ;

    obj = buildFromCoarseData(info, coarse, options.MeshSize, options.Rotation) ;
end
