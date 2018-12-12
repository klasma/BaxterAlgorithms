function StabilizeLK(aSrcSeqPath, aDstSeqPath, varargin)
% Performs image stabilization using the Lucas-Kanade algorithm [1].
%
% The implementation follows the image stabilization plugin for ImageJ [2],
% but it only implements transformations through translation. That is the
% type of transformation which occurs due to errors in the positioning of a
% microscope stage. The alignment can be performed on multiple scales from
% coarse to fine, by down-sampling the images. On the first scale, the
% image is down-sampled by a factor of 2^k and for each scale the
% down-sampling factor is cut in half until we come to the last scale where
% the full-sized images are aligned. This reduces the problems with local
% maxima.
%
% The function can stabilize multi-channel image sequences, by using one
% channel as a reference channel. The stabilization offsets are computed on
% the reference channel and then the offsets are applied to all other
% channels.
%
% The stabilization results produced are very similar to the stabilization
% results produced by the image  stabilizer for ImageJ. The main
% differences are caused by the fact that bilinear interpolation in ImageJ
% produces small errors on the right and bottom edges of the image. Smaller
% errors are introduces by differences in the numerical computations. A log
% file with computed offsets, with the same format as in the log files
% created by ImageJ, is created when the stabilized sequence has been
% saved. The log files can be used in the ImageJ plugin
% Image_Stabilizer_Log_Applier.
%
% The function can use a GPU for processing and is about 3 times faster if
% a GPU is available.
%
% Inputs:
% aSrcSeqPath - Full path of the folder containing the image sequence that
%               should be stabilized.
% aDstSeqPath - Full path of the folder that the stabilized image sequence
%               will be written to.
%
% Property/Value inputs:
% Channel - Name or index of the reference channel that should be used for
%           stabilization. The other channels are stabilized using the
%           shifts computed from the reference channel. The default is 1.
% MaxIter - The maximum number of iterations (incremental translations)
%           performed every time two images are aligned. The default is
%           200.
% Tol - The RMSE tolerance used in the stopping criteria for the alignment.
%       The alignment process is terminated when the relative change in the
%       RMSE between two iterations is below this value. The default is
%       1E-7.
% Alpha - Factor which specifies how much of the old reference image should
%         be kept when the reference image is updated. When an image has
%         been aligned to the reference image, the new reference image is
%         computed as new_reference = Alpha * old_reference + (1-alpha) *
%         aligned_image. The default is 0.95.
% PyramidLevel - The number of down-sampled images to process before the
%                full-sized image is aligned. The default is 1.
%
% References:
% [1] Lucas, Bruce D., and Takeo Kanade. "An iterative image registration
%     technique with an application to stereo vision." In IJCAI, vol. 81,
%     pp. 674-679. 1981.
%
% [2] K. Li, "The image stabilizer plugin for ImageJ,"
%     http://www.cs.cmu.edu/~kangli/code/Image_Stabilizer.html, February,
%     2008.
%
% See also:
% StabilizationGUI, CropExtrapolatedPixels

% Parse property/value inputs.
[aChannel, aMaxIter, aTol, aAlpha, aPyramidLevel] = GetArgs(...
    {'Channel', 'MaxIter', 'Tol', 'Alpha', 'PyramidLevel'},...
    {1, 200, 1E-7, 0.95, 1},...
    true,...
    varargin);

imData = ImageData(aSrcSeqPath);

% Get the index of the reference channel.
if isnumeric(aChannel)
    stabilizeChannel = aChannel;
else
    stabilizeChannel = find(strcmp(imData.channelNames, aChannel));
end

% Get indices of channels which are not reference channels.
otherChannels = setdiff(1:length(imData.channelNames), stabilizeChannel);

fprintf('Stabilizing %s\n', imData.seqPath)

% Create the output directory if it does not exist.
if ~exist(aDstSeqPath, 'dir')
    mkdir(aDstSeqPath)
end

% Save the first image of the reference channel without an offset.
fprintf('Stabilizing image %d / %d\n', 1, imData.sequenceLength)
im = imData.GetImage(1, 'Channel', stabilizeChannel);
dst = fullfile(aDstSeqPath, FileEnd(imData.filenames{stabilizeChannel}{1}));
imwrite(im, dst, 'Compression', 'lzw');

reference = double(im);

% Save the first images of non-reference channels without offsets.
for i = 1:length(otherChannels)
    im = imData.GetImage(1, 'Channel', otherChannels(i));
    dst = fullfile(aDstSeqPath, FileEnd(imData.filenames{otherChannels(i)}{1}));
    imwrite(im, dst, 'Compression', 'lzw');
end

% Matrix with offsets. The first column has x-offsets and the second has
% y-offsets.
translations = zeros(imData.sequenceLength, 2);

for t = 2:imData.sequenceLength
    fprintf('Stabilizing image %d / %d\n', t, imData.sequenceLength)
    
    % Image in the original numeric type.
    original = imData.GetImage(t, 'Channel', stabilizeChannel);
    try
        % Run on GPU.
        im = gpuArray(double(original));
    catch
        % Run on CPU if there is no GPU or if the GPU cannot be used.
        im = double(original);
    end
    
    trans = FindTranslation(im, reference, aPyramidLevel, aMaxIter, aTol);
    warpedIm = WarpTranslation(im, trans);
    
    % Update the reference image.
    reference = aAlpha*reference + (1-aAlpha)*warpedIm;
    
    translations(t,:) = gather(trans);
    
    % Saved the warped image from the reference channel.
    dst = fullfile(aDstSeqPath, FileEnd(imData.filenames{stabilizeChannel}{t}));
    imwrite(cast(gather(warpedIm), 'like', original), dst,...
        'Compression', 'lzw');
    
    % Apply the same offsets to all other channels and save the images.
    for i = 1:length(otherChannels)
        original = imData.GetImage(t, 'Channel', otherChannels(i));
        try
            % Run on GPU.
            im = gpuArray(double(original));
        catch
            % Run on CPU if there is no GPU or if the GPU cannot be used.
            im = double(original);
        end
        warpedIm = WarpTranslation(im, trans);
        dst = fullfile(aDstSeqPath, FileEnd(imData.filenames{otherChannels(i)}{t}));
        imwrite(cast(gather(warpedIm), 'like', original), dst,...
            'Compression', 'lzw');
    end
end

% Write the offsets to a log file with the format used in the image
% stabilizer for ImageJ.
[dstExPath, dstSeqDir] = FileParts2(aDstSeqPath);
logPath = fullfile(dstExPath,...
    'Analysis',...
    'StabilizationOffsets',...
    [dstSeqDir '.log']);
WriteStabilizationLog(logPath, dstSeqDir, translations)
end

function oTrans = FindTranslation(aIm, aReference, aPyramidLevel, aMaxIter, aTol)
% Aligns an image to a reference image using translations in x and y.
%
% The function performs the alignment on the gradient magnitudes of the
% two images. The alignment can be performed on multiple scales from coarse
% to fine, by down-sampling the two images. On the first scale, the image
% is down-sampled by a factor of 2^k and for each scale the down-sampling
% factor is cut in half until we come to the last scale where the
% full-sized images are aligned. This reduces the problems with local
% maxima.
%
% Inputs:
% aIm - Image that should be aligned to the reference image.
% aReference - Reference image.
% aPyramidLevel - The number of down-sampled images to process before the
%                 full-sized image is aligned.
% aMaxIter - The maximum number of iterations (incremental translations)
%            performed every time two images are aligned.
% aTol - The RMSE tolerance used in the stopping criteria for the
%        alignment. The alignment process is terminated when the relative
%        change in the RMSE between two iterations is below this value.
%
% Outputs:
% oTrans - Translation which aligns aIm to aReference. The output is a two
%          element array, where the first element is the translation in x
%          and the second element is the translation in y. If the x- and
%          y-values are positive, the image is shifted to the left and
%          upward respectively.

% Compute the gradient magnitude images.
pyramid = GradientMagnitude(aIm);
refPyramid = GradientMagnitude(aReference);

% Start with zero translation.
oTrans = zeros(2,1);

% Align donwsampled images from coarse to fine.
for i = aPyramidLevel:-1:1
    if min(size(aReference)) < 50 * 2^i
        % Skip levels where the down-sampled image is too small.
        continue
    end
    
    % Down-sample the current image and the reference.
    smallPyramid = pyramid(1:2^i:end, 1:2^i:end);
    smallRefPyramid = refPyramid(1:2^i:end, 1:2^i:end);
    
    % Compute the best translation on this level.
    oTrans = EstimateTranslation(oTrans, smallPyramid, smallRefPyramid, aMaxIter, aTol);
    
    % Up-sample the translation for the following scale.
    oTrans = oTrans * 2^i;
end

% Align the full-sized images, using the translation from the down-sampled
% image as a starting point, if aPyramidLevel > 0.
oTrans = EstimateTranslation(oTrans, pyramid, refPyramid, aMaxIter, aTol);
end

function oTrans = EstimateTranslation(aTrans, aIm, aReference, maxIter, aTol)
% Aligns images by translation so that the RMSE between them is minimized.
%
% The optimization is done iteratively. The reference image is assumed to
% be linear around each pixel and based on that assumption, the translation
% which minimizes the RMSE is computed. The current image is then warped
% using the computed translation. Then the next iteration finds a
% refinement to the translation, which further decreases the RMSE.
%
% Inputs:
% aTrans - Starting guess for the translation.
% aIm - Image (gradient magnitude) that should be aligned to the reference.
% aReference - Reference image (gradient magnitude).
% aMaxIter - The maximum number of iterations (incremental translations) to
%            be performed.
% aTol - The RMSE tolerance used in the stopping criteria for the
%        alignment. The alignment process is terminated when the relative
%        change in the RMSE between two iterations is below this value.
%
% Outputs:
% oTrans - Translation which aligns aIm to aReference. The output is a
%          two element array, where the first element is the translation in
%          x and the second element is the translation in y. If the x- and
%          y-values are positive, the image is shifted to the left and
%          upward respectively.

% Compute x- and y-components of the gradient using the Sobel operator.
[dxRef, dyRef] = Gradient(aReference);

% The best offset found so far.
oTrans = aTrans;
bestTrans = aTrans;

h = zeros(2);
h(1,1) = gather(dxRef(:)' * dxRef(:));
h(2,1) = gather(dxRef(:)' * dyRef(:));
h(1,2) = gather(dyRef(:)' * dxRef(:));
h(2,2) = gather(dyRef(:)' * dyRef(:));

oldRmse = inf;
minRmse = inf;

for iter = 0:maxIter-1
    % Warp the input image to create the current aligned image.
    out = WarpTranslation(aIm, oTrans);
    
    error = out - aReference;  % Error between reference and current image.
    rmse = sqrt(mean(error(:).^2));
    
    if iter > 0
        if rmse < minRmse
            % Only update the warp if the error is reduced. It happens that
            % the error increases, but after that it seems to continue
            % increasing. Therefore it could make sense to terminate as
            % soon as the error is not reduced. It also seems like the RMSE
            % is not always a good measure of the error. From the error
            % image it can seem like the alignment gets better after
            % further iterations, even though the RMSE increases. In that
            % case it could make sense to not look at the RMSE at all and
            % only terminate once the tolerance condition is met.
            bestTrans = oTrans;
            minRmse = rmse;
        end
        % Terminate when the rmse changes by less than the tolerance.
        if abs(oldRmse - rmse) / (oldRmse + eps(0)) < aTol
            break;
        end
    end
    oldRmse = rmse;
    
    dp = zeros(2,1);
    dp(1) = gather(dxRef(:)' * error(:));
    dp(2) = gather(dyRef(:)' * error(:));
    
    % Solves the equation in the top right corner of page 124 in [1]. dp is
    % the estimated offset that should be added to the reference image in
    % order to minimize the RMSE between the current image and the
    % reference. Given that wp is the offset that should be added to the
    % current image in order to align it to the reference image, we should
    % subtract wp from the offsets computed so far (oTrans).
    dp = h \ dp;
    
    oTrans = oTrans - dp;
end
oTrans = bestTrans;
end

function oIm = WarpTranslation(aIm, aTrans)
% Warps an image using translations in the x- and y-directions.
%
% Positive x-translations shift the image to the left and positive
% y-translations shift the image upward. The translations are performed
% using bilinear interpolation. Pixel values outside the input image are
% extrapolated using the closest pixel on the image border. The bilinear
% interpolation is computed as the weighted sum of 4 images.
%
% Inputs:
% aIm - Image to be warped.
% aTrans - Two element vector with translations. The first element is x and
%          the second element is y.
%
% Outputs:
% oIm - Warped image.

[h,w] = size(aIm);

% x-coordinates before interpolation points.
x1 = (1:w) + floor(aTrans(1));
% x-coordinates after interpolation points.
x2 = x1 + 1;

% Move interpolation points outside the image to the closest border pixels.
x1(x1 < 1) = 1;
x1(x1 > w) = w;
x2(x2 < 1) = 1;
x2(x2 > w) = w;

% y-coordinates before interpolation points.
y1 = (1:h) + floor(aTrans(2));
% y-coordinates after interpolation points.
y2 = y1 + 1;

% Move interpolation points outside the image to the closest border pixels.
y1(y1 < 1) = 1;
y1(y1 > h) = h;
y2(y2 < 1) = 1;
y2(y2 > h) = h;

% Weights used in bilinear interpolation.
alpha = aTrans(1) - floor(aTrans(1));  % x
beta = aTrans(2) - floor(aTrans(2));  % y

oIm =...
    (1-alpha) * (1-beta) * aIm(y1,x1) +...
    (1-alpha) * beta     * aIm(y2,x1) +...
    alpha     * (1-beta) * aIm(y1,x2) +...
    alpha     * beta     * aIm(y2,x2);
end

function [oGx, oGy] = Gradient(aIm)
% Computes the gradient of an image in the x- and y-directions.
%
% The function computes the gradients using the center difference in the
% middle of the image and the forward/backward differences at the edges.
% The function gives the same output as the built in function gradient, but
% it is slightly faster and can be executed on a GPU from a deployed
% application. The built in function causes an error when it is executed on
% a GPU from a deployed application created with MATLAB 2015b.

oGx  = zeros(size(aIm), 'like', aIm);
oGy  = zeros(size(aIm), 'like', aIm);

% Forward/backward differences on the edges.
oGy(1,:) = aIm(2,:) - aIm(1,:);
oGy(end,:) = aIm(end,:) - aIm(end-1,:);
oGx(:,1) = aIm(:,2) - aIm(:,1);
oGx(:,end) = aIm(:,end) - aIm(:,end-1);

% Center differences in the center.
oGy(2:end-1,:) = (aIm(3:end,:) - aIm(1:end-2,:)) / 2;
oGx(:,2:end-1) = (aIm(:,3:end) - aIm(:,1:end-2)) / 2;
end

function oIm = GradientMagnitude(aIm)
% Computes the gradient magnitude using the Sobel operator.
%
% Inputs:
% aIm - Image to computed the gradient magnitude of.
%
% Outputs:
% oIm - Gradient magnitude image.

oIm = ZeroBorders(imgradient(aIm));
end