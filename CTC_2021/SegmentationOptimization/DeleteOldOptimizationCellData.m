function DeleteOldOptimizationCellData(aExPaths)
% Deletes old CellData folders created by parameter optimization scripts.
%
% This should be done before starting a new parameter optimization script,
% so that the script does not crash because of old CellData folders with
% locked files.
%
% Inputs:
% exPaths - Cell array with full paths of experiments for which CellData
%           folders should be removed.

for i = 1:length(aExPaths)
    exPath = aExPaths{i};
    analysisPath = fullfile(exPath, 'Analysis');
    folders = GetNames(analysisPath, '');
    optimizationFolders = regexp(folders, '^CellData_optimization\d+$', 'match', 'once');
    optimizationFolders = optimizationFolders(~cellfun(@isempty, optimizationFolders));
    for j = 1:length(optimizationFolders)
        optimizationFolder = optimizationFolders{j};
        optimizationPath = fullfile(analysisPath, optimizationFolder);
        fprintf('Removing %s\n', optimizationPath)
        rmdir(optimizationPath, 's')
    end
end