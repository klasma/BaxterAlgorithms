function oMenu = GetMenu(aObj, varargin)
% Finds a menu or a submenu with a specified name.
%
% The function is used to get a handle to a uimenu object corresponding to
% a menu with a specified name. If the menu is a sub-menu, the names of all
% super-menus need to be specified as input arguments too. The function is
% recursive.
%
% Inputs:
% aObj - Parent object (figure or uimenu) to look for the menu in.
% varargin - Sequence of submenu labels. varargin{1} is the label
%            of the top-level menu, varargin{2} is a label on one of that
%            menus submenus and so forth.
%
% Outputs:
% oMenu - uimenu object corresponding to the requested menu.
%
% See also:
% CreateMenus, SetVisibleMenus

ch = get(aObj, 'Children');
menuName = varargin{1};
for i = 1:length(ch)
    if strcmp(get(ch(i), 'Type'), 'uimenu') &&...
            strcmp(get(ch(i), 'Label'), menuName)
        if length(varargin) > 1
            % We are looking for a submenu.
            oMenu = GetMenu(ch(i), varargin{2:end});
        else
            oMenu = ch(i);
        end
    end
end
end