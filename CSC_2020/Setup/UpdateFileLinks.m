% Make the settings link files of all old expriment folders point to the
% new settings files for CTC 2020.

dataSetFolders = {
    'C:\CTC2020\Challenge'
    'C:\CTC2020\Training'};

for d = 1:length(dataSetFolders)
    experimentFolders = GetNames(dataSetFolders{d});
    for e = 1:length(experimentFolders)
        settingsLinksPath = fullfile(dataSetFolders{d}, experimentFolders{e}, 'SettingsLinks.csv');
        
        if ~exist(settingsLinksPath, 'file')
            continue
        end
        
        fprintf('Modifying %s\n', settingsLinksPath)
        
        fid = fopen(settingsLinksPath, 'r');
        text = fscanf(fid, '%c', inf);
        fclose(fid);
        
        text = strrep(text, 'ISBI_2019', 'ISBI_2020');
        
        fid = fopen(settingsLinksPath, 'w');
        fprintf(fid, '%c', text);
        fclose(fid);
    end
end