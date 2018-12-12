function oVar = LoadVariable(aName)
% Loads a variable that has been saved previously.
%
% The variables are loaded from a file named variables.mat in a folder
% named MATfiles. The purpose of loading and saving variables to this file
% is to remember user choices between sessions.
%
% Inputs:
% aName - Name that the variable was saved under.
%
% Outputs:
% oVar - Saved value
%
% See also:
% SaveVariable

oVar = [];

loadPath = FindFile('variables.mat');

if ~exist(loadPath, 'file')
    return
end

tmp = load(loadPath);
if isfield(tmp, aName)
    oVar = tmp.(aName);
end
end