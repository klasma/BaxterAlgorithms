dataSetFolders = {
    'C:\CTC2020\Challenge'
    'C:\CTC2020\Training'};
trainingOrChallenge = {
    'Challenge'
    'Training'};

currentPath = fileparts(mfilename('fullpath'));
newSettingsPath = fullfile(currentPath, '..', '..', 'Files', 'Settings', 'CTC2020');

for d = 1:length(dataSetFolders)
    exDirs = GetNames(dataSetFolders{d}, '');
    for e = 1:length(exDirs)
        exPath = fullfile(dataSetFolders{d}, exDirs{e});
        seqDirs = GetNames(exPath, '');
        seqDirs = setdiff(seqDirs, 'Analysis');
        settingsLinksPath = fullfile(exPath, 'SettingsLinks.csv');
        
        if exist(settingsLinksPath, 'file')
            continue
        end
        
        sett = cell(length(seqDirs)+1, 3);
        
        % Labels.
        sett{1,1} = 'file';
        sett{1,2} = 'csv-file';
        sett{1,3} = 'fileLink';
        
        for s = 1:length(seqDirs)
            settingsFileName = sprintf('Settings_ISBI_2020_%s_%s-%s.csv',...
                trainingOrChallenge{d}, exDirs{e}, seqDirs{s}(end-1:end));
            
            % Values.
            sett{s+1,1} = seqDirs{s};
            sett{s+1,2} = settingsFileName;
            sett{s+1,3} = seqDirs{s}(end-1:end);
            
            settings = {'file'};  % Empty settings.
            WriteSettings(fullfile(newSettingsPath, settingsFileName), settings)
        end
        
        % Save the link file.
        WriteSettings(fullfile(exPath, 'SettingsLinks.csv'), sett,...
            'Transpose', false);
    end
end

fprintf('Done creating settings link files.\n')