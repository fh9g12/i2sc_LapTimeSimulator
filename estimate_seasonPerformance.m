%% ----- set parameters: design 1 -----
Cl1 = -3.65;
Cd1 = 1.06;
AeroBalance1 = 0.513;
gearRatioScale1 = 1;
name1 = 'FH';

%% ----- set parameters: design 2 (tweaked aero balance) -----
Cl2 = -3.9;
Cd2 = 1.1;
AeroBalance2 = 0.534;
gearRatioScale2 = 1;
name2 = 'FH2';

%% --- run both seasons ---
tic;
res1 = api.runSeason2025(Cl1,Cd1,AeroBalance1,gearRatioScale1,name1);
fprintf('%s total laptime: %.0f s\n',name1,sum(res1.laptime));
toc;

tic;
res2 = api.runSeason2025(Cl2,Cd2,AeroBalance2,gearRatioScale2,name2);
fprintf('%s total laptime: %.0f s\n',name2,sum(res2.laptime));
toc;

%% --- compare race by race ---
trackNames = strrep(extractBefore(res1.file,'.'),'_',' ');

figure;
p = util.spider_plot([res1.laptime,res2.laptime]');
p.AxesLabels = cellfun(@(x)x,trackNames,'UniformOutput',false)';
p.LegendLabels = {res1.teamName,res2.teamName};

%% --- how many races was each design fastest at? ---
nRaces = numel(res1.laptime);
wins1 = res1.laptime < res2.laptime;
wins2 = res2.laptime < res1.laptime;
nTies = nRaces-nnz(wins1)-nnz(wins2);

fprintf('\n%s fastest at %d of %d races: %s\n',name1,nnz(wins1),nRaces,strjoin(trackNames(wins1),', '));
fprintf('%s fastest at %d of %d races: %s\n',name2,nnz(wins2),nRaces,strjoin(trackNames(wins2),', '));
if nTies>0
    fprintf('%d race(s) tied exactly\n',nTies);
end

%% --- compare GGV envelopes ---
% Same two parameter sets, seen as grip envelopes rather than lap times --
% useful for seeing WHY one design wins more races than the other.
api.compareGGV(Cl1,Cd1,AeroBalance1,gearRatioScale1,name1, ...
               Cl2,Cd2,AeroBalance2,gearRatioScale2,name2);
