% iR=1
% for i=1:10
% x(i)=1
% i=i+1;
% end
Analyses=4;

% for k = 1:Analyses
%   a = k;
%   b = k + 1;
%   tmpstruct(k) = struct('a',a,'b',b);
% end
% % Display it
% tmpstruct

rng('default') % for reproducibility
% Pre-allocate loop vars
A = nan(5,4); 
B = nan(5,3); 
C = nan(5,1); 
% Create vars within loop
for i = 1:5
    A(i,:) = rand(1,4); 
    B(i,:) = rand(1,3); 
    C(i) = rand(1); 
end
% Build table
T = table(A,B,C,'VariableNames',{'BG','RO','GR'});