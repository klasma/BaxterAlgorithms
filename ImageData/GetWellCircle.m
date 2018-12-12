function [oX, oY, oR] = GetWellCircle(aImData)
% Finds a circular microwell in the first image of an image sequence.
%
% The function either computes the center and the radius of the microwell,
% or reads the data from a mat-file if it has been computed before. The
% function is intended for images that have already been cut and will
% return the first microwell in sequences with multiple wells. The computed
% microwell information is saved to a mat-file with the same name as the
% image sequence, in a folder named 'Microwells' in the Analysis folder of
% the experiment. The mat-files store the three variables 'x', 'y', and
% 'r'. All values are in pixels.
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

if isnan(aImData.Get('minWellR')) || isnan(aImData.Get('maxWellR'))
    % The image has no circular microwell.
    oX = nan;
    oY = nan;
    oR = nan;
    return
end

microwellFile = fullfile(...
    aImData.GetAnalysisPath(),...
    'Microwells',...
    [aImData.GetSeqDir() '.mat']);

if exist(microwellFile, 'file')
    tmp = load(microwellFile);
    % If more than one well was found we just take the first. This should
    % never happen.
    oX = tmp.x(1);
    oY = tmp.y(1);
    oR = tmp.r(1);
else
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
    
    if ~exist(fileparts(microwellFile), 'dir')
        mkdir(fileparts(microwellFile))
    end
    
    % Save the computed microwell parameters to a mat-file.
    save(microwellFile, 'x', 'y', 'r')
    
    % If more than one well was found we just take the first. This  should
    % never happen.
    oX = x(1);
    oY = y(1);
    oR = r(1);
end
end