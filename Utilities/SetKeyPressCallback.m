function SetKeyPressCallback(aObject, aKeyPressCallback)
% Sets the keypress callback of a graphics object and all its children.
%
% The function only sets the keypress callback on objects for which this
% property exists. The function is used to deal with the problem that a
% figure's keypress callback will not execute when a button or some other
% object is selected. The function is recursive.
%
% Inputs:
% aObject - Figure or other object where the keypress callback will be set.
% aKeyPressCallback - Function handle to the desired keypress callback.
%
% See also:
% SetKeyReleaseCallback

% Set the keypress callback of the object itself.
if isprop(aObject, 'KeyPressFcn')
    set(aObject, 'KeyPressFcn', aKeyPressCallback)
end

% Set the keypress callback for all children of the object, unless the
% object is an axes, because axes can have many children and none of them
% have a keypress callback.
if isprop(aObject, 'Children') && ~isprop(aObject, 'XLim')
    ch = get(aObject, 'Children');
    for i = 1:length(ch)
        SetKeyPressCallback(ch(i), aKeyPressCallback)
    end
end
end