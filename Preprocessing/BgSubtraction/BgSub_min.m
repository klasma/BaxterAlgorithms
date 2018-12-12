function [oI, oBg] = BgSub_min(aImData, aFrame, varargin)
% Subtracts the minimum image, taken over time, from an image sequence.
%
% The minimum image taken over the time dimension of the image sequence
% serves as a background image for fluorescent image sequences. The
% background image can then be removed to get rid of non-uniform
% illumination, and other stationary background features.
%
% Inputs:
% aImData - ImageData object for the image sequence.
% aFrame - Frame number to read.
%
% Outputs:
% oI - Background subtracted image.
% oBg - Background image.
%
% Property/Value inputs:
% Channel - Index or name of the channel in which the background should be
%           removed. The default is the first channel.
%
% See also:
% BgSub_generic, BgSub_median, BgSub_medianfit, BgImage_median

% Parse property/value inputs.
aChannel = GetArgs({'Channel'}, {1}, true, varargin);

% Compute background image.
oBg = BgImage_min(aImData, 'Channel', aChannel);

% Background subtraction.
I = aImData.GetDoubleImage(aFrame, 'Channel', aChannel);
oI = max(I - oBg + mean(oBg(:)), 0);
end