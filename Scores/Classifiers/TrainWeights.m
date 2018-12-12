function oWeights = TrainWeights(aSamples, aClasses)
% Computes weights for training of classifiers, based on class frequencies.
%
% The function computes the weights of different classes based on the
% number of samples in each class. The class with the fewest samples gets
% the weight 1, a class with twice as many samples gets the weight 2 and so
% on. The weights are used as input to Train.
%
% Inputs:
% aSamples - Vector where every element is a class index.
% aClasses - Indices of the classes to compute weights for. Classes that
%            are in aSamples but not in aClasses are not counted.
%
% Outputs:
% oWeights - The training weights of the classes.
%
% See also:
% Train

freq = nan(size(aClasses));
for i = 1:length(aClasses)
    freq(i) = sum(aSamples == aClasses(i));
end
oWeights = freq / min(freq);
end