function oPaths = RequiredJavaPaths()
% Returns javapaths required by the Baxter Algorithms.
%
% Outputs:
% oPaths - Cell array with full path names.
%
% See also:
% CheckJavaPath, AddJavaPath

% Path of the top program directory.
basePath = fileparts(fileparts(fileparts(mfilename('fullpath'))));

% This path is required for a progress-bar which works in parfor loops.
parforProgressPath = fullfile(basePath,...
    'External', 'ParforProgMonv2', 'java');

oPaths = {parforProgressPath};
end