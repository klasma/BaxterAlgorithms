function SetKeyReleaseCallback(aObject, aKeyReleaseCallback)
% Sets the key release callback of a graphics object and all its children.
%
% The function only sets the key release callback on objects for which this
% property exists. The function is used to deal with the problem that a
% figure's key release callback will not execute when a button or some
% other object is selected. The function is recursive.
%
% Inputs:
% aObject - Figure or other object where the key release callback will be
%           set.
% aKeyPressCallback - Function handle to the desired keypress callback.
%
% See also:
% aKeyPressCallback

% Set the key release callback of the object itself.
if isprop(aObject, 'KeyReleaseFcn')
    set(aObject, 'KeyReleaseFcn', aKeyReleaseCallback)
end

% Set the key release callback for all children of the object, unless the
% object is an axes, because axes can have many children and none of them
% have a key release callback.
if isprop(aObject, 'Children') && ~isprop(aObject, 'XLim')
    ch = get(aObject, 'Children');
    for i = 1:length(ch)
        SetKeyReleaseCallback(ch(i), aKeyReleaseCallback)
    end
end
end