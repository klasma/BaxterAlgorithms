function oMoment = Hu(aBlob, aImProcessor, aOrder)
% Hu computes the first 7 Hu invariant moments of a Blob binary mask.
%
% In addition to the 7 Hu moments, the function also has an 8:th invariant
% moment. This moment has order 3 and is different form the Hu moment of
% order 3. This moment was taken from the Wikipedia article about Hu
% moments. All of the moments are invariant to rotation and scaling.
%
% Inputs:
% aBlob - Blob object.
% aImProcessor - ImageProcessor object for the image.
% aOrder - Index of the Hu moment. 8 gives a 3rd order moment which is not
%          a Hu moment.
%
% Outputs:
% oMoment - The computed invariant moment.
%
% References:
% [1] Theriault, D. H.; Walker, M. L.; Wong, J. Y. & Betke, M. Cell
%     morphology classification and clutter mitigation in phase-contrast
%     microscopy images using machine learning Mach. Vis. Appl., Springer,
%     2012, 23, 659-673
%
% [2] Hu, Visual Pattern Recognition by Moment Invariants
%
% See also:
% ComputeFeatures

% Compute the necessary scale invariant central moments.
if any([1 2 6 8] == aOrder)
    n02 = aImProcessor.GetEta(aBlob,0,2);
    n20 = aImProcessor.GetEta(aBlob,2,0);
end
if any([2 6 8] == aOrder)
    n11 = aImProcessor.GetEta(aBlob,1,1);
end
if any([3 4 5 6 7 8] == aOrder)
    n03 = aImProcessor.GetEta(aBlob,0,3);
    n12 = aImProcessor.GetEta(aBlob,1,2);
    n21 = aImProcessor.GetEta(aBlob,2,1);
    n30 = aImProcessor.GetEta(aBlob,3,0);
end

% Compute the correct Hu moment.
switch(aOrder)
    case 1
        oMoment = n20 + n02;
    case 2
        oMoment = (n20-n02)^2 + 4*n11^2;
    case 3
        oMoment = (n30-3*n12)^2 + (3*n21-n03)^2;
    case 4
        oMoment = (n30+n12)^2 + (n21+n03)^2;
    case 5
        oMoment = (n30-3*n12) * (n30+n12) * ((n30+n12)^2 - 3*(n21+n03)^2) +...
            (3*n21-n03) * (n21+n03) * (3*(n30+n12)^2 - (n21+n03)^2);
    case 6
        oMoment = (n20-n02) * ((n30+n12)^2 - (n21+n03)^2) +...
            4*n11 * (n30+n12) * (n21+n03);
    case 7
        oMoment = (3*n21-n03) * (n30+n12) * ((n30+n12)^2 - 3*(n21+n03)^2) -...
            (n30-3*n12) * (n21+n03) * (3*(n30+n12)^2 - (n21+n03)^2);
    case 8
        % Alternative third order moment. Not included in [1] or [2].
        oMoment = n11 * ((n30+n12)^2 - (n03+n21)^2) -...
            (n20-n02) * (n30+n12) * (n03+n21);
    otherwise
        error('There is no Hu moment with index %d.\n', aOrder)
end
end