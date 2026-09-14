% Example: run two parameter choices on one race, compare their lap
% times, then compare their GGV envelopes (grip limit) side by side.
track = api.RaceNames.Monza;

nameA = 'Low downforce';
ClA = -3;  CdA = 1.0;  AeroBalanceA = 0.5;  GearRatioScaleA = 1;

nameB = 'High downforce';
ClB = -5;  CdB = 1.5;  AeroBalanceB = 0.5;  GearRatioScaleB = 1;
% try changing CdB to 1.4 ... you'll se the best design switch!

resA = api.simulate_race(track,ClA,CdA,AeroBalanceA,GearRatioScaleA,nameA);
resB = api.simulate_race(track,ClB,CdB,AeroBalanceB,GearRatioScaleB,nameB);

% Compare lap times
fprintf('%s: %.3f s\n',nameA,resA.laptime);
fprintf('%s: %.3f s\n',nameB,resB.laptime);
if resA.laptime < resB.laptime
    fprintf('%s is faster by %.3f s\n',nameA,resB.laptime-resA.laptime);
else
    fprintf('%s is faster by %.3f s\n',nameB,resA.laptime-resB.laptime);
end

% Compare GGV envelopes
api.compareGGV(ClA,CdA,AeroBalanceA,GearRatioScaleA,nameA, ...
               ClB,CdB,AeroBalanceB,GearRatioScaleB,nameB);
