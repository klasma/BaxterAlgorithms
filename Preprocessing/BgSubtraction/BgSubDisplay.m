function oImage = BgSubDisplay(aImData, aFrame)
% Produces a background subtracted image with a shifted mean value.
%
% The function computes the background subtracted image using the
% background subtraction settings of the image sequence and then adds the
% mean value of the background image. This changes the pixel intensities so
% that intensities of moving objects look the same or almost the same as in
% the original image. The returned image should be displayed on an
% intensity scale from 0 to 1 but can have some pixels with values below 0
% or above 1. The image can be be displayed using the function "imshow".
%
% Inputs:
% aImData - ImageData object associated with the image sequence.
% aFrame - Frame index.
%
% Outputs:
% oImage - Background subtracted image with a shifted mean.

[im, bg] = BgSub_generic(aImData, aFrame,...
    'CorrectLight', aImData.Get('SegLightCorrect'),...
    'BgSubAtten', aImData.Get('SegBgSubAtten'));
oImage = (im + mean(bg(:)))/255;
end