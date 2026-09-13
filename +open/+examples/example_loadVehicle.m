%% OpenLAP Laptime Simulation Project
%
% OpenVEHICLE
%
% Racing vehicle model file creation for use in OpenLAP and OpenDRAG.
% Instructions:
% 1) Select a vehicle excel file containing the vehicles information by
%    assigning the full path to the variable "filename". Use the
%    "OpenVEHICLE tmp.xlsx" file to create a new vehicle excel file.
% 2) Run the script.
% 3) The results will appear on the command window and inside the folder
%    "OpenVEHICLE Vehicles".
%
% More information can be found in the "OpenLAP Laptime Simulator"
% videos on YouTube.
%
% This software is licensed under the GPL V3 Open Source License.
%
% Open Source MATLAB project created by:
%
% Michael Halkiopoulos
% Cranfield University Advanced Motorsport MSc Engineer
% National Technical University of Athens MEng Mechanical Engineer
%
% LinkedIn: https://www.linkedin.com/in/michael-halkiopoulos/
% email: halkiopoulos_michalis@hotmail.com
% MATLAB file exchange: https://uk.mathworks.com/matlabcentral/fileexchange/
% GitHub: https://github.com/mc12027
%
% April 2020.

%% Clearing Memory

clear
clc
close all force
fclose('all') ;

%% Vehicle file selection
filename = 'Formula 1.xlsx' ;

%% Building vehicle model
veh = open.Vehicle.FromExcelFile(filename) ;

%% HUD
[folder_status,folder_msg] = mkdir('data/cars') ;
vehname = "data_cars/Formula_1_car";
disp('Vehicle generated successfully.')

%% Saving vehicle
veh.saveToMat(vehname+".mat")


%% Plot
fig = veh.plotModel() ; %#ok<NASGU>
disp('Plots created and saved.')

