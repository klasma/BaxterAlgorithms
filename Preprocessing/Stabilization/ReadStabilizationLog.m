function oShifts = ReadStabilizationLog(aSeqPath)
% Load stabilization log files in the format used by ImageJ.
%
% Inputs:
% aSeqPath - Full path of the image sequence.
%
% Outputs:
% oShifts - Matrix where the first column contains x-shifts and the second
%           column contains y-shifts. The matrix has one row for each time
%           point, including the first time point where the shift is 0.
%
% See also:
% WriteStabilizationLog

imData = ImageData(aSeqPath);

oShifts = zeros(imData.sequenceLength, 2);

logFile = fullfile(imData.GetAnalysisPath(),...
    'StabilizationOffsets',...
    [imData.GetSeqDir() '.log']);

fid = fopen(logFile, 'r');
text = fscanf(fid, '%c', inf);
lines = strtrim(regexp(text, '\n', 'split'));
% The first two rows do not have shift information.
lines = lines(3:end);

for t = 1:imData.sequenceLength
    strings = regexp(lines{t}, ',', 'split');
    oShifts(t,1) = str2double(strings{3});
    oShifts(t,2) = str2double(strings{4});
end
end