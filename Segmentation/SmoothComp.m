function oImage = SmoothComp(aImage, aSigma, varargin)
% Applies Gaussian smoothing to an image without making the borders dark.
%
% The correction is performed through division by a smoothed image of ones.
% This is equivalent to taking the weighted average of the kernel pixels
% that fall inside the image. To save computation, the smoothed image of
% ones is stored in a persistent variable which is reset whenever the image
% size changes. The persistent variable can store smoothed images for
% multiple sigmas though. The function works for arrays with an arbitrary
% number of dimensions.
%
% Inputs:
% aImage - Image to be smoothed.
% aSigma - Standard deviation of the Gaussian kernel. The parameter can be
%          either a scalar or a vector with a separate standard deviation
%          for each image dimension.
%
% Parameter/Value inputs:
% Store - Specify as false if you don't want to cache smoothed unit images.
%
% Outputs:
% oImage - Image where smoothing has been applied.
%
% See also:
% Smooth

persistent pOnes    % Cell array of stored smoothed images of ones.
persistent pSigmas  % Cell array of standard deviations.
persistent pSz      % The size of the previous image processed.

% Parse property/value inputs.
aStore = GetArgs({'Store'}, {true}, 1, varargin);

% Reuses an old smoothed image of ones if possible or computes a new one.
if ~aStore
    sOnes = Smooth(ones(size(aImage)), aSigma);
elseif isequal(size(aImage), pSz)
    index = find(cellfun(@(x)isequal(x, aSigma), pSigmas));
    
    if ~isempty(index)
        % Reuse a stored value.
        sOnes = pOnes{index};
    else
        % Add a new value, since the image size has not changed.
        sOnes = Smooth(ones(size(aImage)), aSigma);
        
        pOnes = [pOnes; {sOnes}];
        pSigmas = [pSigmas; {aSigma}];
        if length(pOnes) > 10
            pOnes = pOnes(end-9:end);
            pSigmas = pSigmas(end-9:end);
        end
    end
else
    % The image size has changed, so the persistent variables are reset to
    % conserve memory.
    sOnes = Smooth(ones(size(aImage)), aSigma);
    
    pOnes = {sOnes};
    pSigmas = {aSigma};
    pSz = size(aImage);
end

oImage = Smooth(aImage, aSigma) ./ sOnes;
end