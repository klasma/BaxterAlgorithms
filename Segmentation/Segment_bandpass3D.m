function [oBw, oGray, oImages] = Segment_bandpass3D(aI, aImData, aFrame,...
    aHighStd, aLowStd, aBgFactor, aThreshold, aDarkOrBright)
% Segments fluorescent z-stacks by bandpass filtering and thresholding.
%
% High frequency components are removed using convolution with a small
% Gaussian kernel. The low frequency components are found using convolution
% with a larger Gaussian kernel, and then subtracted from the image. The
% low frequency components can be multiplied by a user defined number
% before they are subtracted to give increased flexibility. If the number
% is set to 1, a traditional bandpass filter is achieved. The function
% works on both 2D and 3D image sequences. If the voxels height is
% different from the width and height, the standard deviations of the
% Gaussian kernels are scaled accordingly in the z-dimension.
%
% Inputs:
% aI - Gray scale double image with values between 0 and 255.
% aImData - ImageData object for the image sequence.
% aFrame - The index of the frame to be segmented.
% aHighStd - Standard deviation of the Gaussian kernel used to find the
%            background, in pixels. This parameter can be either a scalar
%            or a vector with two elements. If it is a vector, the first
%            element is used for the first image and the second element is
%            used for the last image. The values for images in the middle
%            of the sequence are computed using linear interpolation.
% aLowStd - Standard deviation of the Gaussian kernel used to remove noise,
%           in pixels. This parameter can be either a scalar or a vector
%           with two elements. If it is a vector, the first element is used
%           for the first image and the second element is used for the last
%           image. The values for images in the middle of the sequence are
%           computed using linear interpolation.
% aBgFactor - Factor that multiplies the background before it is
%             subtracted. 1 gives a true bandpass filter.
% aThreshold - Threshold above which pixels are considered to be a part of
%              the sample. Usually in the range [0 0.1].
% aDarkOrBright - If if this input argument is 'bright', pixels above the
%                 threshold will be segmented. If it is 'dark', pixels
%                 below the threshold will be segmented.
%
% Outputs:
% oBw - Logical image where segmented foreground pixels are ones.
% oGray - Bandpass filtered image before thresholding.
% oImages - Struct with intermediate processing results. The struct has the
%           following fields:
%    bg - Image filtered with the large Gaussian kernel.
%    smooth - Image filtered with the small Gaussian kernel.
%    bandpass - Bandpass filtered image.
%    mask - Binary mask after thresholding the filtered image.
%
% See also:
% Segment_bandpass

im = aI/255;
im = im - min(im(:));

if length(aHighStd) == 2
    n = aImData.sequenceLength;
    if aImData.sequenceLength > 1
        highStd = aHighStd(1) * (n-aFrame) / (n-1) +...
            aHighStd(2) * (aFrame-1) / (n-1);
    else
        highStd = mean(aHighStd);
    end
else
    highStd = aHighStd;
end

if length(aLowStd) == 2
    n = aImData.sequenceLength;
    if aImData.sequenceLength > 1
        lowStd = aLowStd(1) * (n-aFrame) / (n-1) +...
            aLowStd(2) * (aFrame-1) / (n-1);
    else
        lowStd = mean(aLowStd);
    end
else
    lowStd = aLowStd;
end

if aImData.numZ > 1
    % Set the height of the Gaussian kernel for 3D images.
    lowStd = lowStd * [1 1 1/aImData.voxelHeight];
    highStd = highStd * [1 1 1/aImData.voxelHeight];
end

multipleBlocks = any(aImData.Get('SegNumBlocks') > 1);

% Background.
im_bg = SmoothComp(im, highStd,...
    'Store', length(aHighStd) == 1 && ~multipleBlocks);
% Noise reduced image.
im_smooth = SmoothComp(im, lowStd,...
    'Store', length(aLowStd) == 1 && ~multipleBlocks);
% Get rid of background.
im_sample = im_smooth - im_bg * aBgFactor;

switch aDarkOrBright
    case 'bright'
        oBw = im_sample >  aThreshold;
    case 'dark'
        oBw = im_sample <  aThreshold;
end

if nargout > 1
    oGray = im_sample;
end

if nargout > 2
    oImages.bg = im_bg;
    oImages.smooth = im_smooth;
    oImages.bandpass = im_sample;
    oImages.mask = oBw;
end
end