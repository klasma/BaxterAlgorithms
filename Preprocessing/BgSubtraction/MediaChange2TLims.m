function [oT1, oT2] = MediaChange2TLims(aImData, aMediaChanges, aFrame)
% Finds the current time interval between media changes.
%
% The function finds the time interval that the current media is present
% in, from an array of media change frames. Media changes are assumed to
% specify the first frame of the new media. The time points do not have to
% be real media changes, they can also have been specified to give a better
% background subtraction.
%
% Inputs:
% aImData - ImageData object for the image sequence.
% aMediaChanges - Array with media change frames.
% aFrame - Current frame.
%
% Outputs:
% oT1 - First frame with current media.
% oT2 - Last frame with current media.
%
% See also:
% BgSub_generic, BgSub_median, BgSub_medianfit

% First image to compute background image from.
oT1 = max([1, aMediaChanges(aMediaChanges <= aFrame)]);
% Last image to compute background image from.
oT2 = min([aMediaChanges(aMediaChanges > aFrame)-1, aImData.sequenceLength]);
end