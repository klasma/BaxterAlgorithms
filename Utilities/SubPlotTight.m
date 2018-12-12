function varargout = SubPlotTight(aRows, aCols, aIndex, varargin)
% Creates an axes object which fits in a custom rectangular grid of axes.
%
% The function does the same thing as the built in function subplot, but it
% makes it possible to customize how wide the margins between the axes
% should be, and also how much of the figure should be taken up by the full
% grid of axes.
%
% Inputs:
% aRows - The number of rows in the grid of axes.
% aCols - The number of columns in the grid of axes.
% aIndex - The index of the axes object to be created. The axes are indexed
%          from 1 to aRows*aCols, starting with the upper left axes and
%          continuing row by row, from left to right. Note that only the
%          axes with index aIndex is created. To create the whole grid, you
%          need to call the function aRows*aCols times.
%
% Property/Value inputs:
% Position - The position of the full axes grid inside the figure in
%            normalized units. The default is [0 0 1 1], and makes the axes
%            grid take up the whole figure.
% Margins - Two element vector which gives the fractions of the maximum
%           width and height that the axes take up. A value of 1 means that
%           the axes objects are adjacent with no white space in between.
%           The default value is [0.9 0.9]. If a scalar is given, the same
%           fraction is used in both dimensions.
% Parent - Specifies the figure object that the axes will be placed in.
%
% Outputs:
% varargout{1} - Optional output with the created axes object.
%
% See also:
% subplot

% Parse property/value inputs.
[aPosition, aMargins, aParent] = GetArgs(...
    {'Position', 'Margins', 'Parent'},...
    {[0 0 1 1], [0.9 0.9], gcf()},...
    true, varargin);

% Use the same margin in both dimensions if a single value is given.
if length(aMargins) == 1
    aMargins = aMargins*ones(2,1);
end

[c, r] = ind2sub([aCols, aRows], aIndex);
% The row numbering should start with the top row.
r = aRows-r+1;

% Position of the axes in the figure in normalized units.
pos = zeros(1,4);
pos(1) = aPosition(1) + aPosition(3)/aCols*(c-1) + aPosition(3)/aCols*(1-aMargins(1))/2;  % left
pos(2) = aPosition(2) + aPosition(4)/aRows*(r-1) + aPosition(4)/aRows*(1-aMargins(2))/2;  % bottom
pos(3) = aPosition(3)/aCols*aMargins(1);  % width
pos(4) = aPosition(4)/aRows*aMargins(2);  % height

units = get(aParent, 'Units');
set(aParent, 'Units', 'normalized')

% Create the axes.
ax = axes('Position', pos);

% Restore the old units.
set(aParent, 'Units', units)

if nargout == 1
    % Create an output only if the caller asked for it.
    varargout{1} = ax;
end
end