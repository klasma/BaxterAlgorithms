function oPosteriors = ChangePriors(aPosteriors, aOldPriors, aNewPriors)
% Corrects posteriors from a classifier with incorrect priors.
%
% ChangePriors recomputes posterior classification probabilities computed
% using incorrect priors. This function can be used if a classifier was
% trained using a training data set with the wrong proportions between
% samples from the different classes.
%
% Inputs:
% aPosteriors - Matrix where column i has posterior probabilities of class
%               i. Row j has the posteriors for feature vector j.
% aOldPriors - Array with incorrect priors used to compute aPosteriors.
% aNewPriors - Array with correct priors that should have been used.
%
% Outputs:
% oPosteriors - Matrix with corrected posteriors based on the priors in
%               aNewPriors.

% Scale the posteriors.
oPosteriors = aPosteriors .*...
    repmat(aNewPriors(:)' ./ aOldPriors(:)', size(aPosteriors,1), 1);

% Normalize so that the posteriors sum to 1.
oPosteriors = oPosteriors ./...
    repmat(sum(oPosteriors, 2), 1, size(oPosteriors,2));
end