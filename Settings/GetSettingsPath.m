function oPath = GetSettingsPath(aFilename)
% Returns the full path of a built in settings file.
%
% The function finds the full path of one of the settings files in the
% folder named 'SettingsFiles', given the name of the file. The function is
% used to make it possible to put the settings files in sub-folders inside
% the SettingsFiles folder and still only specify the names of the files in
% SettingsLinks.csv files. The function starts by searching in the
% SettingsFiles folder and then searches through the sub-folders in
% alphabetical order. The first matching file is returned, and the function
% does not check if there are multiple files with the same name.
%
% Inputs:
% aFilename - The name of the settings file including '.csv' but without
%             path information.
%
% Outputs:
% oPath - The full path of the settings file.

% Find the full paths of the SettingsFiles folder and all sub-folders.
settingsBaseFolder = FindFile('Settings');
settingsFolders = textscan(genpath(settingsBaseFolder), '%s',...
    'delimiter', pathsep);
settingsFolders = settingsFolders{1};

for i = 1:length(settingsFolders)
    settingsFiles = GetNames(settingsFolders{i}, 'csv');
    index = strcmp(settingsFiles, aFilename);
    if any(index)
        oPath = fullfile(settingsFolders{i}, settingsFiles{index});
        return
    end
end
error('The settings file %s does not exist\n', aFilename)
end