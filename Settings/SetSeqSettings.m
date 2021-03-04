function oSett = SetSeqSettings(aSett, aSeqDir, varargin)
% Modifies settings from a cell array created using ReadSettings.
%
% Inputs:
% aSett - Cell array with settings. The first column has names of image
%         sequences, the first row has names of settings and the other
%         elements contain settings.
% aSeqDir - Name of the image sequence folder (not the full path).
% varargin - Property/Value pairs with the settings names and the settings
%            values that should be entered for the image sequence.
%
% Outputs:
% oSett - Modified table of settings.
%
% See also:
% GetSeqSettings, ReadSeqSettings, WriteSeqSettings

oSett = aSett;
row = find(strcmpi(oSett(:,1), aSeqDir));

if isempty(row)
    % Add a new row if there is no existing row for the image sequence.
    oSett = [oSett; [{aSeqDir} repmat({''}, 1, size(oSett,2)-1)]];
    % Sort the image sequence names alphabetically.
    [~, order] = sort(oSett(2:end,1));
    oSett = [oSett(1,:); oSett(order+1,:)];
    row = find(strcmpi(oSett(:,1), aSeqDir));
end

for i = 1 : 2 : length(varargin)
    col = find(strcmpi(oSett(1,:), varargin{i}));
    if isempty(col)
        % Add a new column if the specified setting does not exist in the
        % settings table.
        oSett = [oSett [varargin(i); repmat({''}, size(oSett,1)-1, 1)]]; %#ok<AGROW>
        col = size(oSett, 2);
    end
    oSett{row, col} = varargin{i+1};
end
end