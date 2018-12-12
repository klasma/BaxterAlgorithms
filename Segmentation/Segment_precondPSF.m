function [oBw, oGray] =...
    Segment_precondPSF(aI, aPSF, aBeta, aIterations, aThreshold)
% Segments fluorescent particles using L1-regularized deconvolution.
%
% The algorithm can be used for detection of point shaped objects, if the
% PSF of the microscope is known. The algorithm performs deconvolution by
% solving the optimization problem: minimize ||y-Ax||_2^2 + beta*||x||_1
% subject to x >= 0, where y is a vector with pixel values from the
% microscope image, x is a vector representing the particle density, and A
% is a matrix representing the convolution of the particle density with the
% PSF of the microscope. The parameter beta is a regularization parameter
% which promotes a sparse solution. In the optimization problem it is
% assumed that the noise in the image is Gaussian, but we have seen that
% the algorithm works well for Poisson noise as well. The optimization
% problem is solved using convolutions and a multiplicative update. The
% algorithm can handle PSFs with both positive and negative values. Before
% the algorithm performs deconvolution, it removes background intensity.
% The details of the algorithm are described in [1] and [2], and the
% multiplicative update is described in [3]. We used the algorithm for
% tracking of the simulated particles in the ISBI 2012 Particle Tracking
% Challenge in [1] and [4].
%
% Inputs:
% aI - The image, to perform deconvolution on, in double format.
% aPSF - The name of a mat-file with a saved PSF. The file has to be
%        located in the folder named PSFs in the Files folder of the
%        program.
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
% References:
% [1] Chenouard, N.; Smal, I.; de Chaumont, F.; Maška, M.; Sbalzarini, I.
%     F.; Gong, Y.; Cardinale, J.; Carthel, C.; Coraluppi, S.; Winter, M.;
%     Cohen, A. R.; Godinez, W. J.; Rohr, K.; Kalaidzidis, Y.; Liang, L.;
%     Duncan, J.; Shen, H.; Xu, Y.; Magnusson, K. E. G.; Jaldén, J.; Blau,
%     H. M.; Paul-Gilloteaux, P.; Roudot, P.; Kervrann, C.; Waharte, F.;
%     Tinevez, J.-Y.; Shorte, S. L.; Willemse, J.; Celler, K.; van Wezel,
%     G. P.; Dan, H.-W.; Tsai, Y.-S.; Ortiz de Solórzano, C.; Olivo-Marin,
%     J.-C. & Meijering, E. Objective Comparison of Particle Tracking
%     Methods Nat. Methods, 2014, 11, 281-289
%
% [2] Yin, Z.; Kanade, T. & Chen, M. Understanding the phase contrast
%     optics to restore artifact-free microscopy images for segmentation
%     Med. image anal., Elsevier, 2012, 16, 1047-1062
%
% [3] Sha, F.; Lin, Y.; Saul, L. K.; & Lee, D. D. Multiplicative updates
%     for nonnegative quadratic programming. Neural Computation, 2007,
%     19(8), 2004-2031.
%
% [4] Magnusson, K. E. G. & Jaldén, J. Tracking of non-Brownian particles
%     using the Viterbi algorithm Proc. 2015 IEEE Int. Symp. Biomed.
%     Imaging (ISBI), 2015, 380-384
%
% See also:
% Segment_precondPSF3D, Segment_generic

% Load PSF from file.
tmp = load(FindFile('PSFs', aPSF));
PSF = tmp.PSF;

PSF2 = conv2(PSF,rot90(PSF,2));

% Positive and negative parts of the self-convolved PSF.
PSF2p = max(PSF2,0);
PSF2m = max(-PSF2,0);

% Global and local mean remover. The region used for local mean removal is
% often too large to remove local intensity variations.
Me = 30;
B = -1/((2*Me+1)^2)*ones(2*Me+1,2*Me+1);
B(Me+1,Me+1) = B(Me+1:Me+1)+1;
aI = aI-mean(aI(:));
aI = conv2(aI,B,'same');

% Optimization variables.
V = ones(size(aI));

B = -conv2(aI,PSF,'same');
B = B + aBeta/2;

% Perform iterations of the multiplicative update.
for k = 1:aIterations
    Dp = conv2(V,PSF2p,'same');
    Dm = conv2(V,PSF2m,'same');
    V = ((-B+sqrt(B.^2 + 4*Dp.*Dm)) ./ (2*Dp+1e-6*ones(size(V)))).*V;
end

% Threshold the deconvolved image to produce a segmentation.
oBw = (V > aThreshold);
oGray = V;
end