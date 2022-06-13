function [TPs] = CumCell(AllData4)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
    for i=1:length(AllData4)
        AllData5=AllData4{i};
        AllData5(all(cellfun(@isempty, AllData5),2),:) = [];
        AllData6{i}=AllData5;
    end    


TPs=[];
    for i=1:length(AllData6)
        for j=1:size(AllData6{1,i},1)
            for k=1:size(AllData6{1,i},2)
            TPs=[TPs;AllData6{1,i}{j,k}];
            end
        end
    end    
end
