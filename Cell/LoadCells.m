function oCells = LoadCells(aSeqPath, aVersion, varargin)
% Loads Cell objects representing a tracking result.
%
% This function loads tracking results which have been created using either
% automated tracking or the manual correction GUI. The tracking results are
% stored in <Experiment path>/Analysis/CellData<version>/<Image sequence
% name>.mat. There can also be a compact version of the tracking result
% (without the outlines of the cells) with the path <Experiment
% path>/Analysis/CellData<version>/Compact/<Image sequence name>.mat. The
% compact version can be loaded by setting the 'Compact' property to true.
%
% Inputs:
% aSeqPath - Full path of an image sequence folder. aSeqPath can also be a
%            cell array with multiple image sequence paths. In this case, a
%            vector containing Cell objects from all image sequences will
%            be returned.
% aVersion - Label of the tracking version (not including 'CellData').
%
% Property/Value inputs:
% Compact - Loads the compact version of saved cells. This version does not
%           have information about the cell outlines and can therefore be
%           loaded faster. The default is logical false.
% AreCells - Excludes false positive cells (Cell objects which represent
%            debris or background features) from the returned array. The
%            default is logical false.
%
% Outputs:
% oCells - Array of loaded Cell objects.
%
% See also:
% SaveCells, Cells

[aCompact, aAreCells] = GetArgs(...
    {'Compact', 'AreCells'},...
    {false, false},...
    1, varargin);

if iscell(aSeqPath)
    % Read tracking results from multiple image sequences.
    
    wbar = waitbar(0,...
        sprintf('Trying to load file %d / %d', 1, length(aSeqPath)),...
        'Name', 'Loading tracking results');
    oCells = {};
    for i = 1:length(aSeqPath)
        waitbar((i-1)/length(aSeqPath), wbar,...
            sprintf('Trying to load file %d / %d', i, length(aSeqPath)))
        cells = LoadCells(aSeqPath{i}, aVersion, varargin{:});
        if ~isempty(cells)
            oCells = [oCells cells]; %#ok<AGROW>
        end
    end
    delete(wbar)
else
    % Read tracking results from a single image sequence.
    
    imData = ImageData(aSeqPath, 'version', aVersion);
    
    % Full path of the mat-file containing saved tracking results.
    if aCompact
        matFile = fullfile(imData.GetCellDataDir('Version', aVersion),...
            'Compact', [imData.GetSeqDir() '.mat']);
    else
        matFile = fullfile(imData.GetCellDataDir('Version', aVersion),...
            [imData.GetSeqDir() '.mat']);
    end
    
    if exist(matFile, 'file')
        % Load the tracking result from a mat-file.
        oCells = load(matFile);
        if aCompact
            oCells = oCells.cellData_compact;
        else
            oCells = oCells.cellData;
        end
    else
        % Load the tracking results from tif- and txt-files. These files
        % are loaded if the SaveCells failed to save a mat-file and saved
        % tif- and txt-files in the CTC format instead.
        ctcDir = fullfile(....
            imData.GetCellDataDir('Version', aVersion),...
            'RES',...
            [imData.GetSeqDir(), '_RES']);
        if exist(ctcDir, 'dir')
            oCells = LoadCellsTif(aSeqPath, ctcDir);
        else
            fprintf('The tracking result %s does not exist\n', aVersion)
            oCells = [];
            return
        end
    end
    
    if aAreCells
        oCells = AreCells(oCells);
    end
    
    if isempty(oCells)
        return
    end
    
    % Replace the saved ImageData object by an updated object. This can be
    % important if the image sequence folder has been moved.
    for i = 1:length(oCells)
        oCells(i).imageData = imData;
    end
end

% Delete cells which have a life time shorter than 1 frame. This is done to
% fix corrupted data. This should not be necessary, but some old tracking
% results may require it.
if ~isempty(oCells)
    deleteIndex = false(size(oCells));
    for i = 1:length(oCells)
        c = oCells(i);
        if c.lifeTime < 1
            deleteIndex(i) = true;
            if ~isempty(c.parent)
                c.parent.RemoveChildren()
            end
        end
    end
    oCells(deleteIndex) = [];
end

% Trim cells which occur outside the defined image sequence length
% This is required in order to analyze image sequences with different
% lengths, or to exclude the ending of an experiment from analysis.
if ~isempty(oCells)
    deleteIndex = false(size(oCells));
    for i = 1:length(oCells)
        c = oCells(i);
        if c.firstFrame > c.sequenceLength
            deleteIndex(i) = true;
            if ~isempty(c.parent)
                c.parent.RemoveChildren()
            end
        elseif c.lastFrame > c.sequenceLength
            c.Split(c.sequenceLength+1);
        end
    end
    oCells(deleteIndex) = [];
end

end