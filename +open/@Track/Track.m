classdef Track
    % Track - racing track model for use with OpenLAP.
    %
    % Build one with open.Track.FromShapeFile(filename) (an "OpenTRACK
    % Shape tmp.xlsx"-format Excel file) or open.Track.FromLoggedFile
    % (an "OpenTRACK Logged Data tmp.csv"-format telemetry file), then
    % persist it with saveToMat/loadFromMat (primary, lossless) or
    % saveToJSON/fromJSON (secondary, human-readable).

    properties
        info        % struct: name, country, city, type, config, direction, mirror

        x           % distance along track, fine mesh [m]
        dx          % mesh step size [m]
        n           % number of mesh points [-]
        r           % curvature [1/m]
        bank        % banking [deg]
        incl        % inclination [deg]
        factor_grip % grip factor [-]
        sector      % sector number at each mesh point [-]
        r_apex      % curvature at each apex [1/m]
        apex        % mesh point index of each apex [-]
        X           % track map X coordinate [m]
        Y           % track map Y coordinate [m]
        Z           % track map elevation [m]
        arrow       % finish line direction arrow, 3x[X,Y,Z] [m]
    end

    methods
        function obj = Track(params)
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
        obj = FromShapeFile(filename, options)
        obj = FromLoggedFile(filename, options)
        obj = fromStruct(s)
        obj = loadFromMat(filepath)
        obj = fromJSON(filepath)
    end

    % toStruct, saveToMat, saveToJSON, plotModel and printAsciiMap are
    % ordinary public instance methods (default attributes), so MATLAB
    % discovers their separate files in this class folder without
    % needing a signature declared here.
end
