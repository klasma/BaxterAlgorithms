function [oI, oBg] = BgSub_generic(aImData, aFrame, varargin)
% Subtracts the background from an image in an image sequence.
%
% The function will call one of the available background subtraction
% algorithms. Which one is determined by the setting SegBgSubAlgorithm. The
% function then attenuates regions with a high local variance in the
% background image, by the amount specified in the setting SegBgSubAtten.
%
% Inputs:
% aImData - ImageData object for the image sequence.
% aFrame - Frame number of the image to be background subtracted.
%
% Property/Value inputs:
% CorrectLight - Name of method used to normalize the illumination across
%                frames.
% BgSubAtten - Parameter multiplying the local variance of the background
%              image before it is used to attenuate the background
%              subtracted image in regions where the background has a lot
%              of texture. This is done to remove residual background in
%              regions that are hard to background subtract perfectly.
%
% Settings in aImData:
% SegBgSubAlgorithm - Name of the background subtraction algorithm to use.
% SegMediaChanges - Time points were media changes were performed. Some of
%                   the algorithms compute new background images for each
%                   media change.
%
% Outputs:
% oI - Background subtracted image.
% oBg - Background image.
%
% See also:
% BgSub_median, BgSub_min, Attenuate

% Parse property/value inputs.
[aCorrectLight, aBgSubAtten] =...
    GetArgs({'CorrectLight', 'BgSubAtten'}, {true, 0}, true, varargin);

% Apply the specified background subtraction algorithm.
switch aImData.Get('SegBgSubAlgorithm')
    case 'BgSub_median'
        [oI, oBg] = BgSub_median(...
            aImData,...
            aFrame,...
            aImData.Get('SegMediaChanges'),...
            'Channel', aImData.Get('SegChannel'),...
            'CorrectLight', aCorrectLight);
    case 'BgSub_min'
        [oI, oBg] = BgSub_min(...
            aImData,...
            aFrame,...
            'Channel', aImData.Get('SegChannel'));
    case 'BgSub_medianfit'
        [oI, oBg] = BgSub_medianfit(...
            aImData,...
            aFrame,...
            aImData.Get('SegMediaChanges'),...
            'Channel', aImData.Get('SegChannel'),...
            'CorrectLight', aCorrectLight);
    otherwise
        error('Unknown background subtraction algorithm')
end

% Attenuation of regions with high local variance in background image.
if aBgSubAtten > 0
    % Compute local variance.
    N = 2; % Use (2*2+1)x(2*2+1)=5x5 pixel neighborhoods.
    V = LocalVariance(oBg,N);
    V = log(1+V);
    % Leave everything below 5 times the median untouched.
    V = max(0,V-median(V(:))*5);
    
    oI = Attenuate(oI, V*aBgSubAtten);
end
end