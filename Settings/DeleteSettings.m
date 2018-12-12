function DeleteSettings(aSeqPath)
% Deletes settings for an image sequence from a settings file.
%
% DeleteSettings removes all settings associated with a particular image
% sequence from the corresponding settings file. If there is a
% SettingsLinks.csv file, the link for the image sequence will be removed,
% but the settings that the link file points to will not be altered. If
% there is both a SettingsLinks.csv and a Settings.csv file, only the
% SettinsLinks.csv file will be altered.
%
% Inputs:
% aSeqPath - Path of image sequence from which to remove all settings.
%
% See also:
% CopySettings

exPath = fileparts(aSeqPath);

% File with links to other settings files. This takes precedence over a
% real settings file if it exists.
settingsLinkPath = fullfile(exPath, 'SettingsLinks.csv');
% File with settings.
settingsPath = fullfile(exPath, 'Settings.csv');

% Select what csv file to alter.
if exist(settingsLinkPath, 'file')
    csvFile = settingsLinkPath;
elseif exist(settingsPath, 'file')
    csvFile = settingsPath;
else
    return
end

% Read old settings.
sett = ReadSettings(csvFile);

% Remove the row associated with aSeqPath.
index = find(strcmp(sett(2:end,1), FileEnd(aSeqPath)))+1;
sett(index,:) = [];

if size(sett,1) == 1
    % There are no image sequences in the settings file, so it can be
    % removed.
    delete(csvFile)
else
    % Save new settings.
    WriteSettings(csvFile, sett)
end
end