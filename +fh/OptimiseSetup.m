%% ===== Gradient-based optimisation of front AoA, rear AoA and gear ratio =====
% Given a starting setup (wing sections + AoAs + gear scale), minimise total
% season lap time with fmincon (Optimization Toolbox). Gradients are central
% finite differences, evaluated in parallel.
% Section choice (NACA 4-digit) is fixed -- only AoAs and gearing are free.
% Aero balance is NOT constrained: it falls out of the two AoAs.
clear all
util.Log.setLevel(util.LogLevel.Info)

%% ----- initial condition -----
secF = "2506";   aF0 = -0.3;       % front section / AoA [deg]   (negative = downforce)
secR = "8315";   aR0 = -15.172;    % rear  section / AoA [deg]
gear0 = 1.0;                       % final drive scale (Vehicle.withGearRatioScale)

x0 = [aF0; aR0; gear0];            % design vector [aF; aR; gear]
lb = [-18; -18; 0.7];
ub = [  0;   0; 1.3];

p = api.CarAeroParams();           % same car as the sweeps

%% ----- optimise -----
hist = struct('x', {}, 'f', {});
options = optimoptions('fmincon', ...
    'Algorithm', 'sqp', ...
    'Display', 'iter', ...
    'UseParallel', true, ...
    'FiniteDifferenceType', 'central', ...
    'FiniteDifferenceStepSize', 0.01, ...   % x TypicalX -> 0.1 deg / 0.01 gear
    'TypicalX', [10; 10; 1], ...
    'StepTolerance', 1e-3, ...
    'OptimalityTolerance', 1e-3, ...
    'MaxIterations', 30, ...
    'OutputFcn', @(x, ov, state) record(x, ov, state));

util.Log.info('Begin optimisation', 'High')
[xo, f] = fmincon(@(x) cost(x, secF, secR, p), x0, [], [], [], [], lb, ub, [], options);

%% ----- report -----
[ClF, CdF, ClR, CdR] = api.wingSectionAero(secF, xo(1), secR, xo(2), p);
[CL, CD, AB] = api.carAeroFromSections(ClF, CdF, ClR, CdR, p);
fprintf('\nOptimum: front %s @ %.3f deg, rear %s @ %.3f deg, gear scale %.4f\n', ...
    secF, xo(1), secR, xo(2), xo(3));
fprintf('  CL %.3f, CD %.4f, AB %.4f, season lap time %.3f s (start %.3f s)\n', ...
    CL, CD, AB, f, hist(1).f);
save('+fh\bin\optimise_setup.mat', 'hist', 'xo', 'secF', 'secR', 'CL', 'CD', 'AB', 'f')

X = [hist.x];
figure
tiledlayout(2, 1, 'TileSpacing', 'compact');
nexttile; plot([hist.f], '.-'); ylabel('Season lap time (s)'); grid on
nexttile; yyaxis left; plot(X(1:2,:)', '.-'); ylabel('AoA (deg)')
yyaxis right; plot(X(3,:), 'k.--'); ylabel('Gear scale')
xlabel('Iteration'); grid on; legend('Front AoA', 'Rear AoA', 'Gear', 'Location', 'best')

%% ===== Local functions =====
function f = cost(x, secF, secR, p)
% Season lap time for design x = [aF; aR; gearScale]. NaN if anything fails.
    util.Log.setLevel(util.LogLevel.Info, "Mid")
    try
        [ClF, CdF, ClR, CdR] = api.wingSectionAero(secF, x(1), secR, x(2), p);
        [CL, CD, AB] = api.carAeroFromSections(ClF, CdF, ClR, CdR, p);
        res = api.runSeason2025(CL, CD, AB, x(3), 'Opt');
        f = sum([res.laptime]);
    catch
        f = NaN;
    end
end

function stop = record(x, ov, state)
% fmincon OutputFcn: log each major iteration into the base-workspace 'hist'.
    stop = false;
    if strcmp(state, 'iter')
        h = evalin('base', 'hist');
        h(end+1) = struct('x', x(:), 'f', ov.fval);
        assignin('base', 'hist', h);
    end
end
