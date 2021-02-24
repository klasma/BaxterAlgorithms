function oMeasure = PerformanceSEG(aSeqPaths, aTestVer, aRelaxed, varargin)
% Computes the SEG or relaxed SEG measure for segmentation performance.
%
% The function acts as a wrapper for SEGmeasure, which computes the
% performance measures. The results are saved to log files which are later
% read by this function. If the log file already exists, the results will
% not be recomputed. The SEG measure is the mean of the the Jaccard
% similarity index of pixel sets in matching regions. The relaxed SEG
% measure is normally higher than the SEG measure, because the normal SEG
% measure requires that segmented regions cover more than half of the
% corresponding ground truth regions. The function can use parallel
% processing if there are multiple image sequences.
%
% Inputs:
% aSeqPaths - The full path of an image sequence, or a cell array with full
%             paths of multiple image sequences.
% aTestVer - Name of the tracking version that should be evaluated. If the
%            tracking version does not exist, the corresponding values in
%            the output will be nan.
% aRelaxed - If this is true, the relaxed SEG measure is used.
%
% Property/Value inputs:
% NumCores - The number of cores to use for parallel processing. If the
%            first input is a cell array with multiple image sequences, the
%            specified number of cores will be used to process the image
%            sequences in parallel in a parfor loop. The default is 1.
%
% Outputs:
% oMeasure - A column vector with the SEG measures of the image sequences.
%
% See also:
% SEGmeasure

% Parse property/value inputs.
aNumCores = GetArgs({'NumCores'}, {1}, true, varargin);

% Handle cell inputs through recursion.
if iscell(aSeqPaths)
    % Pre-allocate the output.
    oMeasure = nan(length(aSeqPaths),1);
    
    if aNumCores == 1
        for i = 1:numel(aSeqPaths)
            fprintf('Evaluating SEG performance for sequence %d / %d\n',...
                i, numel(aSeqPaths))
            oMeasure(i) = PerformanceSEG(aSeqPaths{i}, aTestVer, aRelaxed);
        end
    else
        StartWorkers(aNumCores)
        parfor i = 1:numel(aSeqPaths)
            fprintf('Evaluating SEG performance for sequence %d / %d\n',...
                i, numel(aSeqPaths))
            oMeasure(i) = PerformanceSEG(aSeqPaths{i}, aTestVer, aRelaxed);
        end
    end
    return
end

if ~HasVersion(aSeqPaths, aTestVer)
    oMeasure = nan;
    return
end

imData = ImageData(aSeqPaths);
seqDir = imData.GetSeqDir();

% Folder with ground truth.
gtPath = fullfile(imData.GetAnalysisPath(), [seqDir '_GT'], 'SEG');
% Folder with tracking results.
resPath = fullfile(imData.GetCellDataDir('Version', aTestVer),...
    'RES', [seqDir '_RES']);
% File that the performance evaluation will be saved to, so that it does
% not have to be recomputed the next time.
if aRelaxed
    resFile = fullfile(resPath, 'SEGR_log.txt');
else
    resFile = fullfile(resPath, 'SEG_log.txt');
end

% Check if the name of the ground truth folder has been abbreviated, if the
% folder cannot be found.
if ~exist(gtPath, 'dir')
    alt = fullfile(imData.GetAnalysisPath(), [seqDir(end-1:end) '_GT'], 'SEG');
    if exist(alt, 'dir')
        gtPath = alt;
    else
        error('No ground truth folder found.')
    end
end

% Check if the name of the folder with tracking results has been
% abbreviated, if the folder cannot be found.
if ~exist(resPath, 'dir')
    alt = regexprep(resPath, [seqDir '$'], seqDir(end-1:end));
    if exist(alt, 'dir')
        resPath = alt;
    end
end

% Compute performance data if necessary.
if ~exist(resFile, 'file')
    % Convert the tracking information to the right format.
    if (~exist(resPath, 'dir') ||...
            length(GetNames(resPath,'tif')) ~= imData.sequenceLength  ||...
            ~exist(fullfile(resPath, 'res_track.txt'), 'file')) &&...
            exist(fullfile(imData.GetAnalysisPath(), ['CellData' aTestVer], [seqDir '.mat']), 'file')
        if exist(resPath, 'dir')
            % Remove incomplete results folder.
            fclose('all'); % rmdir can fail because files are open in Matlab.
            rmdir(resPath, 's')
        end
        imData = ImageData(aSeqPaths);
        cells = LoadCells(aSeqPaths, aTestVer);
        SaveCellsTif(imData, cells, aTestVer, false);
    end
    
    SEGmeasure(resPath, gtPath, aRelaxed)
end

% Read the saved file with performance data.
fid = fopen(resFile, 'r');
results = fscanf(fid, '%c', inf);
fclose(fid);

% Extract the SEG measure from the contents of the saved file.
if aRelaxed
    oMeasure = str2double(regexp(results, '(?<=SEGR measure: )[\d\.]*', 'match'));
else
    oMeasure = str2double(regexp(results, '(?<=SEG measure: )[\d\.]*', 'match'));
end
end