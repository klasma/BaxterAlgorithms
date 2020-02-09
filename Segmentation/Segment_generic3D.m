function [oBlobs, oBw, oGray, oImages] = Segment_generic3D(aImData, aFrame, varargin)
% Runs 3D segmentation algorithms together with pre- and post-processing.
%
% The function runs other segmentation functions and allows pre- and
% post-processing to be done before and after the main segmentation
% function is called. In the pre-processing step, the function can perform
% intensity clipping, median filtering, and Gaussian smoothing. In the
% post-processing step, the function can fill holes, apply watershed
% transforms to break clusters, remove regions that are too small or too
% large, and apply morphological operations to the segmented cell regions.
% Using property/value inputs, a sub-volume can be specified for
% segmentation. This can save computation time when parameters are tweaked
% in SegmentationPlayer.
%
% Inputs:
% aImData - ImageData object for the image sequence.
% aFrame - The index of the frame to be segmented.
%
% Property/Value inputs:
% X1 - First pixel in x-dimension of sub-volume to be segmented.
% X2 - Last pixel in x-dimension of sub-volume to be segmented.
% Y1 - First pixel in y-dimension of sub-volume to be segmented.
% Y2 - Last pixel in y-dimension of sub-volume to be segmented.
% Z1 - First pixel in z-dimension of sub-volume to be segmented.
% Z2 - Last pixel in z-dimension of sub-volume to be segmented.
%
% Settings in aImData (these are only a few important ones):
% SegAlgorithm - The name of the segmentation algorithm that will be used.
% SegFillHoles - Fill holes in the segmentation mask if set to 1.
% SegMinArea - Minimum volume of segmented regions in voxels. No regions
%              are removed if the value is 0.
% SegMaxArea - Maximum volume of segmented regions in pixels. No regions
%              are removed if the value is inf.
%
% Outputs:
% oBlobs - Array of Blob objects representing the segmented regions.
% oBw - Binary segmentation mask where cell pixels are 1s.
% oGray - Z-stack before the thresholding step which creates cell regions.
% oImages - Struct with fields for intermediate processing steps. The
%           fields are named after the processing steps. The z-stacks
%           included in oImages vary depending on the segmentation
%           algorithm and the pre- and post-processing algorithms used.
%
% See also:
% SegmentSequence, SegmentationPlayer, Segment_generic,
% Segment_threshold3D, Segment_bandpass3D, Segment_precondPSF3D

% Parse property/value inputs.
[aX1, aX2, aY1, aY2, aZ1, aZ2] = GetArgs(...
    {'X1', 'X2', 'Y1', 'Y2', 'Z1', 'Z2'},...
    {1, aImData.imageWidth, 1, aImData.imageHeight, 1, aImData.numZ},...
    true, varargin);

if nargin == 2
    oBlobs = Segment_generic3D_blocks(aImData, aFrame, [8 4 4]);
    oImages = struct();
    return
end

I = aImData.GetDoubleZStack(aFrame, 'Channel', aImData.Get('SegChannel'));

if ~isempty(varargin)
    % Crop the input volume if cropping instructions are given.
    I = I(aY1:aY2, aX1:aX2, aZ1:aZ2);
end

[oBlobs, oBw, oGray, oImages] = Segment_generic3D_image(I, aImData, aFrame);
end