function Fmax = axleLateralForceMax(muy, dmy, Ny, N)
    % axleLateralForceMax - maximum unsigned lateral force from one axle
    % (2 wheels), given its total normal load N, using OpenLAP's
    % load-sensitive tyre model (muy, dmy, Ny already scaled by the
    % track/vehicle grip factor, same convention as Vehicle.mu_y/
    % sens_y/mu_y_M). This is the per-axle (2-wheel) form of the same
    % formula the original whole-car (4-wheel) model used.
    Fmax = (muy+dmy*(Ny-N/2)).*N ;
end
