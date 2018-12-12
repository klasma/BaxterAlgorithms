function oFeatures = ReplaceNanFeatures(aFeatures, aRep)
% Replaces NaNs in a feature matrix with other values.
%
% Inputs:
% aFeatures - Feature matrix where each row corresponds to an object to be
%             classified and each column corresponds to a feature.
% aRep - Array with a replacement value for each feature. The array has one
%        element for each column in aFeatures, and that value will be used
%        to replace NaNs in that column. The replacement values are usually
%        mean feature values computed over training datasets.
%
% Outputs:
% oFeatures - Feature matrix where NaNs have been replaced by values from
%             aRep.
%
% See also:
% Classify, FeatureMatrix, ReplaceNanProbs
%
% TODO: Vectorize the code if it is too slow.

oFeatures = aFeatures;
for i = 1:size(oFeatures,1)
    for j = 1:size(oFeatures,2)
        if isnan(oFeatures(i,j)) || isinf(oFeatures(i,j))
            oFeatures(i,j) = aRep(j);
        end
    end
end
end