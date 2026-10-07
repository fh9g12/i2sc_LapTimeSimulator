clear all
T = readtable("+results\Team Design Challenge 2026 (MSc Aerospace).xlsx", ...
    "ReadRowNames", true, "VariableNamingRule", "preserve");

res = open.SeasonResult.empty;

Nacafs = string(T.("Front Wing Airfoil Section"));
AoAfs = str2double(T.("Front Wing Angle of Attack (deg)"));
Nacars = string(T.("Rear Wing Airfoil Section"));
AoArs = str2double(T.("Rear Wing Angle of Attack (deg)"));
GearRatios = str2double(T.("Gear Ratio Scaling "));
Names = string(T.("Team Name"));
clear T

resC = {};
CL = nan(length(Names),1);
CD = nan(length(Names),1);
AB = nan(length(Names),1);
parfor i = 1:length(Names)
    util.Log.setLevel("Info")
    util.Log.info(sprintf('Running Team %0.f of %0.f',i,length(Names)))
    try
    % car-level aero (same call official_evaluation makes internally)
    [CL(i),CD(i),AB(i)] = api.genCarAeroData(Nacafs(i),AoAfs(i),Nacars(i),AoArs(i));
    resC{i} = api.official_evaluation(Nacafs(i),AoAfs(i),...
        Nacars(i),AoArs(i),GearRatios(i),Names(i));
    util.Log.warn(sprintf('Team %0.f Complete',i,length(Names)))
    catch
        util.Log.warn(sprintf('Team %0.f Failed',i,length(Names)))
    end
end

for i = 1:length(Names)
    res(i) = resC{i};
end

% car-level aero table, one row per team (CL negative = downforce)
aeroTable = table(Nacafs,AoAfs,Nacars,AoArs,GearRatios,CL,CD,AB, ...
    'RowNames',matlab.lang.makeUniqueStrings(cellstr(Names)), ...
    'VariableNames',{'FrontSection','FrontAoA','RearSection','RearAoA','GearRatio','CL','CD','AeroBalance'});
disp(sortrows(aeroTable,'CL'))

%% make plots
close all
[~, ~, ~, pointsTable] = res.comparePositions(res(1:9));

P      = pointsTable{1:end-1, :};        % drop the 'Total' row: races x teams
races  = pointsTable.Properties.RowNames(1:end-1);
teams  = pointsTable.Properties.VariableNames;
cum    = cumsum(P, 1);                   % running championship total
races = erase(erase(string(races),'FORMULA 1 '),' GRAND PRIX 2025');

figure
plot(1:size(cum,1), cum, '-o', 'LineWidth', 1.2, 'MarkerSize', 3)
xticks(1:numel(races)); xticklabels(races); xtickangle(45)
xlabel('Race'); ylabel('Cumulative points')

% legend(teams, 'Location', 'northwest', 'Interpreter', 'none')

[final, order] = sort(cum(end,:), 'descend');
top = order(1:min(9, numel(order)));
for k = top
    text(size(cum,1) + 0.1, cum(end,k), teams{k}, 'Interpreter', 'none')
end
xlim([1, size(cum,1) + 3])               % room for the labels

grid on


%% car-level aero scatter plots (10 x 10 cm)
% one marker/colour combination per team, shared by both figures + legend
nT      = height(aeroTable);
teamLbl = aeroTable.Properties.RowNames;
mk      = repmat('os^v<>dph*+x', 1, ceil(nT/12));  mk = mk(1:nT);   % marker per team
col     = repmat(lines(7), ceil(nT/7), 1);         col = col(1:nT,:); % colour per team
msz     = 8;                                                         % marker size

f1 = figure;
f1.Units = "centimeters";
f1.Position = [2, 2, 10, 10];
hold on
for k = 1:nT
    plot(aeroTable.CD(k), aeroTable.CL(k), mk(k), 'Color', col(k,:), ...
        'MarkerFaceColor', col(k,:), 'MarkerSize', msz)
end
xlabel("$C_D$", "Interpreter", "latex")
ylabel("$C_L$", "Interpreter", "latex")
grid on
fontsize(f1, 10, "points")

f2 = figure;
f2.Units = "centimeters";
f2.Position = [2, 2, 10, 10];
hold on
for k = 1:nT
    plot(aeroTable.AeroBalance(k),aeroTable.CL(k), mk(k), 'Color', col(k,:), ...
        'MarkerFaceColor', col(k,:), 'MarkerSize', msz)
end
ylabel("$C_L$", "Interpreter", "latex")
xlabel("Aero balance [-]")
grid on
fontsize(f2, 10, "points")

%% legend-only figure
f3 = figure;
f3.Units = "centimeters";
ncol = ceil(nT/15);                              % ~15 entries per legend column
f3.Position = [2, 2, 5*ncol, 0.55*min(nT,15) + 1];
ax = axes(f3, 'Visible', 'off');
hold(ax, 'on')
h = gobjects(nT,1);
for k = 1:nT
    h(k) = plot(ax, nan, nan, mk(k), 'Color', col(k,:), ...
        'MarkerFaceColor', col(k,:), 'MarkerSize', msz);
end
lg = legend(ax, h, teamLbl, 'Interpreter', 'none', 'NumColumns', ncol, 'Box', 'off');
lg.Units = 'normalized';
lg.Position = [0 0 1 1];
fontsize(f3, 10, "points")
