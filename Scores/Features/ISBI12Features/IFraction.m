function oVal = IFraction(aBlob, aImProcessor, aInOut, aFrac)
% Average intensity in a region around the boundary or center of a blob.
%
% This feature computes the average intensity in a given fraction of the
% blob pixels, which is closest to the center or boundary of the blob. For
% example, the function can compute the average intensity of the 25% of the
% blob pixels which are closest to the boundary of the blob.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
% aImProcessor - ImageProcessor object for the image.
% aInOut - String ('inner' or 'outer') which indicates if the average
%          intensity should be computed over the pixels which are closest
%          to the center or the boundary of the blob.
% aFrac - The fraction of the pixels to compute the average intensity of,
%         given in per mille. If the value 250 is given as input, one
%         quarter of the pixels will be included in the average.
%
% Outputs:
% oVal - The computed feature value.
%
% See also:
% ComputeFeatures, IBoundary, ICenter, ICentroid

dist = aBlob.GetPixels(aImProcessor.GetDistIm());
im = aBlob.GetPixels(aImProcessor.GetNormIm());

switch lower(aInOut)
    case 'inner'
        [~, order] = sort(dist, 'descend');
    case 'outer'
        [~, order] = sort(dist, 'ascend');
    otherwise
        error(['The last input argument to IFraction has to be either '...
            '''inner'' or ''outer'''])
end

indices = order(1:ceil(length(order)*aFrac/1000));
oVal = mean(im(indices));
end