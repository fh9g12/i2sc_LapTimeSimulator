clear all
util.Log.setLevel(util.LogLevel.Info)
%% ----- set parameters: design 1 -----
deltaCls = 0:-0.25:-3;
ABs = 0.4:0.025:0.55;
Etas = [0.9,1,1.1];

data = struct.empty;
%preallocate data
for k = 1:length(Etas)
    for i = 1:length(deltaCls)
        for j = 1:length(ABs)
            data(end+1).DeltaCL = deltaCls(i);
            data(end).AB = ABs(j);
            data(end).Eta = Etas(k);
            data(end).isComplete = false;
            data(end).CD = nan;
            data(end).LapTime = nan;
        end
    end
end
N = length(data);
%% complete analysis
util.Log.setLevel(util.LogLevel.Info,"Mid")

util.Log.info(sprintf('Completing %.0f Instances',N),'High')
parfor i = 1:N
    try
        util.Log.setLevel(util.LogLevel.Info,"Mid")
        util.Log.info(sprintf('Completing run %.0f of %.0f',i,N),'Mid')
        [data(i).LapTime,data(i).CD] = cost(data(i).DeltaCL,data(i).AB,eta=data(i).Eta);
        data(i).isComplete = true;
    catch
        util.Log.warn(sprintf('Error completing run %.0f of %.0f',i,N),'Mid')
    end
end
util.Log.info('Runs Complete','High')

save('+fh\bin\sweep_CL_AB.mat',"data")

%% plot data
% clear all
load('+fh\bin\sweep_CL_AB.mat')
% Baseline
xEta = [data.Eta];
xCLall  = [data.DeltaCL];
xABall  = [data.AB];
tol     = 1e-6;
iBase   = find(abs(xEta - 1) < tol & abs(xCLall + 1) < tol & abs(xABall - 0.5) < tol);
assert(isscalar(iBase), 'Expected exactly one baseline case, found %d', numel(iBase));
LT0     = data(iBase).LapTime;
Etas = unique(xEta);
% % change in lap time for all cases
dLTall  = 100 * ([data.LapTime] - LT0) / LT0;

% Symmetric colour range about zero
inPlot  = ismember(xEta, Etas(1:3));
cMax    = abs(min(dLTall(inPlot)));
cLims   = [-cMax, cMax];
levels  = linspace(-cMax, cMax, 21);

% Diverging colormap: blue = faster, white = baseline, red = slower
n    = 128;
up   = linspace(0, 1, n)';
cmap = [[up, up, ones(n,1)]; [ones(n,1), flipud(up), flipud(up)]];

% Plot
f = figure;
f.Units = "centimeters";
f.Position = [2,2,16,8];
t = tiledlayout(1, 3, 'TileSpacing', 'compact');

for i = 1:3
    idx = abs(xEta - Etas(i)) < tol;
    xDeltaCLs = xCLall(idx);
    xAB       = xABall(idx);
    xdLT      = dLTall(idx);

    nGrid = 100;
    abVec = linspace(min(xAB), max(xAB), nGrid);
    clVec = linspace(min(xDeltaCLs), max(xDeltaCLs), nGrid);
    [ABg, CLg] = meshgrid(abVec, clVec);

    F_LT = scatteredInterpolant(xAB(:), xDeltaCLs(:), xdLT(:), 'linear', 'none');
    dLTg = F_LT(ABg, CLg);

    ax = nexttile;
    contourf(ABg, CLg, dLTg, levels, 'LineColor', 'none');
    colormap(ax, cmap);
    clim(cLims);                       % caxis(cLims) on R2022a or earlier
    hold on;
    % contour(ABg, CLg, dLTg, [0 0], 'k-', 'LineWidth', 1);   % 0 % line
    plot(xAB, xDeltaCLs, 'k.', 'MarkerSize', 6);

    if abs(Etas(i) - 1) < tol    % mark baseline
        plot(0.5, -1, 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', 10);
    end

    xlabel('AB');
    title(sprintf('$\\eta$: %.1f', Etas(i)));
end

ylabel(t, '$\Delta C_L$', 'Interpreter', 'latex');
cb = colorbar;
cb.Layout.Tile = 'east';
cb.Label.String = '\Delta Lap time (%)';

fontsize(f, 10, "points");


% nexttile;
% contourf(ABg, CLg, CDg, 20, 'LineColor', 'none');
% hold on; plot(xAB, xDeltaCLs, 'k.', 'MarkerSize', 6);   % sample points
% cb = colorbar; cb.Label.String = '$C_D$'; cb.Label.Interpreter = "latex";
% xlabel('Aero Balance (% Wheelbase)'); ylabel('$\Delta C_L$'); title('$C_D$');




%% --- run both seasons ---

function [laptime, CD] = cost(deltaCL, AB, opts)
    arguments
        deltaCL; AB
        opts.cdp = 0.02            % section profile cd (from database)
        opts.eta = 1               % drag multiplier for surrogate spread
        opts.GearRatioFactor = 1
    end
    p  = api.CarAeroParams();
    CL = p.CL_body + deltaCL;
    [ClF, ClR] = api.wingClsForTarget(CL, AB, p);
    [~, CD0]   = api.carAeroFromSections(ClF, opts.cdp, ClR, opts.cdp, p);
    CD  = p.CD_body + opts.eta*(CD0 - p.CD_body);
    res = api.runSeason2025(CL, CD, AB, opts.GearRatioFactor, 'Test');
    laptime = sum([res.laptime]);
end




