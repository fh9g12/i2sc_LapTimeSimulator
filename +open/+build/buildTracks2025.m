%% buildTracks2025
%
% Batch-builds an open.Track for every OpenF1-derived shape-data Excel
% file in "tracks_2025/", and saves each one into
% "OpenTRACK Tracks/2025/" under the same short, special-character-free
% filename as its source Excel file (e.g. "tracks_2025/Monza.xlsx" ->
% "OpenTRACK Tracks/2025/Monza.mat"), so they can be loaded with
% open.Track.loadFromMat just like any other track file.
%
% A failure on one track (e.g. a malformed sheet) is reported and does
% not stop the rest of the batch.

%% Clearing memory

clear
clc
close all force

%% Settings

inputFolder = '+open/+build/tracks_2025' ;
outputFolder = 'data/tracks' ;

%% Building tracks

mkdir(outputFolder) ;
files = dir(fullfile(inputFolder,'*.xlsx')) ;

succeeded = strings(0,1) ;
failed = strings(0,1) ;

for i = 1:numel(files)
    filename = fullfile(files(i).folder,files(i).name) ;
    disp(['Building: ',files(i).name])
    try
        tr = open.Track.FromShapeFile(filename) ;

        [~,baseName] = fileparts(files(i).name) ;
        trackname = outputFolder+"/"+baseName ;
        tr.saveToMat(trackname+".mat") ;

        % tr.plotModel();
        succeeded(end+1,1) = string(files(i).name) ; %#ok<SAGROW>
    catch ME
        warning(['Failed to build ',files(i).name,': ',ME.message])
        failed(end+1,1) = string(files(i).name) ; %#ok<SAGROW>
    end
end

%% Summary

disp('====================================================================')
disp(numel(succeeded)+" of "+numel(files)+" tracks built successfully.")
if ~isempty(failed)
    disp('Failed files:')
    disp(failed)
end
