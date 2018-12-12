classdef ImageProcessor < handle
    % Computes and caches images and values used for feature computation.
    %
    % This class computes and caches intermediate processing results which
    % are used by functions that compute blob features for classification.
    % Most of the intermediate processing results are images, such as the
    % background subtracted image, the local variance image, and different
    % gradient magnitude images. Some other intermediate results are
    % computed directly from the binary masks of the blobs. The caching is
    % used to speed up the processing. The use of the ImageProcessor class
    % also makes the feature computation structured and modular. All
    % functions that compute features should take a Blob object as the
    % first input argument and an ImageData object as the second input
    % argument. An ImageProcessor object is created from an ImageData
    % object and a frame number. The ImageProcessor object can then only be
    % used to compute and cache intermediate results in that particular
    % image sequence and frame. In order to make computations for feature
    % that depend on the binary segmentation mask, the binary segmentation
    % mask need to be specified using the function SetBwIm.
    %
    % See also:
    % ComputeFeatures
    
    properties
        imData          % ImageData object of the image sequence.
    end
    
    properties (Access = private)
        t               % The time point for which we are currently processing images. This cannot be changed.
        rawIm           % Unprocessed double image.
        im              % Light corrected or raw image.
        normIm          % Background subtracted image.
        zeroMinIm       % Image with a minimum value of 0.
        gradXIm         % X-component of the gradient.
        gradYIm         % Y-component of the gradient.
        distGradXIm     % X-component of the gradient of the distance transform of the segmentation mask.
        distGradYIm     % Y-component of the gradient of the distance transform of the segmentation mask.
        distIm          % Distance transform of the segmentation mask.
        bgIm            % Background image.
        bgNormIm        % Background image normalized to have 0 mean.
        bgVarIm         % Local variance of the background image.
        prevDiffIm      % The current image minus the previous image.
        nextDiffIm      % The next image minus the current image.
        locVarIm        % Local variance image.
        loG5Im          % 5-point approximation of the Laplacian (of smoothed image).
        locMaxIm        % Binary image with local maxima.
        locMinIm        % Binary image with local minima.
        smoothIm        % Smoothed image.
        bwIm            % Segmentation mask.
        preThresholdIm  % Image that was thresholded to produce the segmentation mask.
        gradientKIm     % Gradient magnitude computed using down-sampling with a factor of K.
        laplacianKIm    % Laplacian computed using down-sampling with a factor of K.
        eta             % Scale invariant moments of blobs in the image.
        xbar            % Mean x-coordinates of blobs in the image.
        ybar            % Mean y-coordinates of blobs in the image.
    end
    
    methods
        function this = ImageProcessor(aImData, aT)
            % Makes an ImageProcessor object for a specific image sequence.
            %
            % Inputs:
            % aImData - ImageData object for the image sequence.
            % aT - The index of the image that will be processed.
            
            this.imData = aImData;
            this.t = aT;
            this.gradientKIm = cell(3,1);
            this.laplacianKIm = cell(3,1);
        end
        
        function oT = GetT(this)
            % Returns the index of the image that this object can process.
            %
            % The t-variable itself is private, as an object can only
            % process one image.
            
            oT = this.t;
        end
        
        function oIm = GetRawIm(this)
            % Returns the unprocessed double image.
            %
            % The image can have values between 0 and 255.
            
            if isempty(this.rawIm)
                this.rawIm = this.imData.GetDoubleZStack();
            end
            oIm = this.rawIm;
        end
        
        function oIm = GetIm(this)
            % Returns the image used for segmentation.
            %
            % This image can be either a double image between 0 and 255 or
            % a light corrected version of that image.
            
            if isempty(this.im)
                this.im = this.imData.GetIntensityCorrectedImage(this.t,...
                    this.imData.Get('SegLightCorrect'));
            end
            oIm = this.im;
        end
        
        function oIm = GetZeroMinIm(this)
            % Returns an image where the minimum value has been subtracted.
            %
            % The image can have values between 0 and 255.
            
            if isempty(this.zeroMinIm)
                this.zeroMinIm = this.GetPreThresholdIm();
                this.zeroMinIm = this.zeroMinIm - min(this.zeroMinIm(:));
            end
            oIm = this.zeroMinIm;
        end
        
        function oNormIm = GetNormIm(this)
            % Returns a background subtracted image.
            %
            % If there is no background subtraction algorithm specified,
            % the function assumes that the mean intensity is background.
            % The function also cashes the background image. The
            % segmentation options specify what background subtraction
            % algorithm will be used.
            
            if isempty(this.normIm)
                if strcmpi(this.imData.Get('SegBgSubAlgorithm'), 'none')
                    this.bgIm = ones(size(this.GetIm())) *...
                        mean(mean(mean(this.GetIm())));
                    this.normIm = this.GetIm() - this.bgIm;
                else
                    [this.normIm, this.bgIm] = BgSub_generic(this.imData, this.t,...
                        'CorrectLight', this.imData.Get('SegLightCorrect'),...
                        'BgSubAtten', 0);
                end
            end
            oNormIm = this.normIm;
        end
        
        function [oGradXIm, oGradYIm] = GetGradIm(this)
            % Returns the x- and y-components of the image gradient.
            %
            % Outputs:
            % oGradXIm - X-component of gradient.
            % oGradYIm - Y-component of gradient.
            
            if isempty(this.gradXIm) || isempty(this.gradYIm)
                [this.gradXIm, this.gradYIm] = gradient(this.GetIm());
            end
            oGradXIm = this.gradXIm;
            oGradYIm = this.gradYIm;
        end
        
        function [oDistGradXIm, oDistGradYIm] = GetDistGradIm(this)
            % Returns x- and y-components of the distance image gradient.
            %
            % Outputs:
            % oGradXIm - X-component of distance image gradient.
            % oGradYIm - Y-component of distance image gradient.
            
            if isempty(this.distGradXIm) || isempty(this.distGradYIm)
                dist = this.GetDistIm();
                [this.distGradXIm, this.distGradYIm] = gradient(dist);
            end
            oDistGradXIm = this.distGradXIm;
            oDistGradYIm = this.distGradYIm;
        end
        
        function oBgIm = GetBgIm(this)
            % Returns a background image.
            %
            % If there is no background subtraction algorithm specified,
            % the function assumes that the mean intensity is background.
            % The function also cashes the background subtracted image. The
            % segmentation options specify what background subtraction
            % algorithm will be used.
            
            if isempty(this.bgIm)
                if strcmpi(this.imData.Get('SegBgSubAlgorithm'), 'none')
                    image = this.GetIm();
                    this.bgIm = ones(size(image)) * mean(image(:));
                    this.normIm = image - this.bgIm;
                else
                    [this.normIm, this.bgIm] = BgSub_generic(this.imData, this.t,...
                        'CorrectLight', this.imData.Get('SegLightCorrect'),...
                        'BgSubAtten', 0);
                end
            end
            oBgIm = this.bgIm;
        end
        
        function oBgNormIm = GetBgNormIm(this)
            % Returns a background image with zero mean.
            %
            % The output is the same as for GetBgIm, but the mean value has
            % been subtracted.
            
            if isempty(this.bgNormIm)
                bg = this.GetBgIm();
                this.bgNormIm = bg - mean(bg(:));
            end
            oBgNormIm = this.bgNormIm;
        end
        
        function oBgVarIm = GetBgVarIm(this)
            % Returns the local variance image of the background.
            %
            % The function uses a 5x5 region to compute the local variance,
            % and it uses the background image returned by GetBgIm.
            
            if isempty(this.bgVarIm)
                this.bgVarIm = LocalVariance(this.GetBgNormIm(), 2);
            end
            oBgVarIm = this.bgVarIm;
        end
        
        function oPrevDiffIm = GetPrevDiffIm(this)
            % Returns difference between the current and previous image.
            %
            % The previous image is subtracted from the current. If it is
            % the first image, an image of NaNs is returned.
            
            if isempty(this.prevDiffIm)
                if this.t > 1
                    prevIm = this.imData.GetIntensityCorrectedImage(this.t-1,...
                        this.imData.Get('SegLightCorrect'));
                    this.prevDiffIm = this.GetIm() - prevIm;
                else
                    this.prevDiffIm = nan(size(this.GetIm()));
                end
            end
            oPrevDiffIm = this.prevDiffIm;
        end
        
        function oNextDiffIm = GetNextDiffIm(this)
            % Returns difference between the next and the current image.
            %
            % The current image is subtracted from the next. If it is the
            % last image, an image of NaNs is returned.
            
            if isempty(this.nextDiffIm)
                if this.t < this.imData.sequenceLength
                    nextIm = this.imData.GetIntensityCorrectedImage(this.t+1,...
                        this.imData.Get('SegLightCorrect'));
                    this.nextDiffIm = nextIm - this.GetIm();
                else
                    this.nextDiffIm = nan(size(this.GetIm()));
                end
            end
            oNextDiffIm = this.nextDiffIm;
        end
        
        function oLocalVarIm = GetLocVarIm(this)
            % Returns the local variance computed using a 5x5 pixel region.
            
            if isempty(this.locVarIm)
                this.locVarIm = LocalVariance(this.GetNormIm(), 2);
            end
            oLocalVarIm = this.locVarIm;
        end
        
        function oLoG5Im = GetLog5Im(this)
            % Returns a 5-point approximation of the Laplacian.
            %
            % The Laplacian operator is applied to the smoothed image
            % returned by GetSmoothIm.
            
            if isempty(this.loG5Im)
                this.loG5Im = 4*del2(this.GetSmoothIm());
            end
            oLoG5Im = this.loG5Im;
        end
        
        function oLocMaxIm = GetLocMaxIm(this)
            % Returns a binary image of the local maxima.
            %
            % Local maxima are 1:s and other pixels are zeros. The local
            % maxima are computed on the smoothed image returned by
            % GetSmoothIm. Local maxima on the border of the image are
            % removed.
            
            if isempty(this.locMaxIm)
                this.locMaxIm = ZeroBorders(imregionalmax(this.GetSmoothIm()));
            end
            oLocMaxIm = this.locMaxIm;
        end
        
        function oLocMinIm = GetLocMinIm(this)
            % Returns a binary image of the local minima.
            %
            % Local minima are 1:s and other pixels are zeros. The local
            % minima are computed on the smoothed image returned by
            % GetSmoothIm. Local minima on the border of the image are
            % removed.
            
            if isempty(this.locMinIm)
                this.locMinIm = ZeroBorders(imregionalmax(-this.GetSmoothIm()));
            end
            oLocMinIm = this.locMinIm;
        end
        
        function oSmoothIm = GetSmoothIm(this)
            % Returns an image smoothed using a Gaussian kernel with std 5.
            
            if isempty(this.smoothIm)
                this.smoothIm = SmoothComp(this.GetNormIm(), 5);
            end
            oSmoothIm = this.smoothIm;
        end
        
        function oBwIm = GetBwIm(this)
            % Returns a binary segmentation mask where cell pixels are 1s.
            %
            % The segmentation mask has to be passed to the ImageProcessor
            % using SetBwIm before this function can be called. Otherwise
            % calling the function will result in an error.
            
            if isempty(this.bwIm)
                error('bwIm has to be set using SetBwIm, before it can be returned.')
            end
            oBwIm = this.bwIm;
        end
        
        function oPreThresholdIm = GetPreThresholdIm(this)
            % Returns an image that can be thresholded into a segmentation.
            %
            % The image has to be passed to the ImageProcessor using
            % SegPreThresholdIm before this function can be called.
            % Otherwise calling the function will result in an error.
            
            if isempty(this.preThresholdIm)
                [~, ~, this.preThresholdIm] = Segment_generic(this.imData, this.t);
            end
            oPreThresholdIm = this.preThresholdIm;
        end
        
        function oDistIm = GetDistIm(this)
            % Returns a distance transform of the binary segmentation mask.
            %
            % When the distance transform is computed, pixels outside the
            % image are considered to be background. The function will
            % return an error if the segmentation mask has not been
            % specified using SetBwIm.
            
            if isempty(this.distIm)
                bwImPad = padarray(this.GetBwIm(), [1 1]);
                distImPad = double(bwdist(~bwImPad));  % bwdist returns single.
                this.distIm = distImPad(2:(end-1), 2:(end-1));
            end
            oDistIm = this.distIm;
        end
        
        function SetBwIm(this, aBwIm)
            % Sets the binary segmentation mask.
            %
            % The binary segmentation mask cannot be computed by the object
            % and has to be set from the outside.
            
            this.bwIm = aBwIm;
        end
        
        function SetPreThresholdIm(this, aPreThresholdIm)
            % Sets the image that can be thresholded into a segmentation.
            %
            % This image cannot be computed by the object and has to be set
            % from the outside.
            
            this.preThresholdIm = aPreThresholdIm;
        end
        
        function oEta = GetEta(this, aBlob, aP, aQ)
            % Returns the normalized central moments of binary blob mask.
            %
            % The normalized central moments are used in multiple other
            % features, like the Hu invariant moments.
            %
            % Inputs:
            % aBlob - Blob object to compute the moments for.
            % aP - The order of the moment in the x-dimension.
            % aQ - The order of the moment in the y-dimension.
            
            index = aBlob.index;
            
            % Preallocate with nan.
            if size(this.eta,1) < index
                this.eta = cat(1, this.eta, nan(index-size(this.eta,1)+1000,4,4));
            end
            
            if isnan(this.eta(index,aP+1,aQ+1))
                [x, y, ~] = aBlob.GetPixelCoordinates();
                xb = this.GetXbar(aBlob);
                yb = this.GetYbar(aBlob);
                nu = sum((x-xb).^aP .* (y-yb).^aQ);
                this.eta(index,aP+1,aQ+1) = nu / length(x)^(1+aP/2+aQ/2);
            end
            
            oEta = this.eta(index,aP+1,aQ+1);
        end
        
        function oXbar = GetXbar(this, aBlob)
            % Returns the average x-coordinate in a binary blob mask.
            %
            % The function caches both the mean x-coordinate and the mean
            % y-coordinate, so that they do not have to be computed again.
            
            index = aBlob.index;
            
            % Preallocate with nan.
            if length(this.xbar) < index
                this.xbar = [this.xbar; nan(index-length(this.xbar)+1000,1)];
                this.ybar = [this.ybar; nan(index-length(this.ybar)+1000,1)];
            end
            
            if isnan(this.xbar(index))
                [x, y, ~] = aBlob.GetPixelCoordinates();
                this.xbar(index) = mean(x);
                this.ybar(index) = mean(y);
            end
            
            oXbar = this.xbar(index);
        end
        
        function oYbar = GetYbar(this, aBlob)
            % Returns the average y-coordinate in a binary blob mask.
            %
            % The function caches both the mean x-coordinate and the mean
            % y-coordinate, so that they do not have to be computed again.
            
            index = aBlob.index;
            
            % Preallocate with nan.
            if length(this.ybar) < index
                this.ybar = [this.ybar nan(index-length(this.ybar)+1000,1)];
            end
            
            if isnan(this.ybar(index))
                [x, y, ~] = aBlob.GetPixelCoordinates();
                this.xbar(index) = mean(x);
                this.ybar(index) = mean(y);
            end
            
            oYbar = this.ybar(index);
        end
        
        function oGradientK = GetGradientKIm(this, aK)
            % Computes the gradient magnitude of a down-sampled image.
            %
            % The the gradient magnitude image is computed by down-sampling
            % the background subtracted image by a factor k, computing the
            % gradient magnitude, and then up-sampling the resulting
            % gradient magnitude image by the factor k. This results in an
            % output with the same dimensions as the original image.
            %
            % Inputs:
            % aK - Down-sampling factor.
            %
            % Outputs:
            % oGradient - Gradient magnitude image after up-sampling.
            
            if isempty(this.gradientKIm{aK})
                h = this.imData.imageHeight;
                w = this.imData.imageWidth;
                
                img = this.GetNormIm();
                if aK > 1
                    % Down-sample.
                    img = imresize(img, ceil([h w]/aK));
                end
                
                % Compute gradient magnitude.
                [gx, gy] = gradient(img);
                this.gradientKIm{aK} = sqrt(gx.^2 + gy.^2);
                
                if aK > 1
                    % Up-sample.
                    this.gradientKIm{aK} = imresize(this.gradientKIm{aK}, [h w]);
                end
            end
            oGradientK = this.gradientKIm{aK};
        end
        
        function oLaplacianK = GetLaplacianKIm(this, aK)
            % Computes the gradient Laplacian of a down-sampled image.
            %
            % The the Laplacian image is computed by down-sampling the
            % background subtracted image by a factor k, computing the
            % Laplacian, and then up-sampling the resulting Laplacian image
            % by the factor k. This results in an output with the same
            % dimensions as the original image.
            %
            % Inputs:
            % aK - Down-sampling factor.
            %
            % Outputs:
            % oGradient - Laplacian image after up-sampling.
            
            
            if isempty(this.laplacianKIm{aK})
                h = this.imData.imageHeight;
                w = this.imData.imageWidth;
                
                img = this.GetNormIm();
                if aK > 1
                    % Down-sample.
                    img = imresize(img, ceil([h w]/aK));
                end
                
                % Compute Laplacian.
                this.laplacianKIm{aK} = 4*del2(img);
                
                if aK > 1
                    % Up-sample.
                    this.laplacianKIm{aK} = imresize(this.laplacianKIm{aK}, [h w]);
                end
            end
            oLaplacianK = this.laplacianKIm{aK};
        end
    end
end