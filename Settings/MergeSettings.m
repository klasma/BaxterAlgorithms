function oSett = MergeSettings(aSett1, aSett2)
% MergeSettings merges two cell arrays of settings.
%
% The function operates on 2D cell arrays created by ReadSettings, where
% each image sequence has a row and each setting has a column. Settings in
% the second input argument has precedence if the same setting exists in
% both cell arrays.
%
% Inputs:
% aSett1 - Cell array with settings.
% aSett2 - Cell array with settings, that will overwrite settings in aSett1
%          if the same setting is defined twice for the same image
%          sequence.
%
% Outputs:
% oSett - Cell array with the settings from both aSett1 and aSett2.
%
% See also:
% ReadSettings, GetSeqSettings, SetSeqSettings

oSett = aSett1;

if size(aSett2,1) < 2 || size(aSett2,2) < 2
    % The second input does not contain any settings.
    return
end

seDirs = aSett2(2:end,1);
props = aSett2(1, 2:end);
for j = 1:length(seDirs)
    for k = 1:length(props)
        value = GetSeqSettings(aSett2, seDirs{j}, props{k});
        oSett = SetSeqSettings(oSett, seDirs{j}, props{k}, value);
    end
end
end