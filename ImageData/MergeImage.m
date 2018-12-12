function oIm = MergeImage(aImData, aFrame, varargin)
% Merges multiple channels into a single RGB image.
%
% The channel colors can be specified using SetFluorescenceParams. If both
% white light channels and fluorescence channels are merged, half the image
% intensity is fluorescence and half is white light. If there are only
% fluorescence channels or only white light channels, the channels are
% added and use the whole intensity range. In addition to the additional
% Property/Value inputs specified here, the function takes the same
% Property/Value inputs as imread.
%
% Inputs:
% aImData - ImageData object of the image sequence.
% aFrame - The desired frame in the sequence.
%
% Property/Value inputs:
% Visible - Binary array specifying what channels should be included in the
%           merge. The array must have one element for each channel.
%
% Outputs:
% oIm - 3-channel double image with values between 0 and 1.
%
% See also:
% aImData, SetFluorescenceParams

% Get additional inputs.
[mergeImageArgs, imreadArgs] = SelectArgs(varargin, {'Visible'});
visible = GetArgs(...
    {'Visible'},...
    {true(size(aImData.channelNames))},...
    true, mergeImageArgs);

if length(visible) ~= length(aImData.channelNames)
    error(['The length of the visible-array has to be equal to the '...
        'number of channels.'])
end

% Check for transmission channels with white light.
numGray = 0;  % The number of transmission microscopy (gray) channels.
numColored = 0;  % The number of fluorescence microscopy (colored) channels
for i = 1:length(aImData.channelNames)
    if ~visible(i)
        continue
    end
    if aImData.IsTransChannel(i)
        numGray = numGray + 1;
    else
        numColored = numColored + 1;
    end
end

% Allocation done inside the for-loop.
oIm = [];

% Add colored channels.
for i = 1:length(aImData.channelNames)
    
    % Don't perform computations for black channels.
    if ~visible(i) || all(aImData.channelColors{i} == 0)
        continue
    end
    
    % The gray scale image for the channel that will be added.
    c = aImData.GetDoubleImage(aFrame, 'Channel', i, imreadArgs{:})/255;
    
    if isempty(oIm)
        % The additional inputs in imreadArgs can make the size of c be
        % different from aImData.imageHeight x imData.imageWidth and
        % therefore the allocation can not be done outside the for-loop.
        oIm = zeros(size(c,1), size(c,2), 3);
    end
    
    cmin = aImData.channelMin(i);
    cmax = aImData.channelMax(i);
    
    
    % Modify the intensity range.
    if cmin > 0 || cmax < 1
        c = min(c, cmax); % Satturate.
        c = max(0, c-cmin+eps) / (cmax-cmin+eps); % Clip.
    end
    
    for ci = 1:3 % Add in red green and blue separately.
        if aImData.channelColors{i}(ci) > 0
            if numGray > 0 && numColored > 0
                % Half the intensity is fluorescence and half is white
                % light.
                oIm(:,:,ci) = oIm(:,:,ci) + c * 0.5 * aImData.channelColors{i}(ci); %#ok<AGROW>
            else
                % The whole intensity is either fluorescence or white
                % light.
                oIm(:,:,ci) = oIm(:,:,ci) + c * aImData.channelColors{i}(ci); %#ok<AGROW>
            end
        end
    end
end
end