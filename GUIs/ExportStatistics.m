function ExportStatistics(aSeqPaths)
% Exports statistics for different cell properties to csv files.
%
% The function exports statistics for the cell properties avgSpeed,
% avgAxisRatio, avgSize, divisionTime, and timeToFirstDivision. A separate
% csv file is created for each property. The mean, standard deviation,
% median, max, min, and number of cells used for the estimation are saved
% for each experimental condition, and also for each generation in the
% different experimental conditions. The method first opens a dialog where
% a tracking version can be selected, and then opens a dialog where the
% user can specify a folder that the csv files will be created in.
%
% Inputs:
% aSeqPaths - Cell array with full paths of the image sequences that should
%             be included in the analysis.
%
% See also:
% PlotGUI

% Open dialog to select tracking version.
versions = GetVersions(aSeqPaths);
versions = unique([versions{:}])';
[sel, ok] = listdlg('PromptString', 'Select tracking version:',...
    'SelectionMode', 'single',...
    'ListString', versions);
if ok
    ver = versions{sel};
else
    % The user canceled the version selection dialog.
    return
end

% Open dialog to specify a directory where the csv files will be saved.
saveDir = uigetdir(fileparts(fullfile(fileparts(aSeqPaths{1}), 'Analysis')),...
    'Export statistics');

if isequal(saveDir, 0)
    % The user canceled the file saving dialog.
    return
end

% The cell properties to save statistics for.
properties = {...
    'avgSpeed',...
    'avgAxisRatio',...
    'avgSize',...
    'divisionTime',...
    'timeToFirstDivision'};

% File names for the csv files that will be created.
fileNames = {...
    'Average speed (microns per hr)',...
    'Average axis ratio',...
    'Average size (square microns)',...
    'Time between divisions (hr)',...
    'Time to first division (hr)'};

cells = LoadCells(aSeqPaths, ver, 'AreCells', true, 'Compact', true);

% Partition the cells by condition and by both condition and generation.
% The latter partitioning is used to compute statistics per generation.
[pCells1, pLabels1] = PartitionCells(cells, 'condition');
[pCells2, pLabels2] = PartitionCells(cells, 'condition', 'generation');

% Create a cell array where each cell is a cell array of strings that can
% be written to a csv file.
stats = cell(length(properties),1);
for i = 1:length(properties)
    stats{i} = cell(length(pLabels1)+length([pLabels2{2,:}])+3,7);
    
    % Headings.
    stats{i}(1,:) = {'' 'mean', 'std', 'median', 'min', 'max', 'N'};
    
    % Statistics for the conditions.
    for j = 1:length(pCells1)
        values = [pCells1{j}.(properties{i})];
        values(isnan(values)) = [];
        stats{i}{j+1,1} = pLabels1{j};
        stats{i}{j+1,2} = num2str(mean(values));
        stats{i}{j+1,3} = num2str(std(values));
        stats{i}{j+1,4} = num2str(median(values));
        stats{i}{j+1,5} = num2str(min(values));
        stats{i}{j+1,6} = num2str(max(values));
        stats{i}{j+1,7} = num2str(length(values));
    end
    
    % Statistics for the generations in each condition. The property
    % timeToFirstDivision only exists for generation 1 and therefore no
    % generation information is saved for that property.
    if ~strcmp(properties{i}, 'timeToFirstDivision')
        index = length(pCells1) + 2;  % The row to write to.
        for j = 1:length(pCells2)
            index = index + 1;  % Leave a blank row.
            for k = 1:length(pCells2{j})
                values = [pCells2{j}{k}.(properties{i})];
                % Cells that do not have the property defined are excluded
                % from the analysis.
                values(isnan(values)) = [];
                
                label = sprintf('%s gen %d', pLabels2{1,j}, pLabels2{2,j}{k});
                stats{i}{index,1} = label;
                stats{i}{index,2} = num2str(mean(values));
                stats{i}{index,3} = num2str(std(values));
                stats{i}{index,4} = num2str(median(values));
                stats{i}{index,5} = num2str(min(values));
                stats{i}{index,6} = num2str(max(values));
                stats{i}{index,7} = num2str(length(values));
                
                index = index + 1;
            end
        end
    end
end

% Write the extracted data to csv files.
for i = 1:length(fileNames)
    filePath = fullfile(saveDir, [fileNames{i} '.csv']);
    WriteDelimMat(filePath, stats{i}, ',')
end
end