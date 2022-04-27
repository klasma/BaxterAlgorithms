function out = cellflat(celllist,level)
% Flatten nested cell arrays. 
% 
% out = CELLFLAT(celllist) searches every cell element in cellist and put them on
% the top most level. Therefore, CELLFLAT linearizes a cell array tree
% structure. 
%
% out = CELLFLAT(celllist,n) flattens the input cell array for up to `n`
% levels. Noted that the default is n = -1, indicating deepest flatten
% possible. If n = 0, returns original cell array.
%
% If you are only interested in flatten a cell array in all level, please
% take a look at the old version of cellflat(), which serves the purpose
% and much much clean than this one. Please open 'cellflat_v1_0.m', or
% simply rename 'cellflat_v1_0.m' to 'cellflat.m'.
%
% Examples: cellflat({[1 2 3], [4 5 6],{[7 8 9 10],[11 12 13 14 15]},{'abc',{'defg','hijk'},'lmnop'}}) 
% 
% Output: 
%Columns 1 through 7
%     [1x3 double]    [1x3 double]    [1x4 double]    [1x5 double]    'abc'    'defg'    'hijk'
%   Column 8 
%     'lmnop'
%
% cellflat({[],'1','2',{'a','b','c',{'x','y','z'},'r'},[123],@isempty})
% ans = 
%    []    '1'    '2'    'a'    'b'    'c'    'x'    'y'    'z'    'r'    [123]    @isempty
% 
% cellflat({[],'1','2',{'a','b','c',{'x','y','z'},'r'},[123],@isempty},1)
% ans = 
%    []    '1'    '2'    'a'    'b'    'c'    {1x3 cell}    'r'    [123]    @isempty
%
% Version: 2.0
% Author: Yung-Yeh Chang, Ph.D. (yungyeh@hotmail.com)
% Date: 4/15/2015
% Copyright 2015, Yung-Yeh Chang, Ph.D.
% See Also: cell
%% Error checking
validateattributes(celllist,{'cell'},{},mfilename,'',1);
if nargin < 2
    level = -1; % Defalut, all levels, deepest possible
elseif nargin == 2
    validateattributes(level,{'double'},{'scalar','>=',-1,'integer'},mfilename,'',2);
end
%% Output
countlevel(level); % Set counter
out = m_cellflat(celllist,level); % Flatten cell
function out = m_cellflat(celllist,level)
% Recursive function that flattens cell up to 'level' levels.
%  [out] = M_CELLFALT(celllist,level) runs recursively to seach and promote
%  cells in cell array for up to n level deep. M_CELLFLAT is the core
%  function of CELLFLAT.
%
%  See also: cellflat
% Author: Yung-Yeh Chang Ph.D. (yungyeh@hotmail.com)
% Date: 4/15/2015
out = {};
if level == 0
    out = celllist;
    return;
end
for idx_c = 1:numel(celllist)    
    if iscell(celllist{idx_c}) % is cell
        if level > -1 % n Level extraction
            remlevel = countlevel;
            if remlevel > 0 % Extract remaining levels
                out = [out m_cellflat(celllist{idx_c},remlevel)]; %#ok<*AGROW>
                countlevel(level);
            else % Last level reaches, extract value, including CELL, then reset counter
                out = [out celllist{idx_c}];                
            end
        else
            out = [out m_cellflat(celllist{idx_c},level)]; % only when level = -1
        end        
    else % not cell, extract value
        out = [out celllist(idx_c)];
        if level % level = 0 won't come here, but it stops level = -1
            countlevel(level);
        end
    end
end
function [nlevel] = countlevel(setlevel)
% Level remainder counter
%  [nlevel] = COUNTLEVEL returns number of remaining cell array level that
%  needs to be extract to `nlevel`. Every excusion results in counting down
%  1, i.e. n = n - 1
%
% [nlevel] = COUNTLEVEL(setlevel) initiates counter to
%  `setlevel` and returns the current counter value in `nlevel`(i.e. nlevel
%  = setlevel).
%
% Author: Yung-Yeh Chang Ph.D. (yungyeh@hotmail.com)
% Date: 4/15/2015
persistent n;
if isempty(n) 
    n = -1;
end
if nargin < 1
    n = n - 1;
else 
   n = setlevel; 
end
if nargout > 0
    nlevel = n;
end