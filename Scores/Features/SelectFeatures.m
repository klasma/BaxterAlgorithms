function oFeatures = SelectFeatures(aFeatures, aNames, aSelection)
% Selects feature columns from a matrix of features.
%
% The feature matrix has one row for each blob and one column for each
% feature. This function selects the columns which correspond to features
% in a feature list and orders the columns according to the order in the
% list. The function generates an error if a selected feature is not
% included in the original feature matrix.
%
% Inputs:
% aFeatures - Feature matrix to select and order columns from.
% aNames - Cell array with names of the features in aFeatures, in the same
%          order as the columns of aFeatures.
% aSelection - Cell array with the names of the features that should be
%              selected.
%
% Outputs:
% oFeatures - Feature matrix where the columns correspond to the feature
%             names in aSelection.
% See also:
% ComputeFeatures, Classify

oFeatures = nan(size(aFeatures, 1), length(aSelection));
for i = 1:length(aSelection)
    index = find(strcmpi(aNames, aSelection{i}), 1, 'first');
    if isempty(index)
        error(['The feature "%s" needed for classification has not '...
            'been computed'], aSelection{i})
    end
    oFeatures(:,i) = aFeatures(:,index);
end
end