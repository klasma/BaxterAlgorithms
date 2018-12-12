function [oBW, oImages] = Segment_threshold3D(aI, aThreshold, aDarkOrBright)
% Segments a z-stack using thresholding.
%
% The function applies applies a threshold to convert it to a binary image.
% The binary image can either be everything above or below the threshold.
%
% Inputs:
% aI - Image to be segmented.
% aThreshold - Segmentation threshold.
% aDarkOrBright - 'dark' segments everything below the threshold. 'bright'
%                 segments everything above the threshold.
%
% Outputs:
% oBW - Binary matrix where segmented pixels are ones.
% oImages - Struct with intermediate processing results. The struct has the
%           field 'mask' which corresponds to the binary segmentation mask.

% Check inputs.
if ~strcmpi(aDarkOrBright, 'dark') && ~strcmpi(aDarkOrBright, 'bright')
    error(['aDarkOrBright was set to ''%s''. It mustbe ''dark'' or '...
        '''bright''.]', aDarkOrBright])
end

% Threshold.
oBW = aI/255 > aThreshold;

% Invert the image if the darkest pixels should be segmented.
if strcmpi(aDarkOrBright, 'dark')
    oBW = ~oBW;
end

oImages.mask = oBW;
end