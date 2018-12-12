function SaveCells(aCells, aSeqPath, aVersion, varargin)
% Saves an array of Cell objects to a mat-file.
%
% If desired, the function will also save compressed versions of the Cell
% objects. The compressed versions don't have blob objects, and instead
% have some pre-computed blob properties. The compressed Cells take less
% memory when they are loaded and might load faster. If a compressed
% version is saved, the caller can choose to compress the existing Cell
% objects or compress copies of them. Altering the objects saves RAM,
% reduces the run time and can make the saved files smaller. The function
% uses the save format '-v7', because 'v7.3' takes about 25 times more
% space. For very large tracking results, MATLAB can run out of memory when
% the data is compressed and therefore fail to save the mat-file. If that
% happens, the Cell objects are saved to tif- and txt-files in the CTC
% format instead. Previously, the v7.3 format was used as a fallback, but I
% had some problems with corrupted files when I saved large 3D datasets and
% therefore switched to the CTC format. The CTC format is more robust but
% takes longer to load.
%
% Inputs:
% aCells - Array of Cell objects.
% aSeqPath - Full path of folder containing the image sequence.
% aVersion - Suffix on the name of the saved file. All files start with
%            'CellData'.
%
% Property/Value inputs:
% Compact - If this is set to true, a compressed version of the Cell
%           objects is saved in subdirectory named 'Compact'. The property
%           is set to true by default.
% CompressCopy - If this is set to false, the Cell objects in aCell will be
%                compressed. This property is set to true by default.
%
% See also:
% Cell, LoadCells

% Get additional inputs.
[aCompact, aCompressCopy] = GetArgs(...
    {'Compact', 'CompressCopy'}, {true, true}, 1, varargin);

[saveDir, saveName] = FileParts2(aSeqPath);

saveDir = fullfile(saveDir, 'Analysis', ['CellData' aVersion]);

if ~exist(saveDir, 'dir')
    mkdir(saveDir)
end

% Change the variable name for saving.
cellData = aCells;

% Don't save features, as this seems to make the compression in the save
% function require too much memory.
for cIndex = 1:length(cellData)
    c = cellData(cIndex);
    for bIndex = 1:length(c.blob)
        c.blob(bIndex).features = [];
    end
end

% Save full Cell data.
savePath = fullfile(saveDir, [saveName '.mat']);
try
    save(savePath, 'cellData', '-v7')
catch
    warning('Failed to save mat-file. Saving to tif-files instead.')
    if exist(savePath, 'file')
        delete(savePath)
        if exist(savePath, 'file')
            % The function delete gives its own warning if it was not
            % possible to delete the file, but the user should be told that
            % the file has to be deleted manually.
            warning(['Failed to delete the corrupted file %s. You have '...
                'to delete the file manually before you can load the '...
                'saved tif-files. You may have to close MATLAB before '...
                'you can delete the file.'], savePath)
        end
    end
    SaveCellsTif(ImageData(aSeqPath), aCells, aVersion, false,...
        'SaveDeaths', true, 'SaveFP', true);
end

if aCompact
    if aCompressCopy
        % This produces copies of the Cells that that are altered.
        cellData_compact = CopyCellVec(cellData);
    else
        % This alters the Cells that were given as input.
        cellData_compact = cellData;
    end
    
    % Compress all cell objects.
    for i = 1:length(cellData_compact)
        cellData_compact(i).Compress();
    end
    
    if ~exist([saveDir filesep 'Compact'], 'dir')
        mkdir([saveDir filesep 'Compact'])
    end
    
    % Save compressed cell data.
    save(fullfile(saveDir, 'Compact', [saveName '.mat']),...
        'cellData_compact', '-v7')
end