function CreateSettingsLinkFile(aExPath, aTrainingOrChallenge, aSuffix)

sett{1,1} = 'file';
sett{1,2} = 'csv-file';
sett{1,3} = 'fileLink';

seqDirs = GetSeqDirs(aExPath);
for s = 1:length(seqDirs)
    settingsFileName = sprintf('Settings_ISBI_2021_%s_%s-%s%s.csv',...
        aTrainingOrChallenge, FileEnd(aExPath), seqDirs{s}(end-1:end), aSuffix);
    
    basePath = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    settingsPath = fullfile(basePath, 'Files', 'Settings', ['CTC2021' aSuffix], settingsFileName);
    if ~exist(settingsPath, 'file')
        fprintf('Creating %s\n', settingsPath)
        WriteSettings(settingsPath, {'file'})
    end
    
    % Values.
    sett{s+1,1} = seqDirs{s};
    sett{s+1,2} = settingsFileName;
    sett{s+1,3} = seqDirs{s}(end-1:end);
end

% Save the link file.
filename = fullfile(aExPath, sprintf('SettingsLinks%s.csv', aSuffix));
WriteDelimMat(filename, sett, ',');
end