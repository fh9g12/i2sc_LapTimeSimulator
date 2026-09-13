function raw = extractInfoFields(info)
    % Unpacks the ordered "Info" sheet rows into named raw parameters.
    % Mirrors the row order of the "OpenVEHICLE tmp.xlsx" template.
    raw.name = table2array(info(1,2)) ;
    raw.type = table2array(info(2,2)) ;

    i = 3 ;
    raw.M = str2double(table2array(info(i,2))) ; i = i+1 ; % [kg]
    raw.df = str2double(table2array(info(i,2)))/100 ; i = i+1 ; % [-]
    raw.L = str2double(table2array(info(i,2)))/1000 ; i = i+1 ; % [m]
    raw.rack = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]

    raw.Cl = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.Cd = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.factor_Cl = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.factor_Cd = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.da = str2double(table2array(info(i,2)))/100 ; i = i+1 ; % [-]
    raw.A = str2double(table2array(info(i,2))) ; i = i+1 ; % [m2]
    raw.rho = str2double(table2array(info(i,2))) ; i = i+1 ; % [kg/m3]

    raw.br_disc_d = str2double(table2array(info(i,2)))/1000 ; i = i+1 ; % [m]
    raw.br_pad_h = str2double(table2array(info(i,2)))/1000 ; i = i+1 ; % [m]
    raw.br_pad_mu = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.br_nop = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.br_pist_d = str2double(table2array(info(i,2))) ; i = i+1 ; % [mm]
    raw.br_mast_d = str2double(table2array(info(i,2))) ; i = i+1 ; % [mm]
    raw.br_ped_r = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]

    raw.factor_grip = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.tyre_radius = str2double(table2array(info(i,2)))/1000 ; i = i+1 ; % [m]
    raw.Cr = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.mu_x = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.mu_x_M = str2double(table2array(info(i,2))) ; i = i+1 ; % [1/kg]
    raw.sens_x = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.mu_y = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.mu_y_M = str2double(table2array(info(i,2))) ; i = i+1 ; % [1/kg]
    raw.sens_y = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.CF = str2double(table2array(info(i,2))) ; i = i+1 ; % [N/deg]
    raw.CR = str2double(table2array(info(i,2))) ; i = i+1 ; % [N/deg]

    raw.factor_power = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.n_thermal = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.fuel_LHV = str2double(table2array(info(i,2))) ; i = i+1 ; % [J/kg]

    raw.drive = table2array(info(i,2)) ; i = i+1 ;
    raw.shift_time = str2double(table2array(info(i,2))) ; i = i+1 ; % [s]
    raw.n_primary = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.n_final = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.n_gearbox = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.ratio_primary = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.ratio_final = str2double(table2array(info(i,2))) ; i = i+1 ; % [-]
    raw.ratio_gearbox = str2double(table2array(info(i:end,2))) ;
    raw.nog = length(raw.ratio_gearbox) ;
end
