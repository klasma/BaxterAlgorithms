% Removes the experiment name from the sequence names in settings files.

folders = {
    'C:\git\BaxterAlgorithms_CSC2019\Files\Settings\CTC2021_trained_on_GT'
    'C:\git\BaxterAlgorithms_CSC2019\Files\Settings\CTC2021_trained_on_GT_all'
    };

for i = 1:length(folders)
    folder = folders{i};
    files = GetNames(folder, 'csv');
    for j = 1:length(files)
        file = files{j};
        path = fullfile(folder, file);
        sett = ReadSettings(path);
        sett{2,1} = sett{2,1}(end-1:end);
        WriteSettings(path, sett)
    end
end