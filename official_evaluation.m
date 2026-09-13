% ----- set parameters -----
front_aerofoil_section = '0012';
front_aoa = 10;
rear_aerofoil_section = '0012';
rear_aoa = 8;
gear_ratio_scaling = 1.1;

% ----- get result -----
res = api.official_evaluation(front_aerofoil_section);