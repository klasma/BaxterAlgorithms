function oImage = BgImage_min(aImData, varargin)
% Computes a background image using the minimum pixel values over time.
%
% Creates a background image by computing the minimum image intensity over
% time of up to 100 evenly spaced images in the image sequence. Background
% images are cached so that they do not need to be computed multiple times
% if the function is called multiple times with the same input arguments.
%
% Inputs:
% aImData - ImageData object associated with the image sequence.
%
% Property/Value inputs:
% Channel - Index or name of the image channel to process. The default is
%           the first channel.
%
% Outputs:
% oImage - Background image.
%
% See also:
% BgSub_min, BgImage_median

persistent outputs % Cell array with all previously returned outputs.
persistent labels  % Labels that uniquely identify the different outputs.

% Parse additional input arguments
aChannel = GetArgs({'Channel'}, {1}, true, varargin);

if isnumeric(aChannel)
    aChannel = aImData.channelNames{aChannel};
end

% Name to save persistent data to.
label = sprintf('%s %s', aImData.seqPath, num2str(aChannel));

% Return a pre-computed background image if there is one.
if any(strcmp(labels, label))
    oImage = outputs{strcmp(labels, label)};
    return
else
    % Clear pre-computed background images if they exceed 100 MB.
    info = whos('outputs');
    if info.bytes > 1E8
        outputs = {};
        labels = {};
    end
end

% Build a stack of all images that will be used to compute the background.
numFrames = aImData.sequenceLength;
% downSample = max(1, floor(numFrames/50)); % Gives a sharp peak at 100.
downSample = max(1,ceil(numFrames/100)); % Plateaus at 100.
% Use single to save some memory.
stack = zeros(aImData.imageHeight, aImData.imageWidth,...
    floor(numFrames/downSample), 'single');
for i = 1 : floor(numFrames/downSample)
    im = aImData.GetDoubleImage(1 + (i - 1) * downSample,...
        'Channel', aChannel);
    stack(:,:,i) = im;
end

% Compute the pixel-wise minimum. It is done in 500x500 pixel blocks to
% avoid out of memory errors.
m = size(stack, 1);
n = size(stack, 2);
for i = 1 : 500 : m
    for j = 1 : 500 : n
        oImage(i:min(i+500,m), j:min(j+500,n), :) =...
            min(stack(i:min(i+500,m), j:min(j+500,n), :), [], 3);
    end
end

oImage = double(oImage); % Convert from single to double.

oImage = SmoothComp(oImage,3);

% Store output so that it does not have to be recomputed next time.
outputs = [outputs; {oImage}];
labels = [labels; {label}];
end