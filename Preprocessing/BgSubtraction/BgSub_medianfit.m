function [oIm, oBg] = BgSub_medianfit(aImData, aFrame, aBreakPoints, varargin)
% Subtracts a background computed as a linear combination of median images.
%
% The function creates a basis of median background images for all time
% intervals between media changes and projects the images on the subspace
% spanned by the basis to create background images for the images. To use
% the end of the sequence you need to specify the image after the last
% frame as a media change. Otherwise the images after the last media
% changes will not be used to create a background image in the basis. This
% is done to avoid situations where a small number of images give rise to a
% basis vector by mistake.
%
% Inputs:
% aImData - ImageData object for the image sequence.
% aFrame - Frame to subtract the background from.
% aBreakPoints - Frames of media changes.
%
% Property/Value inputs:
% CorrectLight - Name of method used to normalize the illumination across
%                frames.
% Channel - Index or name of the channel in which the background should be
%           removed. The default is the first channel.
%
% Outputs:
% oIm - Background subtracted image.
% oBg - Background image.
%
% See also:
% BgSub_generic, BgSub_median, BgSub_min, BgImage_median

persistent bases   % Pre-computed bases of different image sequences.
persistent labels  % Unique labels of the pre-computed bases.

% Parse property/value inputs.
[aCorrectLight, aChannel] =...
    GetArgs({'CorrectLight', 'Channel'}, {true, 1}, true, varargin);

% Convert channel indices to channel names.
if isnumeric(aChannel)
    aChannel = aImData.channelNames{aChannel};
end

% Create a label for the basis of background images.
label = sprintf('%s %s %s %s',...
    aImData.seqPath, aChannel, num2str(aBreakPoints), aCorrectLight);

% Create a basis of background images if it has not been computed before.
if any(strcmp(labels, label))
    bgBasis = bases{strcmp(labels, label)};
else
    % Clear pre-computed bases if they take up more than 100 MB.
    info = whos('bases');
    if info.bytes > 1E8
        bases = {};
        labels = {};
    end
    
    % If no media changes are specified this will reduce to BgSub_median.
    if ~isempty(aBreakPoints)
        bp = unique([1 aBreakPoints(aBreakPoints <= aImData.sequenceLength+1)]);
    else
        bp = [1, aImData.sequenceLength];
    end
    k = length(bp)-1; % Number of images in the basis
    bgBasis = nan(aImData.imageWidth*aImData.imageHeight, k);
    for i = 1:k
        bgIm = BgImage_median(aImData,...
            'TLimits', [bp(i),bp(i+1)-1], varargin{:});
        bgBasis(:,i) = bgIm(:);
    end
    
    % Store the computed basis for future computations.
    bases = [bases; {bgBasis}];
    labels = [labels; {label}];
end

% Read image.
im = aImData.GetIntensityCorrectedImage(aFrame, aCorrectLight,...
    'Channel', aChannel);

% Find the linear combination of background images that gets closest to the
% current image.
x = bgBasis \  im(:);
% bgBasis*x is the projection of im onto bgBasis.
oBg = reshape(bgBasis*x, size(im));
% Subtract the background image.
oIm = im - oBg;
end