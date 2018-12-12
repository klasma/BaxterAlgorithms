function oFeature = Jaccard(aBlob1, aBlob2)
% Computes the Jaccard similarity index between two blobs.
%
% The Jaccard similarity index is the intersection of the binary masks,
% divided by the union of the binary masks. The Jaccard similarity index
% can be used as a measure of segmentation accuracy and as a feature or
% likelihood for classification of migration events. The measure is
% symmetric in the two input blobs.
%
% Inputs:
% aBlob1 - First blob object.
% aBlob2 - Second blob object.
%
% Outputs:
% oFeature - Jaccard similarity index for the binary masks of aBlob1 and
%            aBlob2.
%
% See also:
% MigLogLikeList_Jaccard

intersection = Overlap(aBlob1, aBlob2);
if intersection == 0
    oFeature = 0;
    return
end

union = aBlob1.GetArea() + aBlob2.GetArea() - intersection;

oFeature = intersection / union;
end