function [oSeqLength, oTimes] = TimeSpan(aCells)
% Returns the image sequence length and imaging times for cells.
%
% The function takes an array of cells as input and returns the number of
% images in the corresponding image sequences, and an array with the time
% points at which the images where acquired. The method requires that the
% time between images is the same for all image sequences, and throws an
% error otherwise.
%
% Inputs:
% aCells - Array of Cell objects.
%
% Outputs:
% oSeqLength - The length of the longest image sequence.
% oTimes - Array of time points (in hours), when the images in the image
%          sequences were acquired.
%
% See also:
% Cell, ImageData

% Check that the time between images is the same for all image sequences.
dTs = [aCells.dT];
if any(dTs ~= dTs(1))
    error(['All cells must come from image sequences with the same '...
        'time between images.'])
end

oSeqLength = max([aCells.sequenceLength]);
oTimes = aCells(1).imageData.FrameToT(1:oSeqLength);
end