function varargout = GetSeqSettings(aSett, aSeqDir, varargin)
% Extracts settings from a cell array created using ReadSettings.
%
% Inputs:
% aSett - Cell array with settings. The first column has names of image
%         sequences, the first row has names of settings and the other
%         elements contain settings.
% aSeqDir - Name of the image sequence folder (not the full path).
% varargin - Names of settings that should be extracted.
%
% Outputs:
% varargout - The settings values of for the settings in varargin. All
%             settings values are character arrays. If the image sequence
%             or a setting does not exist in aSett, '' will be returned.
%
% See also:
% SetSeqSettings, ReadSettings, ReadSeqSettings

if isempty(aSett)
    varargout = repmat({''}, size(varargin));
    return
end

row = find(strcmpi(aSett(:,1), aSeqDir));  % Row index of sequence.
varargout = cell(size(varargin));
for i = 1:length(varargin)
    col = find(strcmpi(aSett(1,:), varargin{i}));  % Column index of setting.
    if ~isempty(row) && ~isempty(col)
        varargout{i} = aSett{row, col};
    else
        % The setting was not defined for the specified image sequence. The
        % image sequence may not even have a row in the settings file.
        varargout{i} = '';
    end
end
end