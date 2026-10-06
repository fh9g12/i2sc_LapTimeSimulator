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
parfor i = 1:length(Names)
    util.Log.setLevel("Info")
    util.Log.info(sprintf('Running Team %0.f of %0.f',i,length(Names)))
    try
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