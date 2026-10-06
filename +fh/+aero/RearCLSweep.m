%% ===== Rear-cl sweep: database + closed-form balance (no XFOIL) =====
clear all
load('+fh\bin\naca_db.mat')
S  = load('+fh\bin\surrogate_LapTime_CL_CD.mat');
F  = griddedInterpolant({S.CL, S.CD}, S.LapTime, S.method, 'none');
Fv = griddedInterpolant({S.CL, S.CD}, double(S.valid), 'linear', 'none');
ABt = S.AB;
p   = api.CarAeroParams();                 % car geometry/body (same defaults as genCarAeroData)

db    = db(arrayfun(@(D) numel(D.clB) >= 3, db));
allCl = [db.clB];
clR   = linspace(min(0, max(allCl)), min(allCl), 300);   % rear sectional cl targets

% --- Section choice (vectorised over all targets) ---
[secR, aR, cdR] = bestSection(db, clR);
clF             = api.frontClForBalance(clR, ABt, p);    % exact balance
[secF, aF, cdF] = bestSection(db, clF);
feas = ~isnan(cdR) & ~isnan(cdF);

% --- Car level: one call on the whole arrays ---
[CL, CD, AB] = api.carAeroFromSections(clF, cdF, clR, cdR, p);
CL(~feas) = NaN;  CD(~feas) = NaN;  AB(~feas) = NaN;
dCL    = CL - p.CL_body;
LT     = F(dCL, CD);
inData = Fv(dCL, CD) > 0.99;
ok     = ~isnan(LT);

% --- Diagnostics ---
N = numel(clR);
fprintf('Feasible (balanced) setups: %d of %d, inside surrogate: %d\n', nnz(feas), N, nnz(ok));
if any(feas)
    fprintf('dCL: %.3f to %.3f   CD: %.4f to %.4f\n', ...
        min(dCL(feas)), max(dCL(feas)), min(CD(feas)), max(CD(feas)));
    idx = find(feas);  idx = idx(round(linspace(1, numel(idx), min(5, numel(idx)))));
    disp(table(clR(idx).', secR(idx).', aR(idx).', clF(idx).', secF(idx).', aF(idx).', ...
        CL(idx).', CD(idx).', AB(idx).', LT(idx).', 'VariableNames', ...
        {'clR','secR','aR','clF','secF','aF','CL','CD','AB','LT'}))
end
if ~any(ok)
    error('No feasible setup inside the surrogate: rebuild it over the dCL/CD range above.');
end

LTb = LT;  LTb(~ok) = Inf;
[~, ib] = min(LTb);
fprintf('Predicted best: rear %s @ %.2f deg (cl %.3f), front %s @ %.2f deg (cl %.3f)\n', ...
    secR{ib}, aR(ib), clR(ib), secF{ib}, aF(ib), clF(ib));
fprintf('  -> CL %.3f, CD %.4f, AB %.4f, lap %.3f s\n', CL(ib), CD(ib), AB(ib), LT(ib));
save('+fh\bin\rearCL_sweep.mat', 'clR','clF','secF','aF','cdF','secR','aR','cdR', ...
     'CL','CD','AB','LT','inData','p','ABt')

%% ===== Plot =====
f = figure; f.Units = "centimeters"; f.Position = [2 2 16 12];
tiledlayout(2, 2, 'TileSpacing', 'compact');
x = -clR;                                          % rear downforce magnitude

nexttile; hold on; grid on
plot(x(ok), LT(ok), '-', 'Color', [0.5 0.5 0.5]);
plot(x(ok & inData),  LT(ok & inData),  '.', 'MarkerSize', 10);
plot(x(ok & ~inData), LT(ok & ~inData), 'o', 'MarkerSize', 3);       % extrapolated
plot(x(ib), LT(ib), 'rp', 'MarkerFaceColor', 'r', 'MarkerSize', 10);
xlabel('Rear sectional downforce $c_l$'); ylabel('Lap time (s)');

nexttile; grid on
yyaxis left;  plot(x(feas), CL(feas), '-'); ylabel('Car $C_L$');
yyaxis right; plot(x(feas), CD(feas), '-'); ylabel('Car $C_D$');
xlabel('Rear sectional downforce $c_l$');

nexttile; hold on; grid on
plot(x, -clF, '-');
yline(-min(allCl), 'k:', 'database limit');
xlabel('Rear sectional downforce $c_l$'); ylabel('Front $c_l$ needed for AB');

nexttile;
Z = S.LapTime; Z(~S.valid) = NaN;
contourf(S.CL, S.CD, Z.', 20, 'LineColor', 'none'); hold on
plot(dCL(feas), CD(feas), 'k-');
plot(dCL(ib), CD(ib), 'rp', 'MarkerFaceColor', 'r', 'MarkerSize', 10);
xlabel('$\Delta C_L$', 'Interpreter', 'latex'); ylabel('$C_D$', 'Interpreter', 'latex');
cb = colorbar; cb.Label.String = 'Lap time (s)';
fontsize(f, 10, "points");

%% ===== Verify with cold XFOIL, trim front AoA for exact AB =====
[clRx, aRx] = coldCl(secR{ib}, aR(ib), p.rearChord_m);           % actual rear cl
clFt        = api.frontClForBalance(clRx, ABt, p);               % front target from actual rear
[~, aFx]    = trimAoA(secF{ib}, aF(ib), clFt, p.frontChord_m, 1e-3);

[ClFx, CdFx, ClRx, CdRx] = api.wingSectionAero(secF{ib}, aFx, secR{ib}, aRx, p);
[CLx, CDx, ABx] = api.carAeroFromSections(ClFx, CdFx, ClRx, CdRx, p);
fprintf('Verified: front %s @ %.3f deg, rear %s @ %.3f deg\n', secF{ib}, aFx, secR{ib}, aRx);
fprintf('  CL %.3f (pred %.3f), CD %.4f (pred %.4f), AB %.4f, lap %.3f s\n', ...
    CLx, CL(ib), CDx, CD(ib), ABx, F(CLx - p.CL_body, CDx));

% Robustness: cold runs at +/-0.1 deg on both wings
[dF, dR] = ndgrid([-0.1 0 0.1]);
chk = nan(numel(dF), 6);
for j = 1:numel(dF)
    [a1, a2, a3, a4] = api.wingSectionAero(secF{ib}, aFx + dF(j), secR{ib}, aRx + dR(j), p);
    [c1, c2, c3]     = api.carAeroFromSections(a1, a2, a3, a4, p);
    chk(j,:) = [dF(j) dR(j) c1 c2 c3 F(c1 - p.CL_body, c2)];
end
disp(array2table(chk, 'VariableNames', {'dAoA_F','dAoA_R','CL','CD','AB','LapTime'}))

%% ===== Local functions =====
function [sec, a, cd] = bestSection(db, clT)
% Lowest-cd section/AoA for each target cl (vectorised over clT).
% Returns row outputs; sec is a cell array ('' where no section reaches clT).
    clT = clT(:).';  n = numel(clT);
    Am  = nan(numel(db), n);
    CDm = inf(numel(db), n);
    for k = 1:numel(db)
        B  = db(k);
        in = clT >= min(B.clB) & clT <= max(B.clB);
        if ~any(in), continue; end
        Am(k,in)  = interp1(B.clB, B.aB,  clT(in),  'pchip');
        CDm(k,in) = interp1(B.aB,  B.cdB, Am(k,in), 'pchip');
    end
    [cd, kb] = min(CDm, [], 1);
    a   = Am(sub2ind(size(Am), kb, 1:n));
    sec = {db(kb).sec};
    none = isinf(cd);
    cd(none) = NaN;  a(none) = NaN;  sec(none) = {''};
end

function [cl, a, cd] = coldCl(sec, a, chord)
% Single cold XFOIL point; nudge AoA if it fails, return the AoA used
    cl = NaN; cd = NaN;
    for d = [0 0.05 -0.05 0.1 -0.1]
        try, [cl, cd] = api.naca4Aero(sec, a + d, 'chord_m', chord); catch, end
        if ~isnan(cl), a = a + d; return; end
    end
end

function [cl, a] = trimAoA(sec, a, clT, chord, tol)
% Secant iteration on AoA so the cold-run cl hits clT
    [cl, a] = coldCl(sec, a, chord);
    k = 0.1;                                       % initial dcl/dalpha guess (1/deg)
    for it = 1:8
        if abs(cl - clT) < tol, return; end
        aNew = a + (clT - cl)/k;
        [clNew, aNew] = coldCl(sec, aNew, chord);
        if isnan(clNew), return; end
        if abs(aNew - a) > 1e-6
            kNew = (clNew - cl)/(aNew - a);
            if kNew > 0.02, k = kNew; end
        end
        a = aNew;  cl = clNew;
    end
end