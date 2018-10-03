%{
Import_Pupil_Labs_Annotation_Data
Author: Tom Bullock
Date: 03.21.18

Use this function to import pupil-labs gaze surface data
Inputs: file path and file name
Outputs: table with annotation data
%}

function [gazeData] = Import_Pupil_Labs_Gaze_Surface_Data(filePath, fileName)

%% Initialize variables.
%filename = '/Users/tombullock/Documents/Psychology/BOSS/PUPIL_TEMP/b''BOSS_206_2_1_1_ri''/000/exports/000/surfaces/gaze_positions_on_surface_BOSS_WEST_SCREEN_1520443576.721629.csv';
filename = [filePath '/surfaces/' fileName];
delimiter = ',';
startRow = 2;

%% Format for each line of text:
%   column1: double (%f)
%	column2: double (%f)
%   column3: double (%f)
%	column4: double (%f)
%   column5: double (%f)
%	column6: double (%f)
%   column7: double (%f)
%	column8: categorical (%C)
%   column9: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%f%f%f%f%f%f%f%C%f%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'EmptyValue', NaN, 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Create output variable
gazeData = table(dataArray{1:end-1}, 'VariableNames', {'world_timestamp','world_frame_idx','gaze_timestamp','x_norm','y_norm','x_scaled','y_scaled','on_srf','confidence'});

%% Clear temporary variables
clearvars filename delimiter startRow formatSpec fileID dataArray ans;
return