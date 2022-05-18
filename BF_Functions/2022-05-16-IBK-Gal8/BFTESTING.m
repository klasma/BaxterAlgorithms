S1=S;
N1=fieldnames(S1)
% while isstruct(S1)
 N1=fieldnames(S1)
%  bronkity2=struct(N1{:},[])
    for i=1:length(N1)
    for j=1:size(S1,2)
    bronkity=getfield(S1(i,j),N1{i});
    bronkity( all( cell2mat( arrayfun( @(x) structfun( @isempty, x ), bronkity, 'UniformOutput', false ) ), 1 ) ) = []
        if and(i==1,j==1)
        bronkity2=bronkity    
        end
        i
        j
        bronkity2=[bronkity2,bronkity]
    end
    end
    
% end    
% for i=1:length(AllData3)
%    AllData
%    AllData5=struct2cell(AllData4{i});
%    process1=cellfun(@isempty, AllData5);
% %    process2=all(process1,1)
%    AllData6(:,process1) = [];
%    AllData7{i}=AllData6
%     for j=1:size(AllData5)
%         
% 
% 
% % process2=all(process1,2);
% % AllData5(process2,:) = [];
% % AllData6{i,j}=AllData5;
%     end
% end
% 
% while done==0
% test=length(S);
%  for i = 1:length(S)
%     fields=fieldnames(S);
%     for j=length(fields)
%         currfield=fields{j};
%         NewStruct=getfield(S(i),{1},currfield);
% %        CatStructNewStruct}
%     end
%  end
%  k=0;
%  k=1+k;
% done=1;
% end