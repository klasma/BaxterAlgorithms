function CTCTracking(aSeqPath, aVer, varargin)
% Runs cell tracking for optimization of TRA and SEG.
%
% Any settings can be optimized. Not just segmentation setttings.
%
% Inputs:
% aSeqPath - Full path of the image sequence.
% aVer - Name of the generated tracking version.
%
% Property/Value inputs:
% varargin - All valid settings parameters, and values that are fields in
%            AllSettings. The specified values override the values saved in
%            the settings files.

% Parse property/value inputs.
[evaluationArgs, settingsArgs] =...
    SelectArgs(varargin, {'SegmentationCores'});
[aSegmentationCores] = GetArgs({'SegmentationCores'}, {1},...
    true, evaluationArgs);

imData = ImageData(aSeqPath);
imData.version = aVer;

% Overwrite the saved settings with settings specified by the caller.
for i = 1:length(settingsArgs)/2
    imData.Set(settingsArgs{2*i-1}, settingsArgs{2*i});
end

SaveTrack(imData, 'SegmentationCores', aSegmentationCores)

fprintf('Done tracking\n')
end