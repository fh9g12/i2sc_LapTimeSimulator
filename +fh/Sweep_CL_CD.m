clear all
util.Log.setLevel(util.LogLevel.Info)
%% ----- set parameters: design 1 -----
deltaCls = 0:-0.1:-4;
ABs = 0.4388;
Etas = 0.5:0.1:1.5;

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

save('+fh\bin\sweep_CL_CD.mat',"data")

%% Build surrogate + plot
% clear all
load('+fh\bin\sweep_CL_CD.mat')

% Keep only successful runs
ok   = [data.isComplete] & ~isnan([data.LapTime]) & ~isnan([data.CD]);
data = data(ok);

xCL  = [data.DeltaCL];
xCD  = [data.CD];
xLT  = [data.LapTime];
xOsw = [data.Eta];
tol  = 1e-6;

% Regular grid: native dCL sweep values x fine CD vector
clVec = unique(round(xCL, 6));                  % ascending (required)
cdVec = linspace(min(xCD), max(xCD), 200);
LTg   = nan(numel(clVec), numel(cdVec));        % ndgrid layout: rows = CL, cols = CD
valid = false(size(LTg));                       % true where inside sampled data

for i = 1:numel(clVec)
    m = abs(xCL - clVec(i)) < tol;
    [cdi, s] = sort(xCD(m));
    lti      = xLT(m);  lti = lti(s);
    [cdi, u] = unique(cdi);  lti = lti(u);
    if numel(cdi) < 2, continue; end

    in = cdVec >= cdi(1) & cdVec <= cdi(end);
    valid(i,:)  = in;
    LTg(i, in)  = interp1(cdi, lti, cdVec(in),  'pchip');             % smooth inside
    LTg(i, ~in) = interp1(cdi, lti, cdVec(~in), 'linear', 'extrap');  % gentle outside
end
LTg = fillmissing(LTg, 'linear', 1);            % any rows lost to failed runs

% ---- Save surrogate (plain arrays = robust across MATLAB versions) ----
surrogate.CL      = clVec(:).';
surrogate.CD      = cdVec;
surrogate.LapTime = LTg;
surrogate.valid   = valid;
surrogate.AB      = unique([data.AB]);
surrogate.method  = 'makima';
surrogate.created = datetime('now');
surrogate.source  = 'sweep_CL_AB.mat';
save('+fh\bin\surrogate_LapTime_CL_CD.mat', '-struct', 'surrogate')

% ---- Plot ----
Zplot = LTg;  Zplot(~valid) = NaN;              % only show where data exists

f = figure;
f.Units = "centimeters";
f.Position = [2, 2, 12, 9];

contourf(clVec, cdVec, Zplot.', 20, 'LineColor', 'none');
hold on;

% Lines of constant Oswald (the sweep "spokes")
Etas = unique(round(xOsw, 6));
for k = 1:numel(Etas)
    m = abs(xOsw - Etas(k)) < tol;
    [cl_k, s] = sort(xCL(m));
    cd_k = xCD(m);  cd_k = cd_k(s);
    plot(cl_k, cd_k, '-', 'Color', [0 0 0 0.35], 'LineWidth', 0.5);
    % text(cl_k(1), cd_k(1), sprintf(' e=%.1f', Oswalds(k)), ...
    %     'FontSize', 8, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
end
plot(xCL, xCD, 'k.', 'MarkerSize', 5);

xlabel('$\Delta C_L$', 'Interpreter', 'latex');
ylabel('$C_D$',        'Interpreter', 'latex');
title(sprintf('Lap time surrogate (AB = %.4f)', surrogate.AB));
cb = colorbar;
cb.Label.String = 'Total Season Lap time (s)';

fontsize(f, 10, "points");

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




