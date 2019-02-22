function oMenus = CreateMenus(aParent, aDefs)
% Generates a set of menus from a nested cell array representing the menus.
%
% A set of N menus are represented using an Nx3 cell array where the first
% column contains the names of the menus, the second column contains the
% levels of the menus ('basic', 'advanced' or 'development'), and the third
% column contains function handles with callbacks for the menus. The second
% column is not used to generate the menus and can therefore be left empty.
% Sub-menus are created by replacing the callback by an Mx3 cell array
% representing M sub-menus. Sub-menus can be nested in multiple layers. In
% this function, the nesting is achieved through recursion. The menus are
% all created with visibility set to 'off', because otherwise the menus can
% change order when the visibilities are changed using SetVisibleMenus.
%
% Inputs:
% aParent - Figure or uimenu where the menus will be placed.
% aDefs - Nx3 cell array defining N menus.
%
% Outputs:
% oMenus - Nx4 cell array where the first 3 column is identical to aDefs
%          and the 4th column contains the corresponding uimenu objects.
%
% See also:
% SetVisibleMenus, GetMenu

oMenus = [aDefs cell(size(aDefs,1),1)];

for i = 1:size(aDefs,1)
    if iscell(aDefs{i,3})
        % Create sub-menus.
        oMenus{i,4} = uimenu(aParent,...
            'Label', aDefs{i,1},...
            'Visible', 'off');
        oMenus{i,3} = CreateMenus(oMenus{i,4}, aDefs{i,3});
    else
        % Add callback.
        oMenus{i,4} = uimenu(aParent,...
            'Label', aDefs{i,1},...
            'Callback', aDefs{i,3},...
            'Visible', 'off');
    end
end
end