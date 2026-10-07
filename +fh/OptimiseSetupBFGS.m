%% ===== Gradient-based optimisation of front AoA, rear AoA and gear ratio =====
% Toolbox-free alternative to OptimiseSetup.m (fmincon): bounded BFGS
% quasi-Newton with Armijo backtracking. Gradients are central finite
% differences, evaluated in parallel. A NaN (XFOIL/sim failure) at a trial
% point is simply rejected by the line search and the step is halved.
% Section choice (NACA 4-digit) is fixed -- only AoAs and gearing are free.
% Aero balance is NOT constrained: it falls out of the two AoAs.
clear all
util.Log.setLevel(util.LogLevel.Info)

%% ----- initial condition -----
secF = "2604";   aF0 = -0;     % front section / AoA [deg]   (negative = downforce)
secR = "9312";   aR0 = -14;    % rear  section / AoA [deg]
gear0 = 1.0;                       % final drive scale (Vehicle.withGearRatioScale)

x0    = [aF0; aR0; gear0];         % design vector [aF; aR; gear]
lb    = [-18; -18; 0.7];
ub    = [  4;   4; 1.3];
scale = [1; 1; 0.05];              % 1 scaled unit = 1 deg, 1 deg, 0.05 gear

%% ----- optimiser settings (in scaled units) -----
opt.h        = 0.025;                % finite-difference half-step  (0.1 deg / 0.005 gear)
opt.maxStep  = 2;                  % largest line-search step     (2 deg / 0.1 gear)
opt.maxIter  = 30;
opt.gTol     = 1e-2;               % projected-gradient inf-norm  [s per scaled unit]
opt.fTol     = 1e-3;               % stop if lap time improves < this twice in a row [s]

p = api.CarAeroParams();           % same car as the sweeps

%% ----- run -----
z   = x0 ./ scale;  zlb = lb ./ scale;  zub = ub ./ scale;
n   = numel(z);
f   = cost(z.*scale, secF, secR, p);
if isnan(f), error('Initial condition failed (XFOIL non-convergence?) -- change the start point.'); end
util.Log.info(sprintf('Start: lap %.3f s', f), 'High')

g = fdGrad(z, zlb, zub, opt.h, secF, secR, p, scale);
H = eye(n);
hist = struct('x', x0, 'f', f);
smallGain = 0;

for it = 1:opt.maxIter
    gp = g;  gp(z <= zlb & g > 0) = 0;  gp(z >= zub & g < 0) = 0;   % projected gradient
    if norm(gp, inf) < opt.gTol, util.Log.info('Converged: gradient small','High'); break, end

    d = -H*g;
    d(z <= zlb & d < 0) = 0;  d(z >= zub & d > 0) = 0;   % don't push into active bounds
    if g'*d >= 0                                          % not a descent direction -> steepest descent
        H = eye(n);  d = -gp;
    end
    alpha = min(1, opt.maxStep/norm(d));

    % backtracking (Armijo) line search, bounds enforced by clipping
    accepted = false;
    for ls = 1:10
        zn = min(max(z + alpha*d, zlb), zub);
        fn = cost(zn.*scale, secF, secR, p);
        if ~isnan(fn) && fn < f + 1e-4*g'*(zn - z), accepted = true; break, end
        alpha = alpha/2;
    end
    if ~accepted
        if isequal(H, eye(n)), util.Log.info('Converged: line search failed','High'); break, end
        H = eye(n);  continue                             % retry with steepest descent
    end

    gn = fdGrad(zn, zlb, zub, opt.h, secF, secR, p, scale);
    s = zn - z;  y = gn - g;
    if s'*y > 1e-10                                       % BFGS update (keeps H positive definite)
        r = 1/(s'*y);
        H = (eye(n) - r*s*y') * H * (eye(n) - r*y*s') + r*(s*s');
    end

    gain = f - fn;
    z = zn;  f = fn;  g = gn;
    hist(end+1) = struct('x', z.*scale, 'f', f); %#ok<SAGROW>
    util.Log.info(sprintf('Iter %2d: lap %.3f s  aF %.3f  aR %.3f  gear %.4f', ...
        it, f, hist(end).x(1), hist(end).x(2), hist(end).x(3)), 'High')

    smallGain = (gain < opt.fTol) * (smallGain + 1);
    if smallGain >= 2, util.Log.info('Converged: lap time no longer improving','High'); break, end
end

%% ----- report -----
xo = z .* scale;
[ClF, CdF, ClR, CdR] = api.wingSectionAero(secF, xo(1), secR, xo(2), p);
[CL, CD, AB] = api.carAeroFromSections(ClF, CdF, ClR, CdR, p);
fprintf('\nOptimum: front %s @ %.3f deg, rear %s @ %.3f deg, gear scale %.4f\n', ...
    secF, xo(1), secR, xo(2), xo(3));
fprintf('  CL %.3f, CD %.4f, AB %.4f, season lap time %.3f s (start %.3f s)\n', ...
    CL, CD, AB, f, hist(1).f);
save('+fh\bin\optimise_setup_bfgs.mat', 'hist', 'xo', 'secF', 'secR', 'CL', 'CD', 'AB', 'f')

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

function g = fdGrad(z, zlb, zub, h, secF, secR, p, scale)
% Central-difference gradient in scaled units, clipped at the bounds
% (one-sided there). All evaluations run in parallel.
    n  = numel(z);
    zp = repmat(z, 1, n);  zm = zp;
    for k = 1:n
        zp(k,k) = min(z(k) + h, zub(k));
        zm(k,k) = max(z(k) - h, zlb(k));
    end
    fp = nan(1, n);  fm = nan(1, n);
    parfor k = 1:n
        fp(k) = cost(zp(:,k).*scale, secF, secR, p);
        fm(k) = cost(zm(:,k).*scale, secF, secR, p);
    end
    g = zeros(n, 1);
    for k = 1:n
        dz = zp(k,k) - zm(k,k);
        if dz > 0, g(k) = (fp(k) - fm(k))/dz; end
    end
    if any(isnan(g)), error('Gradient evaluation failed (NaN) -- XFOIL did not converge near this point.'); end
end
