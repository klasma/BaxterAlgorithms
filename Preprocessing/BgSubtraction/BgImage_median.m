function oImage = BgImage_median(aImData, varargin)
% Computes a background image using the median pixel values over time.
%
% Creates a background image by computing the median image over time of up
% to 100 evenly spaced images in the image sequence. If function handles
% are given as additional input arguments, these functions will be applied
% to the image before the background image is created. One can also compute
% a background image for an interval of time points. Background images are
% cached so that they do not need to be computed multiple times if the
% function is called multiple times with the same input arguments.
%
% Inputs:
% aImData - ImageData object for the image sequence.
%
% Property/Value inputs:
% TLimits - Two element array specifying the first and last frames to
%           include in background image computation.
% PPFuns - Function handles to functions that will be applied to the images
%          before the background image is calculated.
% CorrectLight - Method used to normalize the illumination.
% Channel - Index or name of the image channel to process. The default is
%           the first channel.
%
% Outputs:
% oImage - Background image.

persistent outputs % Cell array with all previously returned outputs.
persistent labels  % Labels that uniquely identify the different outputs.

% Parse additional input arguments.
[aTLimits, aPPFuns, aCorrectLight, aChannel] = GetArgs(...
    {'TLimits', 'PPFuns', 'CorrectLight', 'Channel'},...
    {[1, aImData.sequenceLength], {}, true, 1}, true, varargin);
if ~iscell(aPPFuns)
    aPPFuns = {aPPFuns};
end
if isnumeric(aChannel)
    aChannel = aImData.channelNames{aChannel};
end

% Name to save persistent data to.
funNames = cellfun(@func2str, aPPFuns, 'UniformOutput', false);
label = sprintf('%s %s %d %d %s %s',...
    aImData.seqPath,...
    aChannel,...
    aTLimits(1),...
    aTLimits(2),...
    aCorrectLight,...
    [funNames{:}]);

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
numFrames = aTLimits(2)-aTLimits(1)+1;
% downSample = max(1, floor(numFrames/50)); % Gives a sharp peak at 100.
downSample = max(1,ceil(numFrames/100)); % Plateaus at 100.
stack = zeros(aImData.imageHeight, aImData.imageWidth,...
    floor(numFrames/downSample), 'single'); % Use single to save some memory.
for i = 1 : floor(numFrames/downSample)
    im = aImData.GetIntensityCorrectedImage(aTLimits(1) + (i - 1) * downSample,...
        aCorrectLight, 'Channel', aChannel);
    for j = 1:length(aPPFuns) % Apply preprocessing functions.
        im = feval(aPPFuns{j}, im);
    end
    stack(:,:,i) = im;
end

% Compute the pixel-wise median. It is done in 500x500 pixel blocks to
% avoid out of memory errors.
m = size(stack, 1);
n = size(stack, 2);
for i = 1 : 500 : m
    for j = 1 : 500 : n
        oImage(i:min(i+500,m), j:min(j+500,n), :) =...
            median(stack(i:min(i+500,m), j:min(j+500,n), :), 3);
    end
end

oImage = double(oImage); % Convert from single to double.

% Store output so that it does not have to be recomputed next time.
outputs = [outputs; {oImage}];
labels = [labels; {label}];
end