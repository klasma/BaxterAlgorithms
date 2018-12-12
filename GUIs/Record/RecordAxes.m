function oIm = RecordAxes(aAxes, varargin)
% Performs a screen capture of an axes object.
%
% The screen capture will normally contain only the box used for plotting,
% and not other things like the title and the axes labels. The box to be
% captured can however bee resized and moved.
%
% Inputs:
% aAxes - Axes to do screen capture on.
%
% Property/Value inputs:
% Offsets - An array defining shifts to the box to be captured, in the
%           format [left, bottom, width, height].
%
% Outputs:
% oIm - Captured uint8 image with 3 (RGB-)channels.

aOffsets = GetArgs({'Offsets'}, {zeros(1,4)}, true, varargin);

unints = get(aAxes, 'units');  % Old units.
set(aAxes, 'units', 'pixels');
box = plotboxpos(aAxes);  % Box used for plotting.
set(aAxes, 'units', unints);  % Restore old units.
im = getframe(get(aAxes, 'Parent'), box+aOffsets);
oIm = im.cdata;
end