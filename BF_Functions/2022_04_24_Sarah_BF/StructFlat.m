function [AllData5] = StructFlat(S)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
done=0;
CatStruct={};

for i=1:size(S,1)
    i
    for j=1:size(S,2)
        j
AllData5=struct2cell(S(i,j))
AllData5(all(cellfun(@isempty, AllData5{:}),2),:) = [];
AllData6{i,j}=AllData5;
    end
end

while done==0
test=length(S);
 for i = 1:length(S)
    fields=fieldnames(S);
    for j=length(fields)
        currfield=fields{j};
        NewStruct=getfield(S(i),{1},currfield);
%        CatStructNewStruct}
    end
 end
 k=0;
 k=1+k;
done=1;
end
end

