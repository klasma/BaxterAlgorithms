function oProbs = ReplaceNanProbs(aProbs)
% Replaces NaNs in probabilities returned by classifiers.
%
% The function replaces NaNs in a matrix so that all rows with NaNs sum to
% 1 after the replacement. If there are multiple NaNs on the same row, all
% of the NaN elements will be given the same value. The function is used by
% Classify to fix  matrices from mnrval that contain NaNs.
%
% Inputs:
% aProbs - Probability matrix that could contain NaNs. Each row corresponds
%          to a classified feature vector and each column corresponds to a
%          class.
%
% Outputs:
% oProbs - Probability matrix where NaNs have been replaced.
%
% See also:
% Classify, ReplaceNanFeatures

oProbs = aProbs;
nanBin = isnan(aProbs);

if sum(nanBin(:)) == 0 % There is nothing to replace.
    return
end

% Compute replacement values.
nNan = sum(nanBin,2);
zeroNans = oProbs;
zeroNans(nanBin) = 0;
reps = (1 - sum(zeroNans,2)) ./ nNan;
repProbs = repmat(reps,1,size(oProbs,2));

% Replace NaNs.
oProbs(nanBin) = repProbs(nanBin);
end