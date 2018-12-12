function [oI, oBg] = BgSub_median(aImData, aFrame, aBreakPoints, varargin)
% Subtracts the median image from an image sequence.
%
% The function finds a background image by taking the median image through
% the time dimension of the image sequence. Then the background image is
% subtracted from images of the sequence.
%
% Inputs:
% aImData - ImageData object for the image sequence.
% aFrame - Frame index to read.
% aBreakPoints - Array with frames where media changes were performed. If
%                media changes were performed, separate background images
%                will be computed for the time intervals between media
%                changes.
%
% Property/Value inputs:
% CorrectLight - Name of method used to normalize the illumination across
%                frames.
% Channel - Index or name of the channel in which the background should be
%           removed. The default is the first channel.
%
% Outputs:
% oI - Background subtracted image.
% oBg - Background image.
%
% See also:
% BgSub_generic, BgSub_medianfit, BgSub_min, BgImage_median

% Parse property/value inputs.
[aCorrectLight, aChannel] =...
    GetArgs({'CorrectLight', 'Channel'}, {true, 1}, true, varargin);

% Compute background image.
if isempty(aBreakPoints)
    % Compute the background image for the entire sequence.
    oBg = BgImage_median(aImData, varargin{:});
else
    % Compute the background image for a specific time interval.
    [t1, t2] = MediaChange2TLims(aImData, aBreakPoints, aFrame);
    oBg = BgImage_median(aImData, 'TLimits', [t1,t2], varargin{:});
end

% Background subtraction.
I = aImData.GetIntensityCorrectedImage(aFrame, aCorrectLight,...
    'Channel', aChannel);
oI = I - oBg;
end