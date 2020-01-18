function BaxterAlgorithmsTermial(aExPaths, aVer, varargin)
% Runs the Baxter Algorithms cell tracking from the command line.
%
% This is only meant for processing computers where MATLAB has to be run
% from the command line. Parallel processing is used by default, but the
% user must start a parallel pool manually. Stabilization and cutting can
% not be performed, and there is no way to change any of the settings.
%
% Inputs:
% aExPaths - Cell array with full paths of the experiment folders. The
%            input can also be a string with a single experiment folder.
% aVer - Text label of the tracking results that will be saved.
%
% Property/Value inputs:
% RegExp - Regular expression that the image sequence names must match.
%          Image sequences which do not match the expression will not be
%          processed.
%
% See also:
% BaxterAlgorithms

% Add necessary paths.
if ~isdeployed
    subdirs = textscan(genpath(fileparts(mfilename('fullpath'))), '%s','delimiter',pathsep);
    addpath(subdirs{1}{:});
end

aRegExp = GetArgs({'RegExp'}, {'.*'}, true, varargin);

% Convert string inupt into a cell array with one cell.
if ~iscell(aExPaths)
    aExPaths = {aExPaths};
end

% Find all used image sequences in all experiments.
allSeqDirs = {};
allSeqPaths = {};
for i = 1:length(aExPaths)
    seqDirs = GetUseSeq(aExPaths{i});
    allSeqDirs = [allSeqDirs; seqDirs(:)]; %#ok<AGROW>
    allSeqPaths = [allSeqPaths; strcat(aExPaths{i}, filesep, seqDirs(:))]; %#ok<AGROW>
end

% Run the tracking.
parfor i = 1:length(allSeqPaths)
    if ~isempty(regexp(allSeqDirs{i}, aRegExp, 'once')) &&...
            ~HasVersion(allSeqPaths{i}, aVer)
        imData = ImageData(allSeqPaths{i}, 'version', aVer);
        SaveTrack(imData)
    end
end
end