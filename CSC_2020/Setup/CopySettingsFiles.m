% Copy the old settings files to a new folder.

currentPath = fileparts(mfilename('fullpath'));
oldSettingsPath = fullfile(currentPath, '..', '..', 'Files', 'Settings', 'CSC2019');
newSettingsPath = fullfile(currentPath, '..', '..', 'Files', 'Settings', 'CTC2020');

if ~exist(oldSettingsPath, 'dir')
    printf('The folder %s does not exist.', oldSettingsPath)
end

if ~exist(newSettingsPath, 'dir')
    mkdir(newSettingsPath)
end

settingsFiles = GetNames(oldSettingsPath, 'csv');

for i = 1:length(settingsFiles)
    fprintf('Copying settings file %d / %d\n', i, length(settingsFiles))
    src = fullfile(oldSettingsPath, settingsFiles{i});
    dst = fullfile(newSettingsPath, strrep(settingsFiles{i}, 'ISBI_2019', 'ISBI_2020'));
    copyfile(src, dst)
end