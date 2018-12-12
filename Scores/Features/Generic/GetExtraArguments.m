function [oFeatureNames, oArgs] = GetExtraArguments(aFeatureNames)
% Separates feature names into feature function names and inputs arguments.
%
% The names of features for classification start with the name of a
% function, and can be followed by input arguments to that function. The
% different parts of the feature names are separated by '_'. This function
% splits the feature names into function names and input arguments, and
% converts numerical inputs into double values. As an example, the feature
% name 'Texture_gradient_mean_2' is separated into the function name
% 'Texture', and the input arguments {'gradient', 'mean', 2}. In this case,
% the input arguments specify that the texture function should compute the
% mean gradient magnitude value for an image which has been down-sampled by
% a factor of 2.
%
% Inputs:
% aFeatureNames - Cell array with feature names.
%
% Outputs:
% oFeatureNames - Cell array with names of the functions that are used to
%                 compute the features.
% oArgs - Cell array where each cell is a cell array with input arguments
%         to the corresponding function.
%
% See also:
% ComputeFeatures, TheriaultFeatures, TransmissionFeatures

% Create empty cell arrays for the outputs.
oFeatureNames = cell(size(aFeatureNames));
oArgs = cell(size(aFeatureNames));

for i = 1:length(aFeatureNames)
    % Split the feature names into the parts separted by '_'.
    parts = regexp(aFeatureNames{i}, '_', 'split');
    
    % The first part is the function name.
    oFeatureNames{i} = parts{1};
    
    % The following parts are input arguments. Numerical input arguments
    % are converted into doubles.
    oArgs{i} = cell(length(parts)-1,1);
    for j = 2:length(parts)
        arg = parts{j};
        numArg = str2double(arg);
        if ~isnan(numArg)
            oArgs{i}{j-1} = numArg;
        else
            % The conversion to double failed (the input was not numeric).
            oArgs{i}{j-1} = arg;
        end
    end
end
end