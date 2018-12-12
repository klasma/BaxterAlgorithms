function oA = ZeroBorders(aA)
% Sets border pixels in an image to zero.
%
% This can for example be used to remove local maxima that have been
% detected on the image border. Pixels are counted as border pixels if they
% do not have 8 neighboring pixels.
%
% Inputs:
% aA - Input image.
%
% Outputs:
% oA - Output image where border pixels have been set to 0.

oA = aA;
oA(:,1) = 0;
oA(:,end) = 0;
oA(1,:) = 0;
oA(end,:) = 0;
end