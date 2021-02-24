function output = HasSettings(aSettingsPath, aSeqDir)

sett = ReadDelimMat(aSettingsPath, ',');
output = any(strcmpi(sett(2:end,1), aSeqDir));
end