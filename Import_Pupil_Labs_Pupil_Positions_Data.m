%{
Import_Pupil_Labs_Positions_Data
Author: Tom Bullock, UCSB Attention Lab
Date: 03.21.18

Use this function to import pupil-labs pupil position data
Inputs: file path and file name
Outputs: table with annotation data
%}

function [pupilpositions1] = Import_Pupil_Labs_Pupil_Positions_Data(filePath, fileName)


%% Initialize variables.
filename = [filePath '/' fileName];
%filename = '/Users/tombullock/Documents/Psychology/BOSS/PUPIL_TEMP/b''BOSS_206_2_3_2_vs''/000/exports/000/pupil_positions.csv';
delimiter = ',';

%% Read columns of data as text:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%q%q%q%q%q%q%q%q%q%q%q%q%q%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string',  'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric text to numbers.
% Replace non-numeric text with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2,3,4,5,6,7,8,9,10,11,12,13]
    % Converts text in the input cell array to numbers. Replaced non-numeric
    % text with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1)
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData(row), regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if numbers.contains(',')
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'))
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric text to numbers.
            if ~invalidThousandsSeparator
                numbers = textscan(char(strrep(numbers, ',', '')), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch
            raw{row, col} = rawData{row};
        end
    end
end


%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
raw(R) = {NaN}; % Replace non-numeric cells

%% Create output variable
pupilpositions1 = table;
pupilpositions1.timestamp = cell2mat(raw(:, 1));
pupilpositions1.index = cell2mat(raw(:, 2));
pupilpositions1.id = cell2mat(raw(:, 3));
pupilpositions1.confidence = cell2mat(raw(:, 4));
pupilpositions1.norm_pos_x = cell2mat(raw(:, 5));
pupilpositions1.norm_pos_y = cell2mat(raw(:, 6));
pupilpositions1.diameter = cell2mat(raw(:, 7));
pupilpositions1.method = cell2mat(raw(:, 8));
pupilpositions1.ellipse_center_x = cell2mat(raw(:, 9));
pupilpositions1.ellipse_center_y = cell2mat(raw(:, 10));
pupilpositions1.ellipse_axis_a = cell2mat(raw(:, 11));
pupilpositions1.ellipse_axis_b = cell2mat(raw(:, 12));
pupilpositions1.ellipse_angle = cell2mat(raw(:, 13));

%% Clear temporary variables
clearvars filename delimiter formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp R;
return