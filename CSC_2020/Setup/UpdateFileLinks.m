% Make the settings link files of all old expriment folder point to the new
% settings files for CSC 2019.

dataSetFolders = {
    'E:\CellData_2011_2014\2019_02_14_Cell_Tracking_Challenge_2019\Challenge'
    'E:\CellData_2011_2014\2019_02_14_Cell_Tracking_Challenge_2019\Training'};

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
        
        text = strrep(text, 'ISBI_2015', 'ISBI_2019');
        
        fid = fopen(settingsLinksPath, 'w');
        fprintf(fid, '%c', text);
        fclose(fid);
    end
end