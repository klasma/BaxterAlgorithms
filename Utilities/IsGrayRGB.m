function oTest = IsGrayRGB(aImage)
% Checks if an image is a 3-channel RGB image with only gray scale pixels.
%
% If all pixels are shades of gray, the image can be stored using a single
% channel, which takes up less space.
%
% Inputs:
% aImage - The image to be tested. The pixels can be any numeric type.
%
% Outputs:
% oTest - Returns true if the image is an RGB image with only gray pixels.
%         If the image is a gray scale image with a single channel, the
%         function returns false.

if ndims(aImage) ~= 3
    % The image needs to have 3 channels.
    oTest = false;
else
    test = aImage(:,:,1) ~= aImage(:,:,2)  | aImage(:,:,1) ~= aImage(:,:,3);
    oTest= ~any(test(:));
end
end