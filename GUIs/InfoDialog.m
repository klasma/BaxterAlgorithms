function InfoDialog(aLabel, aName, aMessage)
% An information dialog that the user can choose not to show again.
%
% Information about which dialogs should be displayed are stored in the
% file variables.mat, and can loaded and changed using the functions
% LoadVariable and SaveVariable. One can choose to display all dialogs or
% no dialog on the menu Help->Information dialogs in the main GUI.
%
% Inputs:
% aLabel - Unique label of the information dialog. This label is used to
%          determine if the user has chosen not to display the dialog
%          again.
% aName - Name displayed at the top of the dialog.
% aMessage - The message text displayed in the dialog. Line breaks can be
%            introduced by placing paragraphs in cells of a cell array.
%
% See also:
% BaxterAlgorithms, LoadVariables, SaveVariables

display = LoadVariable(aLabel);
if ~isempty(display) && ~display
    % The user has selected to not show the message again.
    return
end

% Create the dialog.
choice = questdlg(aMessage, aName,...
    'Ok', 'Do not show again', 'Do not show again');

% Save information saying if the dialog should be displayed again.
if ~isempty(choice) && strcmp(choice, 'Do not show again')
    SaveVariable(aLabel, false)
else
    SaveVariable(aLabel, true)
end
end