function [oMeasure, oErrors, oFrameErrors, oBlackErrors] =...
    PerformanceTRA(aSeqPaths, aTestVer, varargin)
% Computes the TRA tracking performance.
%
% The function call computes the tracking performance measure TRA [1],
% which was used in the cell tracking challenge of 2015. The TRA measure is
% a normalized version of the AOGM measure described in [2]. The AOGM
% results are saved to a log file from which they are later extracted. If
% the log file already exists, the AOGM measure is not recomputed. The AOGM
% measure is a weighted sum of different tracking errors. The un-normalized
% AOGM measure can be computed from the output oErrors. The function can
% use parallel processing if there are multiple image sequences.
%
% Inputs:
% aSeqPaths - The full path of an image sequence, or a cell array with full
%             paths of multiple image sequences.
% aTestVer - Name of the tracking version that should be evaluated. If the
%            tracking version does not exist, the corresponding values in
%            the output will be nan.
%
% Property/Value inputs:
% NumCores - The number of cores to use for parallel processing. If the
%            first input is a cell array with multiple image sequences, the
%            specified number of cores will be used to process the image
%            sequences in parallel in a parfor loop. The default is 1.
%
% Outputs:
% oMeasure - A column vector with the TRA measures of the image sequences.
% oErrors - A matrix with 6 columns, where each row contains the number of
%           tracking errors of different types in one of the image
%           sequences. The 6 columns represent the number of False Negative
%           Vertices, False Positive Vertices, Splitting Operations, Edges
%           To Be Added, Redundant Edges To Be Deleted, and Edges with
%           Wrong Semantics, respectively.
% oFrameErrors - A matrix with 6 columns for the different types of errors
%                and one row for each frame in the image sequence. Each
%                element specifies how many errors of a given type occur in
%                each frame. If multiple image sequences are given as
%                input, this output will be a cell array with one cell for
%                each image sequence.
% oBlackErrors - The same as oErrors, but with the errors that result from
%                empty tracking results without any cells. This corresponds
%                to the creation of a completely manual tracking result in
%                the manual correction step.
%
% References:
% [1] Ulman, V.; Maška, M.; Magnusson, K. E. G.; Ronneberger, O.; Haubold,
%     C.; Harder, N.; Matula, P.; Matula, P.; Svoboda, D.; Radojevic, M.;
%     Smal, I.; Rohr, K.; Jaldén, J.; Blau, H. M.; Dzyubachyk, O.;
%     Lelieveldt, B.; Xiao, P.; Li, Y.; Cho, S.-Y.; Dufour, A. C.;
%     Olivo-Marin, J.-C.; Reyes-Aldasoro, C. C.; Solis-Lemus, J. A.;
%     Bensch, R.; Brox, T.; Stegmaier, J.; Mikut, R.; Wolf, S.; Hamprecht,
%     F. A.; Esteves, T.; Quelhas, P.; Demirel, Ö.; Malmström, L.; Jug, F.;
%     Tomancak, P.; Meijering, E.; Muñoz-Barrutia, A.; Kozubek, M. &
%     Ortiz-de-Solorzano, C., An objective comparison of cell-tracking
%     algorithms, Nature methods, 2017, 14, 1141–1152
%
% [2] Matula, P.; Maška, M.; Sorokin, D. V.; Matula, P.;
%     Ortiz-de-Solórzano, C. & Kozubek, M. Cell Tracking Accuracy
%     Measurement Based on Comparison of Acyclic Oriented Graphs, PLOS ONE,
%     2015, 10, 1-19
%
% See also:
% PerformanceTRAGUI, AOGMR, AOGMR_BLACK

% Parse property/value inputs.
aNumCores = GetArgs({'NumCores'}, {1}, true, varargin);

% Handle cell inputs through recursion.
if iscell(aSeqPaths)
    % Preallocate the output.
    oMeasure = nan(length(aSeqPaths),1);
    oErrors = nan(length(aSeqPaths),6);
    oFrameErrors = cell(length(aSeqPaths));
    oBlackErrors = nan(length(aSeqPaths),6);
    
    if aNumCores == 1
        for i = 1:numel(aSeqPaths)
            fprintf('Evaluating TRA performance for sequence %d / %d\n',...
                i, numel(aSeqPaths))
            [oMeasure(i), oErrors(i,:), oFrameErrors{i}, oBlackErrors(i,:)] =...
                PerformanceTRA(aSeqPaths{i}, aTestVer);
        end
    else
        StartWorkers(aNumCores)
        parfor i = 1:numel(aSeqPaths)
            fprintf('Evaluating TRA performance for sequence %d / %d\n',...
                i, numel(aSeqPaths))
            [oMeasure(i), oErrors(i,:), oFrameErrors{i}, oBlackErrors(i,:)] =...
                PerformanceTRA(aSeqPaths{i}, aTestVer);
        end
    end
    return
end

imData = ImageData(aSeqPaths);
seqDir = imData.GetSeqDir();

if ~HasVersion(aSeqPaths, aTestVer)
    oMeasure = nan;
    oErrors = nan(1,6);
    oFrameErrors = nan(imData.sequenceLength,6);
    oBlackErrors = nan(1,6);
    return
end

% Folder with ground truth.
gtPath = fullfile(imData.GetAnalysisPath(), [seqDir '_GT']);

% Handle ground truth folders where only the two last letters of the image
% sequence name are included in the folder name. That naming was used in
% the cell tracking challenges, but does not make sense for image sequence
% names which do not end with two digits.
if ~exist(gtPath, 'dir')
    alt = fullfile(imData.GetAnalysisPath(), [seqDir(end-1:end) '_GT']);
    if exist(alt, 'dir')
        gtPath = alt;
    else
        error('No ground truth folder found.')
    end
end

% Folder with results.
resPath = fullfile(imData.GetCellDataDir('Version', aTestVer),...
    'RES', [seqDir '_RES']);

% Handle results folders where only the two last letters of the image
% sequence name are included in the folder name.
if ~exist(resPath, 'dir')
    alt = regexprep(resPath, [seqDir '$'], seqDir(end-1:end));
    if exist(alt, 'dir')
        resPath = alt;
    end
end

% File to save the performance evaluation to, so that it does not have to
% be recomputed the next time.
resFile = fullfile(resPath, 'AOGMR_log.txt');

% File with AOGM results for an empty set of tracks.
resFileBlack = fullfile(gtPath, 'TRA', 'AOGMR_BLACK_log.txt');

% Compute the AOGM results for an empty set of tracks if necessary.
if ~exist(resFileBlack, 'file')
    AOGMR_BLACK(fullfile(gtPath, 'TRA'))
end

% Compute performance data if necessary.
if ~exist(resFile, 'file')
    if ~exist(resPath, 'dir')
        ExportCellsTif(aSeqPaths, aTestVer)
    end
    AOGMR(resPath, fullfile(gtPath, 'TRA'))
end

% Read the files with AOGM-results.
[resMeasure, oErrors, oFrameErrors] = ReadAOGMFile(imData, resFile);
[blackMeasure, oBlackErrors] = ReadAOGMFile(imData, resFileBlack);

% Compuate the TRA measure.
oMeasure = max(1 - resMeasure / blackMeasure, 0);
end

function [oMeasure, oErrors, oFrameErrors] = ReadAOGMFile(aImData, aPath)
% Reads log files with AOGM-results.
%
% Inputs:
% aImData - ImageData object for the image sequence.
% aPath - Path of the log file with AOGM-results.
%
% Outputs:
% oMeasure - AOGM measure.
% oErrors - Error matrix with a single row. The matrix has the same
%           structure as the output oErrors returned by PerformanceTRA.
% oFrameErrors - Matrix with the errors in each frame. The matrix has the
%                same structure as the output oFrameErrors returned by
%                PerformanceTRA.

% Read the saved file with performance data as a single string.
fid = fopen(aPath, 'r');
results = fscanf(fid, '%c', inf);
fclose(fid);

% Extract the AOGM measure.
oMeasure = str2double(regexp(results,...
    '(?<=AOGM (measure|value): )[\d\.eE+]*', 'match'));

% Split the file content into lines.
lines = regexp(results, '\r\n', 'split');

% The names of the different error types, which appear on the rows above
% the errors of the given types.
headings = {...
    'False Negative Vertices'
    'False Positive Vertices'
    'Splitting Operations'
    'Edges To Be Added'
    'Redundant Edges To Be Deleted'
    'Edges with Wrong Semantics'}';

% Indices of lines with headings.
headLines = nan(size(headings));
for i = 1:length(headLines)
    headMatch = regexp(lines, ['.*' headings{i} '.*'], 'once');
    index = find(~cellfun(@isempty, headMatch));
    if ~isempty(index)
        headLines(i) = index;
    end
end

% Indices of lines describing errors.
times = regexp(lines, '(?<=T=)\d+', 'match', 'once');
times = cellfun(@str2double, times) + 1;

% Array of line indices where the lines which do not describe errors are
% NaNs.
timeLines = 1:length(times);
timeLines(isnan(times)) = nan;

% Count the number of lines describing errors after each heading.
oErrors = zeros(1,6);
oFrameErrors = zeros(aImData.sequenceLength, 6);
for i = 1:length(headLines)  % Go through the error types.
    % Index of the line directly after the last error of the given type.
    nextHeadLine = min([headLines(headLines > headLines(i)) max(timeLines)+1]);
    % The frames that errors occurred in.
    errorTimes = times(timeLines > headLines(i) & timeLines < nextHeadLine);
    
    % Count the number of errors in each frame.
    oErrors(i) = length(errorTimes);
    for j = 1:length(errorTimes)
        oFrameErrors(errorTimes(j),i) = oFrameErrors(errorTimes(j),i) + 1;
    end
end
end