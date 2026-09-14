% Example: evaluate one team's submitted parameters over the full season.
% AoA is NEGATIVE for downforce.
front_aerofoil_section = '0012';
front_aoa = -10;
rear_aerofoil_section = '0012';
rear_aoa = -8;
gear_ratio_scaling = 1.1;
team_name = "Team 1";

res = api.official_evaluation(front_aerofoil_section,front_aoa, ...
    rear_aerofoil_section,rear_aoa,gear_ratio_scaling,team_name);
