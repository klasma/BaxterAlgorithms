function oDirs = GetUseSeq(aExPath)
% Returns a list of image sequences for which the 'use' parameter is 1.
%
% Image sequences for which the 'use' parameter is set to 0 are hidden from
% the user in all situations except in the settings GUI.
%
% Inputs:
% aExPath - Full path of the experiment folder.
%
% Outputs:
% oDirs - Column cell array with the names of all image sequences for which
%         the 'use' settings is set to 1. The full paths are not returned.
%
% See also:
% GetSeqDirs, GetNames

seqDirs = GetSeqDirs(aExPath);

spreadsheet = ReadSettings(aExPath);

keep = false(size(seqDirs));
for i = 1:length(seqDirs)
    use = GetSeqSettings(spreadsheet, seqDirs{i}, 'use');
    % use is empty if the property is not specified in the settings file.
    keep(i) = isempty(use) || strcmpi(use, '1');
end
oDirs = seqDirs(keep);

% Alphabetize the image sequence names.
oDirs = sort(oDirs);
end