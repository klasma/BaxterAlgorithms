function [oBw, oGray] = Segment_precondPSF3D(...
    aI, aPSF, aPSFSizeXY, aPSFSizeZ, aBeta, aIterations, aThreshold)
% Segments fluorescent particles in 3D using L1-regularized deconvolution.
%
% The function performs deconvolution by solving an L1-regularized least
% squares problem. The algorithm is a 3D generalization of the algorithm
% used in Segment_precondPSF. To save computation time the algorithm is
% constrained to handle only PSFs is with non-negative values. The
% algorithm in Segment_precondPSF reduces to this algorithm if the negative
% part of the PSF is set to 0.
%
% Inputs:
% aI - The image, to perform deconvolution on, in double format.
% aPSF - The name of a mat-file with a saved PSF. The file has to be
%        located in the folder named PSFs in the Files folder of the
%        program.
% aPSFSizeXY - The portion of the PSF to use in the xy-plane. The used part
%              of the PSF will be a square with the size length
%              PSFSizeXY*2+1. The saved PSF must be this large or larger.
% aPSFSizeZ - The portion of the PSF to use in the z-dimension. The used
%             part of the PSF will have aPSFSizeZ*2+1 z-slices. The saved
%             PSF must be this large or larger.
% aBeta - Regularization parameter for the L1-norm of the solution.
% aIterations - The number of iterations of the multiplicative update to
%               perform. 10 is usually enough. Lower values can be used to
%               speed up the computations.
% aThreshold - Detection threshold. Deconvolved pixels with higher values
%              will be included in the segmentation mask.
%
% Outputs:
% oBw - Binary segmentation mask where segmented pixels have the value 1.
% oGray - The deconvolved image.
%
% See also:
% Segment_precondPSF, Segment_generic

% Load PSF from file.
tmp = load(FindFile('PSFs', aPSF));
PSF = tmp.PSF;

% The number of voxels to cut on each side in x- and y-dimensions.
cutxy = (size(PSF,1) - (aPSFSizeXY*2+1))/2;
cutxy = max(cutxy,0);
% The number of voxels to cut on each side in the z-dimension.
cutz = (size(PSF,3) - (aPSFSizeZ*2+1))/2;
cutz = max(cutz,0);
% Reduce the size of the PSF.
PSF = PSF(1+cutxy:end-cutxy, 1+cutxy:end-cutxy, 1+cutz:end-cutz);

PSF2 = convn(PSF,PSF);

% The algorithm assumes that the negative part of the self-convolved PSF is
% zero. Only positive PSFs should be used with this method.
PSF2p = max(PSF2,0);

% Global and local mean remover. The processing is done separately for each
% z-slice. The region used for local mean removal is often too large to
% remove local intensity variations.
Mexy = 30;
Mez = 1;
B = -1/((2*Mexy+1)^2*(2*Mez+1))*ones(2*Mexy+1,2*Mexy+1,2*Mez+1);
B(Mexy+1,Mexy+1,Mez+1) = B(Mexy+1,Mexy+1,Mez+1)+1;
I = aI-mean(aI(:));
I = convn(I,B,'same');

% Optimization variables.
V = ones(size(I));

% Perform iterations of the multiplicative update.
Bp = max(convn(I,PSF,'same') - aBeta/2, 0);
for k = 1:aIterations
    Dp = convn(V,PSF2p,'same');
    V = (Bp ./ (Dp+1e-6*ones(size(V)))).*V;
end

% Threshold the deconvolved image to produce a segmentation.
oBw = (V > aThreshold);
oGray = V;
end