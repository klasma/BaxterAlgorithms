function paths = GetSettingsFiles(aExPath)

    csvFiles = GetNames(aExPath, 'csv');
    
    linkIndices = startsWith(csvFiles, 'SettingsLinks');
    settingsLinkFiles = csvFiles(linkIndices);
    
    otherCsvFiles = csvFiles(~linkIndices);
    
    settingsIndices = startsWith(otherCsvFiles, 'Settings');
    settingsFiles = otherCsvFiles(settingsIndices);
    
    paths = [
        fullfile(aExPath, settingsLinkFiles)
        fullfile(aExPath, settingsFiles)
        ];
end