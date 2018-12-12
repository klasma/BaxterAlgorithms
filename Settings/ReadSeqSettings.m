function varargout = ReadSeqSettings(aData, varargin)
% Reads settings associated with an image sequence from a settings file.
%
% Normally, the settings will be read from the Settings.csv file in the
% experiment folder, but if there is a SettingsLinks.csv file in the
% experiment directory, linking to a different settings file, the settings
% will be taken from that settings file instead. It is also possible to set
% the globalSettingsFile field of an ImageData object and input that object
% to this function to have the settings be read from an arbitrary settings
% file.
%
% Inputs:
% aData - Either the full path name of an image sequence or an ImageData
%         object associated with the image sequence. aData can also be a
%         cell array of path names or ImageData objects but then only a
%         single setting can be read.
% varargin - Names of the settings that should be read.
%
% Outputs:
% varargout - Settings values associated with the settings names in
%             varargin.
%
% See also:
% WriteSeqSettings, ReadSeqLog

% Read a single setting for multiple image sequences.
if iscell(aData)
    if length(varargin) == 1
        varargout{1} = cellfun(@(x)ReadSeqSettings(x, varargin{1}), aData,...
            'UniformOutput', false);
        return
    else
        error(['If the first argument is a cell array there must be 2 '...
            'arguments in total.'])
    end
end

if isa(aData, 'ImageData')
    % An ImageData object was given as input.
    seqDir = aData.GetSeqDir();
    if ~isempty(aData.globalSettingsFile)
        % The image data object defines what settings file should be used.
        sett = ReadSettings(aData.globalSettingsFile, seqDir);
    else
        sett = ReadSettings(aData.GetExPath(), seqDir);
    end
else
    % The path to the image sequence was given as input.
    [exPath, seqDir] = FileParts2(aData);
    sett = ReadSettings(exPath, seqDir);
end

% Extract the desired settings from the contents of the settings file.
varargout = cell(size(varargin));
for i = 1:length(varargin)
    varargout{i} = GetSeqSettings(sett, seqDir, varargin{i});
end
end