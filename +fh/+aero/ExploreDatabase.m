%% ===== Plot sectional database =====
clear all
load('+fh\bin\naca_db.mat')
sgn  = -1;                          % cl < 0 is downforce
nTop = 8;                           % sections to highlight

has  = arrayfun(@(D) numel(D.clB) >= 3, db);
db   = db(has);
[~, rk] = sort([db.LDopt], 'descend', 'MissingPlacement', 'last');
top  = rk(1:min(nTop, numel(rk)));
cols = lines(numel(top));

f = figure; f.Units = "centimeters"; f.Position = [2 2 18 14];
t = tiledlayout(2, 2, 'TileSpacing', 'compact');

% (a) cl vs L/D
nexttile; hold on; grid on
for k = 1:numel(db)
    plot(sgn*db(k).clB, db(k).clcd, '-', 'Color', [0 0 0 0.12]);
end
h = gobjects(numel(top), 1);
for j = 1:numel(top)
    D = db(top(j));
    h(j) = plot(sgn*D.clB, D.clcd, '-', 'Color', cols(j,:), 'LineWidth', 1.4);
    plot(sgn*D.clOpt, D.LDopt, 'o', 'Color', cols(j,:), 'MarkerFaceColor', cols(j,:));
end
xlabel('Downforce c_l'); ylabel('c_l / c_d'); title('Lift-to-drag (pre-stall)');
legend(h, {db(top).sec}, 'Location', 'southeast', 'NumColumns', 2);

% (b) drag polar + lowest-drag envelope (what bestSection uses)
nexttile; hold on; grid on
clMax  = max(arrayfun(@(D) max(sgn*D.clB), db));
clGrid = linspace(0, clMax, 300);
cdAll  = nan(numel(db), numel(clGrid));
for k = 1:numel(db)
    x = fliplr(sgn*db(k).clB);  y = fliplr(db(k).cdB);   % ascending downforce
    plot(x, y, '-', 'Color', [0 0 0 0.12]);
    cdAll(k,:) = interp1(x, y, clGrid, 'pchip', NaN);
end
[cdEnv, win] = min(cdAll, [], 1, 'omitnan');
win(all(isnan(cdAll), 1)) = 0;
winners = unique(win(win > 0), 'stable');
cw = lines(numel(winners));  hw = gobjects(numel(winners), 1);
for j = 1:numel(winners)
    m = win == winners(j);
    hw(j) = plot(clGrid(m), cdEnv(m), '.', 'Color', cw(j,:), 'MarkerSize', 8);
end
xlabel('Downforce c_l'); ylabel('c_d'); title('Drag polar envelope');
legend(hw, {db(winners).sec}, 'Location', 'northwest');

% (c) peak L/D vs camber & thickness (best camber position per cell)
nexttile;
m  = arrayfun(@(D) str2double(D.sec(1)),   db);
tt = arrayfun(@(D) str2double(D.sec(3:4)), db);
mU = unique(m);  tU = unique(tt);
LDmap = nan(numel(tU), numel(mU));
for i = 1:numel(tU), for j = 1:numel(mU)
        sel = m == mU(j) & tt == tU(i);
        if any(sel), LDmap(i,j) = max([db(sel).LDopt]); end
end, end
imagesc(mU, tU, LDmap, 'AlphaData', ~isnan(LDmap)); axis xy
cb = colorbar; cb.Label.String = 'max c_l/c_d';
xlabel('Max camber (%c)'); ylabel('Thickness (%c)'); title('Peak L/D (best p)');

% (d) operating range: cl at max L/D vs max usable cl
nexttile; hold on; grid on
clMaxSec = arrayfun(@(D) max(sgn*D.clB), db);
scatter(sgn*[db.clOpt], clMaxSec, 18, [db.LDopt], 'filled');
cb = colorbar; cb.Label.String = 'max c_l/c_d';
plot([0 clMax], [0 clMax], 'k:');
xlabel('c_l at max L/D'); ylabel('Max usable c_l'); title('Operating range');

fontsize(f, 10, "points");