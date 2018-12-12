function CopySettings(aSeq1, aSeq2)
% Copies settings between image sequences.
%
% CopySettings copies settings from one image sequence to another image
% sequence. All settings are copied from the currently used settings file
% of the first sequence to the settings file of the second sequence. It
% does not matter what settings fields or image sequences are already
% present in the settings file of the second image sequence.
%
% Inputs:
% aSeq1 - ImageData object or full path to image sequence from which the
%         settings should be taken.
% aSeq2 - Full path to image sequence to which the settings should be
%         applied.
%
% See also:
% DeleteSettings

% Read settings to be copied.
if isa(aSeq1, 'ImageData')
    seqDir1 = aSeq1.GetSeqDir();
    if ~isempty(aSeq1.globalSettingsFile)
        sett1 = ReadSettings(aSeq1.globalSettingsFile, seqDir1);
    else
        sett1 = ReadSettings(aSeq1.GetExPath(), seqDir1);
    end
else
    [exPath, seqDir1] = FileParts2(aSeq1);
    sett1 = ReadSettings(exPath, seqDir1);
end

% Read settings that should be modified.
[exPath2, seqDir2] = FileParts2(aSeq2);
sett2 = ReadSettings(exPath2);

% Transfer settings from aSeq1 to aSeq2.
props = sett1(1, 2:end);
for i = 1:length(props)
    value = GetSeqSettings(sett1, seqDir1, props{i});
    sett2 = SetSeqSettings(sett2, seqDir2, props{i}, value);
end

% Save the new settings for aSeq2.
if numel(sett2) > 1  % Don't save empty settings file.
    WriteSettings(exPath2, sett2)
end
end