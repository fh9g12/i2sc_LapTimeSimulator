%% OpenLAP Laptime Simulation Project
%
% OpenTRACK
%
% Track model file creation for use in OpenLAP.
% Instructions:
% 1) Select a track excel file containing the track information by
%    assigning the full path to the variable "filename". To select the
%    input method, call open.Track.FromShapeFile (for an "OpenTRACK
%    Shape tmp.xlsx"-format file) or open.Track.FromLoggedFile (for an
%    "OpenTRACK Logged Data tmp.csv"-format file).
%    a) In shape-data mode use the "OpenTRACK Shape tmp.xlsx" file
%       to create a new track excel file.
%    b) In logged-data mode, use the "OpenTRACK Logged Data tmp.csv"
%       file to create a new track excel file. Make sure the rows and
%       columns in the functions correspond to the correct channels.
%       Channels needed to generate a usable track are distance, speed and
%       lateral acceleration or yaw velocity. To select between lateral
%       acceleration and yaw velocity for the curvature calculation, set
%       the "LogMode" option to "speed & latacc" or "speed & yaw".
%       Elevation and banking can be set to 0 everywhere if no data is
%       available. The grip factor should be set to 1 everywhere, and
%       tweaked only increase correlation in specific parts of a track. To
%       filter the logged data, change the duration of the filter from the
%       "FilterDt" option (a value of 0.5 [s] is recommended).
% 2) Set the meshing size to the desired value (a value of 1 to 5 [m] is
%    recommended) via the "MeshSize" option.
% 3) Set the track map rotation angle to the desired value in [deg] via
%    the "Rotation" option. Zero corresponds to the start of the map
%    pointing towards positive X.
% 4) Run the script.
% 5) The results will appear on the command window and in a figure.
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

%% Track file selection

filename = 'Autodromo Nazionale Monza.xlsx' ;

%% Building track model

tr = open.Track.FromShapeFile(filename) ;
%% HUD

[folder_status,folder_msg] = mkdir('../OpenTRACKs') ;
trackname = "../OpenTRACKs/OpenTRACK_"+tr.info.name+"_"+tr.info.config+"_"+tr.info.direction ;
if strcmp(tr.info.mirror,"On")
    trackname = trackname+"_Mirrored" ;
end
disp('Track generated successfully.')

%% Saving track

tr.saveToMat(trackname+".mat")

%% Plot

fig = tr.plotModel() ; %#ok<NASGU>
disp('Plots created and saved.')

%% ASCII map

tr.printAsciiMap()
