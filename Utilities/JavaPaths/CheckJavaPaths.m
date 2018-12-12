function oOk = CheckJavaPaths()
% Checks if all java paths needed by the Baxter Algorithms have been added.
%
% The paths may have been added statically in the javaclasspath.txt file or
% dynamically using the javaaddpath command.
%
% Outputs:
% oOk - True if all paths have been added.
%
% See also:
% RequiredJavaPaths, AddJavaPaths.

allPaths = javaclasspath('-all');
requiredPaths = RequiredJavaPaths();
oOk = isempty(setdiff(requiredPaths, allPaths));
end