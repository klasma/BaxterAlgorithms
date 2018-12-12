function oIm = PadForFFDshow(aIm, aPadColor)
% Pads an image so that it can be encoded using the ffdshow codec.
%
% The image will be padded with pixels in a specified color from below and
% from the left so that the width is a multiple of 4 and the height is a
% multiple of 2.
%
% Inputs:
% aIm - uint8 gray scale image to be padded.
% aPadColor - Gray scale value between 0 and 255, used for padding.
%
% Outputs:
% oIm - Padded image.

oIm = aIm;

% Make sure that the width is a multiple of 4 by padding to the left.
[h,w,d] = size(oIm);
if rem(w,4) ~= 0
    oIm = [aPadColor*ones(h,4-rem(w,4),d) oIm];
end

% Make sure that the height is a multiple of 2 by padding from below.
[h,w,d] = size(oIm);
if rem(h,2) ~= 0
    oIm = [oIm; aPadColor*ones(2-rem(h,2),w,d)];
end
end