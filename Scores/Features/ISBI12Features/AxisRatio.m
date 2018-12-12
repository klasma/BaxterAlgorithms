function oAxisRatio = AxisRatio(aBlob, ~)
% Feature which returns the axis ratio of a blob.
%
% Inputs:
% aBlob - Blob object to compute the axis ratio of.
%
% Outputs:
% oAxisRatio - The ratio between the major axis length and the minor axis
%              length of the blob.
%
% See also:
% ComputeFeatures

props = regionprops(aBlob.image, 'MinorAxisLength', 'MajorAxisLength');
oAxisRatio = props.MajorAxisLength / props.MinorAxisLength;
end