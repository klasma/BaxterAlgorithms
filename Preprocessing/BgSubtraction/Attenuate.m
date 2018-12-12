function oI = Attenuate(aI, aAttenuation)
% Subtracts an image from the absolute pixel values of another image.
%
% The pixels are subtracted where the other image is positive and added if
% the other image is negative. If the pixels of the other image change
% sign, they are set to 0. This function can be used to bring a background
% subtracted image closer to 0 in regions where there is a lot of
% background.
%
% Inputs:
% aI - Image to attenuate.
% aAttenuation - Image specifying how much the pixels should be attenuated.
%
% Outputs:
% oI - Attenuated image.

oI = aI;

% Positive pixels.
gs = oI > 0;
oI(gs) = max(0, oI(gs) - aAttenuation(gs));

% Negative pixels.
ls = oI < 0;
oI(ls) = min(0, oI(ls) + aAttenuation(ls));
end