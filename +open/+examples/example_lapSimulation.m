%% OpenLAP Laptime Simulation Project
%
% OpenLAP
%
% Lap time simulation using a simple point mass model for a racing vehicle.
% Instructions:
% 1) Select a vehicle file created by OpenVEHICLE by assigning the full
%    path to the variable "vehiclefile".
% 2) Select a track file created by OpenTRACK by assigning the full path to
%    the variable "trackfile".
% 3) Select an export frequency in [Hz] by setting the variable "freq" to
%    the desired value.
% 4) Run the script.
% 5) The results will appear on the command window and in a figure. A
%    .csv export and a .mat file are written to "OpenLAP Sims".
%
% More information can be found in the "OpenLAP Laptime Simulator"
% videos on YouTube.
%
% This software is licensed under the GPL V3 Open Source License.
%
% Open Source MATLAB project created by:
%
% Michael Halkiopoulos
% Cranfield University MSc Advanced Motorsport Engineer
% National Technical University of Athens MEng Mechanical Engineer
%
% LinkedIn: https://www.linkedin.com/in/michael-halkiopoulos/
% email: halkiopoulos_michalis@hotmail.com
% MATLAB file exchange: https://uk.mathworks.com/matlabcentral/fileexchange/
% GitHub: https://github.com/mc12027
%
% April 2020.

%% Clearing memory

clear
clc
close all force
fclose('all') ;

%% Filenames

trackfile = '../OpenTRACKs/2025/Monza.mat' ;
vehiclefile = '../OpenVEHICLEs/Formula_1_car.mat' ;

%% Loading circuit & car

tr = open.Track.loadFromMat(trackfile) ;
veh = open.Vehicle.loadFromMat(vehiclefile) ;

%% Export frequency

freq = 50 ; % [Hz]

%% Lap Simulation

sim = open.LapSimulation.Run(veh, tr) ;

%% Saving results

[folder_status,folder_msg] = mkdir('OpenLAP Sims') ;
simname = "OpenLAP Sims/OpenLAP_"+char(veh.name)+"_"+tr.info.name ;
sim.saveToMat(simname+".mat")
sim.exportCSV(veh, tr, simname+".csv", freq)

%% Plot

fig = sim.plotModel(veh, tr) ; %#ok<NASGU>
