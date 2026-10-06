clear all
util.Log.setLevel(util.LogLevel.Info)
%% ----- set parameters: design 1 -----
deltaCls = -1.25;
ABs = 0.4:0.01:0.6;
Etas = 1;

data = struct.empty;
%preallocate data
    for i = 1:length(deltaCls)
        for j = 1:length(ABs)
            data(end+1).DeltaCL = deltaCls(i);
            data(end).AB = ABs(j);
            data(end).isComplete = false;
            data(end).CD = nan;
            data(end).LapTime = nan;
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
        [data(i).LapTime,data(i).CD] = cost(data(i).DeltaCL,data(i).AB);
        data(i).isComplete = true;
    catch
        util.Log.warn(sprintf('Error completing run %.0f of %.0f',i,N),'Mid')
    end
end
util.Log.info('Runs Complete','High')




% do search for minima
util.Log.info('Begin Search for minima','High')
% bracket the minimum of the regular sweep: neighbours either side of best point
okRuns = [data.isComplete] & ~isnan([data.LapTime]);
sweepAB = [data(okRuns).AB];
sweepLT = [data(okRuns).LapTime];
[sweepAB,idx] = sort(sweepAB);
sweepLT = sweepLT(idx);
[~,ib] = min(sweepLT);
lo = sweepAB(max(ib-1,1));
hi = sweepAB(min(ib+1,numel(sweepAB)));
util.Log.info(sprintf('Bracket [%.4f, %.4f]',lo,hi),'High')
val = goldenSection(@(x)cost(-1.25,x),lo,hi,5e-4);
data(end+1).DeltaCL = -1.25;
[data(end).LapTime,data(end).CD] = cost(-1.25,val);
data(end).AB = val;
data(end).isComplete = true;
util.Log.info(sprintf('Minima found at AB = %.4f',val),'High')
save('+fh\bin\sweep_AB.mat',"data")

%% plot data
load('+fh\bin\sweep_AB.mat',"data")

% Plot
f = figure;
f.Units = "centimeters";
f.Position = [2,2,16,10];

xAB       = [data(1:end-1).AB];
xLapTime  = [data(1:end-1).LapTime];

[xAB,idx] = sort(xAB);
xLapTime = xLapTime(idx);

plot(xAB,xLapTime,'.-')
hold on
plot(data(end).AB,data(end).LapTime,'kd',MarkerFaceColor='r')
xlabel('Aero Balance [\% wheelbase]')
ylabel('Season total Laptime [s]')
fontsize(f, 10, "points");
grid on
legend('Regular Sweep',sprintf('Minima @ %.4f',data(end).AB))
fontsize(f, 10, "points");

%% --- local functions ---
function xmin = goldenSection(f, a, b, tol)
% Golden-section search for the minimum of a unimodal f on [a,b].
% Reuses one interior point per iteration (one new f evaluation each).
    invPhi = (sqrt(5) - 1)/2;
    c = b - invPhi*(b - a);
    d = a + invPhi*(b - a);
    fc = f(c);
    fd = f(d);
    while (b - a) > tol
        if fc < fd
            b = d;  d = c;  fd = fc;
            c = b - invPhi*(b - a);
            fc = f(c);
        else
            a = c;  c = d;  fc = fd;
            d = a + invPhi*(b - a);
            fd = f(d);
        end
    end
    xmin = (a + b)/2;
end

%% --- run both seasons ---
function [laptime, CD] = cost(deltaCL, AB, opts)
    arguments
        deltaCL; 
        AB;
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




