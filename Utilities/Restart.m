% Closes all figures, calls clear classes and starts BaxterAlgorithms.
%
% This function is useful when a class definition has been changed, and
% when a figure with a close request function has changed so that it cannot
% be closed by clicking on the close button.

% Delete all open figures without asking nicely.
figs = get(0, 'Children');  % all open figures
for i =  1:length(figs)
    delete(figs(i))
end

% Remove all variables, class definitions and  break points.
clear classes %#ok<CLCLS>

startup

% Start the Baxter Algorithms.
BaxterAlgorithms()