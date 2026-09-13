classdef DragSimulation
    % DragSimulation - straight-line acceleration/braking simulation for
    % a Vehicle, using a simple point mass model (the OpenDRAG solver).
    %
    % Build one with open.DragSimulation.Run(veh), then persist it with
    % saveToMat/loadFromMat (primary, lossless) or saveToJSON/fromJSON
    % (secondary, human-readable).

    properties
        vehicleName % name of the simulated Vehicle

        % settings used for this run
        dt          % time step [s]
        t_max       % maximum simulation time (memory preallocation) [s]
        ax_sens     % acceleration sensitivity for drag limitation [m/s2]
        speed_trap  % speed trap targets [m/s]
        bank        % track bank angle [deg]
        incl        % track inclination [deg]

        % time series (acceleration phase followed by braking phase)
        T           % time [s]
        X           % distance [m]
        V           % speed [m/s]
        A           % longitudinal acceleration [m/s2]
        RPM         % engine speed [rpm]
        TPS         % throttle position [ratio]
        BPS         % brake pressure [Pa]
        GEAR        % selected gear [-]
        MODE        % 1 = acceleration, 2 = braking

        % summary metrics
        accel_avg_g % average acceleration [G]
        accel_peak_g % peak acceleration [G]
        decel_avg_g % average deceleration [G]
        decel_peak_g % peak deceleration [G]
    end

    methods
        function obj = DragSimulation(params)
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
        obj = Run(veh, options)
        obj = fromStruct(s)
        obj = loadFromMat(filepath)
        obj = fromJSON(filepath)
    end

    % toStruct, saveToMat, saveToJSON and plotModel are ordinary public
    % instance methods (default attributes), so MATLAB discovers their
    % separate files in this class folder without needing a signature
    % declared here.
end
