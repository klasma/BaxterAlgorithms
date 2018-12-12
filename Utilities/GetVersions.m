function oVersions = GetVersions(aSeqPath, varargin)
% Returns the tracking versions that exist for one or multiple sequences.
%
% The function will both check that a file with tracking results exists and
% that it is not empty.
%
% Inputs:
% aSeqPath - Full path of one image sequence or cell array with multiple
%            paths.
%
% Property/Value inputs:
% WithCellData - If this input is set to true, the version names will have
%                the prefix 'CellData', like the directories where the
%                cells tracking results are saved.
%
% Outputs:
% oVersions - Cell array with alphabetically ordered version names. If the
%             input is a cell array of sequence paths, the output will be a
%             cell array with one cell for each sequence. Each cell will
%             then contain a cell array with version names for the
%             corresponding image sequence.
%
% See also:
% HasVersion, GetNames

if iscell(aSeqPath)
    % Apply the function to all cells of a cell input.
    oVersions = cellfun(@(x)GetVersions(x, varargin{:}), aSeqPath,...
        'UniformOutput', false);
    return
end

% Get property/value inputs.
aWithCD = GetArgs({'WithCellData'}, {false}, true, varargin);

exPath = FileParts2(aSeqPath);
analysisPath = fullfile(exPath, 'Analysis');

% Find all version directories of the experiment.
versionDirs = GetNames(analysisPath, '');
versionDirs = regexpi(versionDirs, '^celldata.*', 'match', 'once');
versionDirs(cellfun(@isempty, versionDirs)) = [];
versionDirs = sort(versionDirs);

% Find which version directories have tracking results for this particular
% image sequence.
oVersions = cell(size(versionDirs));
index = 1;
for i = 1:length(versionDirs)
    if HasVersion(aSeqPath, versionDirs{i}(9:end))
        if aWithCD
            oVersions{index} = versionDirs(i);
        else
            oVersions{index} = versionDirs{i}(9:end);
        end
        index = index + 1;
    end
end
oVersions = oVersions(1:index-1)';
end