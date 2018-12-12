function SaveSettingsGUI(aSeqPaths)
% Saves settings so that they can be loaded later.
%
% The function lets the user save the settings associated with a image
% sequences to the folder with settings files inside the program but also
% to other locations.
%
% Inputs:
% aSeqPaths - Cell array of strings with full path names of image sequence
%             folders. Only the settings associated with the first image
%             sequence will be saved.
%
% See also:
% LoadSettingsGUI

[exPaths, seqDirs] = FileParts2(aSeqPaths);

% Let the user specify a file name for the saved settings.
settingsFilePath = FindFile('SettingsFiles', 'Settings.csv');
[saveFile, savePath] = uiputfile(...
    {'*.csv', 'Settings Files'},...
    'Save Settings',...
    settingsFilePath);

if isequal(saveFile, 0)
    % The user chose to cancel.
    return
end

% Read settings and merge them into a single settings cell array in case
% they come from multiple experiment folders.
[uniqueExPaths, ~, indices] = unique(exPaths);
sett = {'file'};  % Empty settings cell array.
for i = 1:length(uniqueExPaths)
    sett_i = ReadSettings(uniqueExPaths{i}, seqDirs(indices == i));
    sett = MergeSettings(sett, sett_i);
end

% Save the settings.
WriteSettings(fullfile(savePath, saveFile), sett);
end