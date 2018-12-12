function ComputeFeatures(aImProcessor, aBlobs, aFeatureNames, aFeatureFunctionNames, aFeatureArgs)
% Computes blob features for classification.
%
% The computed feature values are stored as fields of the property
% 'features' in the Blob objects. If the 'features' property already has a
% field with the desired feature name, the feature will not be recomputed.
% This can save time if blobs from an old segmentation are loaded in
% SegmentSequence.
%
% Inputs:
% aImProcessor - ImageProcessor object for the current image.
% aBlobs - Blobs in the current image, for which features will be computed.
% aFeatureNames - Cell array with the full feature names. The feature names
%                 consist of parts separated by '_'. The first part is the
%                 feature function name and the following parts are input
%                 arguments for the feature function. The last part can be
%                 'log' or 'log10', indicating that the natural logarithm
%                 or the 10-logarithm should be applied to the feature. The
%                 feature names will be used as field names in the
%                 'features' property in the Blob objects.
% aFeatureFunctionNames - Cell array with feature function names.
% aFeatureArgs - Cell array with where each cell is a cell array with input
%                arguments for the corresponding feature function.
%
% See also:
% NecessaryFeatures, Classify, Blob, SegmentSequence

fprintf('Computing features for image %d / %d\n',...
    aImProcessor.GetT(), aImProcessor.imData.sequenceLength)

% Convert the feature function names into function handles.
functions = cellfun(@str2func, aFeatureFunctionNames, 'UniformOutput', false);

for i = 1:length(aBlobs)
    for j = 1:length(aFeatureNames)
        if ~isfield(aBlobs(i).features, aFeatureNames{j})
            if any(isnan(aBlobs(i).boundingBox))
                % Set all features to NaN for point blobs.
                aBlobs(i).features.(aFeatureNames{j}) = nan;
            else
                % A feature can be transformed using the natural logarithm
                % or the 10-logarithm by appending '_log' or 'log10' to the
                % feature name. This is handled by the if-statements below,
                % which check if the last feature argument is 'log' or
                % 'log10'. The logarithms are computed here, and the
                % feature arguments 'log' and 'log10' are not sent to the
                % feature functions.
                if ~isempty(aFeatureArgs{j}) && strcmpi(aFeatureArgs{j}{end}, 'log')
                    aBlobs(i).features.(aFeatureNames{j}) =...
                        log(feval(functions{j}, aBlobs(i), aImProcessor, aFeatureArgs{j}{1:end-1}));
                elseif ~isempty(aFeatureArgs{j}) && strcmpi(aFeatureArgs{j}{end}, 'log10')
                    aBlobs(i).features.(aFeatureNames{j}) =...
                        log10(feval(functions{j}, aBlobs(i), aImProcessor, aFeatureArgs{j}{1:end-1}));
                else
                    aBlobs(i).features.(aFeatureNames{j}) =...
                        feval(functions{j}, aBlobs(i), aImProcessor, aFeatureArgs{j}{:});
                end
            end
        end
    end
end
end