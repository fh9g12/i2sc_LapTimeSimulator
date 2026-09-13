%% ----- set parameters -----
Cl = -3.65;
Cd = 1.06;
AeroBalance = 0.513;
gear_ratio_scaling = 1;

%% --- run simulation 1 ---
tic;
res1 = api.runSeason2025(Cl,Cd,AeroBalance,gear_ratio_scaling,'FH');
fprintf('Total laptime: %.0f s \n',sum(res1.laptime));
toc;

%% ----- set parameters -----
Cl = -3.9;
Cd = 1.1;
AeroBalance = 0.534;
gear_ratio_scaling = 1;

%% --- run simulation 2 - tweaked Aero balance ---
tic;
res2 = api.runSeason2025(Cl,Cd,AeroBalance,gear_ratio_scaling,'FH2');
fprintf('Total laptime: %.0f s \n',sum(res2.laptime));
toc;


%% -- compare race by race;
figure;
p = util.spider_plot([res1.laptime,res2.laptime]');
p.AxesLabels = cellfun(@(x)x,strrep(extractBefore(res2.file,'.'),'_',' '),'UniformOutput',false)';
p.LegendLabels = {res1.teamName,res2.teamName};