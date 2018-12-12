function oProbs = ExtrapProbs(aProbs, aN, aAlpha)
% Extrapolates probability mass functions (PMFs) to infinity.
%
% The PMF p(k) is assumed to be defined over k = 0,1,...,K-1 and we assume
% that p(K-1) represents the probability Pr(k' >= K-1) in an extrapolated
% distribution p'(k'). We also assume that the tail of the distribution is
% defined by a geometric distribution so that
%
% p'(k') = p(k)                             if k < K-1
%          p(K-1)*Ge(k'-(K-1); 1-alpha)     if k >= K-1
%
% for k' = 0,1,...,N-1, where Ge(x,lambda) = lambda*(1-lambda)^x is the
% geometric distribution. This means that the probability decreases by a
% factor alpha when k' increases  by 1, for k' >= K-1. The extrapolated
% distribution p'(k') does not necessarily sum to 1, because the tail is
% truncated, but this should not cause any problems as the track linking
% algorithm extrapolates count scores linearly outside the defined range.
%
% Inputs:
% aProbs - MxK matrix where every row defines a separate PMF from 0 to K-1.
% aN - The desired length of the extrapolated PMF vectors.
% aAlpha - The factor by which the probabilities decrease in the
%          extrapolated region.
%
% Outputs:
% oProbs - MxaN matrix with the extrapolated distributions p'(k') as rows.
%
% See also:
% Classify, CountScores

K = size(aProbs,2);

% If the input distributions are already long enough they are not changed.
if K >= aN
    oProbs = aProbs;
    return
end

% Truncated geometric distribution Ge(1-aAlpha).
geDist = (1-aAlpha)*aAlpha.^(0:aN-K);

oProbs = [aProbs(:,1:K-1)...
    aProbs(:,K) * geDist];
end