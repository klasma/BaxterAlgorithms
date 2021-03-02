function output = HasSettings(aSettingsPath, aSeqDir)

sett = ReadDelimMat(aSettingsPath, ',');
if strcmp(sett{1,1}, 'setting')
    output = any(strcmpi(sett(1,2:end), aSeqDir));
else
    output = any(strcmpi(sett(2:end,1), aSeqDir));
end
end