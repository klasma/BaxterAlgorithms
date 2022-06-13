function [Test] = CumCell5(AllData4)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    Test=cell(1,length(AllData4));
%     out=AllData4;
    for i=1:length(AllData4)
        for j=1:size(AllData4{i},2)
            x=
            Test{i}{j}=AllData4{i}(:,j);   
     
        end  
    end
    
%     while iscell(out{1}{1})
%         out=horzcat(out{:});
%     end
%     out=vertcat(out{:});

end
