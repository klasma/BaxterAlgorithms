function WriteSeqSettings(aSeqPath, varargin)
% Writes settings to the settings file associated with an image sequence.
%
% Inputs:
% aSeqPath - Full path to the image sequence.
% varargin - Property/Value pairs with the settings names and the settings
%            values that should be saved for the image sequence.
%
% See also:
% ReadSeqSettings, WriteSettings

[exPath, seqDir] = FileParts2(aSeqPath);

data = ReadSettings(exPath);
data = SetSeqSettings(data, seqDir, varargin{:});
WriteSettings(exPath, data)
end