function [oBw, oGray, oImages] = Segment_bandpass(aI, aImData, aFrame,...
    aHighStd, aLowStd, aBgFactor, aThreshold, aDarkOrBright)
% Segments fluorescent images by bandpass filtering and then thresholding.
%
% High frequency components are removed using convolution with a small
% Gaussian kernel. The low frequency components are found using convolution
% with a larger Gaussian kernel, and then subtracted from the image. The
% low frequency components can be multiplied by a user defined number
% before they are subtracted to give increased flexibility. If the number
% is set to 1, a traditional bandpass filter is achieved.
%
% Inputs:
% aI - Gray scale double image with values between 0 and 255.
% aImData - ImageData object for the image sequence.
% aFrame - The index of the frame to be segmented.
% aHighStd - Standard deviation in pixels of the Gaussian kernel used to
%            find the background. This parameter can be either a scalar or
%            a vector with two elements. If it is a vector, the first
%            element is used for the first image and the second element is
%            used for the last image. The values for images in the middle
%            of the sequence are computed using linear interpolation.
% aLowStd - Standard deviation in pixels of the Gaussian kernel used to
%           remove noise. This parameter can be either a scalar or a vector
%           with two elements. If it is a vector, the first element is used
%           for the first image and the second element is used for the last
%           image. The values for images in the middle of the sequence are
%           computed using linear interpolation.
% aBgFactor - Factor that multiplies the background before it is
%             subtracted. 1 gives a true bandpass filter.
% aThreshold - Threshold above which pixels are considered to be a part of
%              the sample. Usually in the range [0 0.1].
% aDarkOrBright - If if this input argument is 'bright', pixels above the
%                 threshold will be segmented. If it is 'dark', pixels
%                 below the threshold will be segmented.
%
% Outputs:
% oBw - Logical image where segmented foreground pixels are ones.
% oGray - Bandpass filtered image before thresholding.
% oImages - Struct with intermediate processing results. The struct has the
%           following fields:
%           bg - Image filtered with the large Gaussian kernel.
%           smooth - Image filtered with the small Gaussian kernel.
%           bandpass - Bandpass filtered image.
%           mask - Binary mask after thresholding the filtered image.
%
% See also:
% Segment_bandpass3D

im = aI/255;
im = im - min(im(:));

if length(aHighStd) == 2
    n = aImData.sequenceLength;
    if aImData.sequenceLength > 1
        highStd = aHighStd(1) * (n-aFrame) / (n-1) +...
            aHighStd(2) * (aFrame-1) / (n-1);
    else
        highStd = mean(aHighStd);
    end
else
    highStd = mean(aHighStd);
end

if length(aLowStd) == 2
    n = aImData.sequenceLength;
    if aImData.sequenceLength > 1
        lowStd = aLowStd(1) * (n-aFrame) / (n-1) +...
            aLowStd(2) * (aFrame-1) / (n-1);
    else
        lowStd = mean(aLowStd);
    end
else
    lowStd = mean(aLowStd);
end

im_bg = SmoothComp(im, highStd, 'Store', length(aHighStd) == 1);  % Background.
oImages.bg = im_bg;
im_smooth = SmoothComp(im, lowStd, 'Store', length(aLowStd) == 1);  % Noise reduced image.
oImages.smooth = im_smooth;
im_sample = im_smooth - im_bg * aBgFactor;  % Get rid of background.
oImages.bandpass = im_sample;

% figure
% SubPlotTight(1,4,1)
% imshow(im)
% % figure
% SubPlotTight(1,4,2)
% imshow(im_bg)
% % figure
% SubPlotTight(1,4,3)
% imshow(im_smooth)
% % figure
% SubPlotTight(1,4,4)
% imshow(im_sample)

% figure
% SubPlotTight(1,4,1)
% imagesc(log(im))
% % figure
% SubPlotTight(1,4,2)
% imagesc(log(im_bg))
% % figure
% SubPlotTight(1,4,3)
% imagesc(log(im_smooth))
% % figure
% SubPlotTight(1,4,4)
% imagesc(log(max(im_sample,0.01)))

% figure
% ax1 = SubPlotTight(1,4,1);
% imagesc(asinh(im*100))
% % figure
% ax2 = SubPlotTight(1,4,2);
% imagesc(asinh(im_bg*100))
% % figure
% ax3 = SubPlotTight(1,4,3);
% imagesc(asinh(im_smooth*100))
% % figure
% ax4 = SubPlotTight(1,4,4);
% imagesc(asinh(im_sample*100))
% axis([ax1 ax2 ax3 ax4], 'image', 'off')
%
% allPixels = asinh([im(:); im_bg(:); im_smooth(:); im_sample(:)]*100);
% minVal = min(allPixels);
% maxVal = max(allPixels);
% set(ax1, 'clim', [minVal maxVal])
% set(ax2, 'clim', [minVal maxVal])
% set(ax3, 'clim', [minVal maxVal])
% set(ax4, 'clim', [minVal maxVal])
% colormap gray

% figure
% ax1 = SubPlotTight(1,5,1);
% imagesc(asinh(im*100))
% % figure
% im_sub = im-im_smooth;
% ax2 = SubPlotTight(1,5,2);
% imagesc(asinh(im_sub*100))
% % figure
% ax3 = SubPlotTight(1,5,3);
% imagesc(asinh((im_bg)*100))
% % figure
% ax4 = SubPlotTight(1,5,4);
% imagesc(asinh(im_smooth*100))
% % figure
% ax5 = SubPlotTight(1,5,5);
% imagesc(asinh(im_sample*100))
% axis([ax1 ax2 ax3 ax4 ax5], 'image', 'off')
%
% allPixels = asinh([im(:); im_bg(:); im_sub(:); im_smooth(:); im_sample(:)]*100);
% minVal = min(allPixels);
% maxVal = max(allPixels);
% set(ax1, 'clim', [minVal maxVal])
% set(ax2, 'clim', [minVal maxVal])
% set(ax3, 'clim', [minVal maxVal])
% set(ax4, 'clim', [minVal maxVal])
% colormap gray
%
% im_save = (asinh(im*100) - minVal) / (maxVal-minVal);
% im_save = uint8(round(im_save*255));
% imwrite(im_save, 'im.tif')
%
% im_sub_save = (asinh(im_sub*100) - minVal) / (maxVal-minVal);
% im_sub_save = uint8(round(im_sub_save*255));
% imwrite(im_sub_save, 'im_sub.tif')
%
% im_bg_save = (asinh((im_bg)*100) - minVal) / (maxVal-minVal);
% im_bg_save = uint8(round(im_bg_save*255));
% imwrite(im_bg_save, 'im_bg.tif')
%
% im_smooth_save = (asinh(im_smooth*100) - minVal) / (maxVal-minVal);
% im_smooth_save = uint8(round(im_smooth_save*255));
% imwrite(im_smooth_save, 'im_smooth.tif')
%
% im_sample_save = (asinh(im_sample*100) - minVal) / (maxVal-minVal);
% im_sample_save = uint8(round(im_sample_save*255));
% imwrite(im_sample_save, 'im_sample.tif')

switch aDarkOrBright
    case 'bright'
        oBw = im_sample >  aThreshold;
    case 'dark'
        oBw = im_sample <  aThreshold;
end
oImages.mask = oBw;
oGray = im_sample;
end