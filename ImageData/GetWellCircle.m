function [oX, oY, oR] = GetWellCircle(aImData)
% Finds a circular microwell in the first image of an image sequence.
%
% The function computes the center and the radius of the microwell. The
% function is intended for images that have already been cut and will
% return the first microwell in sequences with multiple wells. The computed
% microwell information is stored in persistent variables, so that it does
% not need to be computed multiple times for the same image sequence.
%
% Inputs:
% aImData - ImageData object of the image sequence.
%
% Outputs:
% oX - X-coordinate (width coordinate) of the microwell in pixels.
% oY - Y-coordinate (height coordinate) of the microwell in pixels.
% oR - Radius of the microwell in pixels.
%
% See also:
% FindWellsHough, Cut

persistent outputX % Cell array with all previously returned x-values.
persistent outputY % Cell array with all previously returned y-values.
persistent outputR % Cell array with all previously returned r-values.
persistent labels  % Labels that uniquely identify the different outputs.

if isnan(aImData.Get('minWellR')) || isnan(aImData.Get('maxWellR'))
    % The image has no circular microwell.
    oX = nan;
    oY = nan;
    oR = nan;
    return
end

% Name to save persistent data to.
label = sprintf('%s %f %f',...
    aImData.seqPath,...
    aImData.Get('minWellR'),...
    aImData.Get('maxWellR'));

% Return pre-computed results if they exist.
if any(strcmp(labels, label))
    index = strcmp(labels, label);
    oX = outputX{index};
    oY = outputY{index};
    oR = outputR{index};
    return
elseif length(labels) > 999
    % Clear pre-computed results to avoid memory leak and overhead.
    outputX = {};
    outputY = {};
    outputR = {};
    labels = {};
end

[x, y, r] = FindWellsHough(aImData, 1);
if isempty(x) % The microwell was not found.
    warning('Blaulab:klasma:baddata',...
        'Unable to find a microwell in the specified images')
    % Create a circle in the center of the image, that touches
    % the closest image sides.
    x = aImData.imageWidth/2;
    y = aImData.imageHeight/2;
    r = min(aImData.imageWidth, aImData.imageHeight)/2;
end

% If more than one well was found we just take the first. This  should
% never happen.
oX = x(1);
oY = y(1);
oR = r(1);

outputX = [outputX; {oX}];
outputY = [outputY; {oY}];
outputR = [outputR; {oR}];
labels = [labels; {label}];
end