function oMatrix = FeatureMatrix(aBlobs, aFeatureNames)
% Extracts already computed features from blobs and puts them in a matrix.
%
% Inputs:
% aBlobs - Array of Blob objects where the features have been computed and
%          placed in the property "features".
% aFeatureNames - Cell array with feature names. An error occurs if the
%                 requested feature has not been computed.
%
% Outputs:
% oMatrix - Matrix with feature values for all blobs. Rows correspond to
%           blobs and columns correspond to features.
%
% See also:
% Blob, ComputeFeatures

% Replace old aliases with the current feature names.
featureNames = SubstituteFeatureNames(aFeatureNames);

oMatrix = nan(length(aBlobs), length(featureNames));

for i = 1:length(aBlobs)
    for j = 1:length(featureNames)
        oMatrix(i,j) = aBlobs(i).features.(featureNames{j});
    end
end
end