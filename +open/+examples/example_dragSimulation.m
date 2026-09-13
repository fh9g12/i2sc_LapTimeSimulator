%% OpenLAP Laptime Simulation Project
%
% OpenDRAG
%
% Straight line acceleration and braking simulation using a simple point
% mass model for a racing vehicle.
% Instructions:
% 1) Select a vehicle file created by OpenVEHICLE by assigning the full
%    path to the variable "vehiclefile".
% 2) Run the script.
% 3) The results will appear on the command window and in a figure.
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

%% Clearing memory

clear
clc
close all force
fclose('all') ;

%% Loading vehicle

vehiclefile = '../OpenVEHICLEs/Formula_1_car.mat' ;
veh = open.Vehicle.loadFromMat(vehiclefile) ;

%% Running the simulation
sim = open.DragSimulation.Run(veh) ;

%% Saving results
[folder_status,folder_msg] = mkdir('../OpenDRAG Sims') ;
simname = "../OpenDRAG Sims/OpenDRAG_"+veh.name ;
sim.saveToMat(simname+".mat")

%% Plot
fig = sim.plotModel() ; %#ok<NASGU>
