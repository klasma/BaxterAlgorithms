% thickBoiboi=unstack(Test2,[1 2 3 4],'ImPlane','AggregationFunction',@sum);
% thickBoiboi2=cellfun(@round,thickBoiboi);
% thickBoiboi3=unstack(thickBoiboi,[5:1:16],'AF','AggregationFunction',@unique);
% newTable=groupsummary(Test2,["Well","TP0","Cell"],

% Test3=Test2((Test2(:,1)==
% Testing(=deal(Testing,
gpuTesting=Testing3;
gpuTesting(:,12:15)=deal(0);
gpuTesting=gpuArray(gpuTesting);
gpuTesting2=[];
% gpuTesting3=zeros(1,size(gpuTesting,2),'uint32','gpuArray');
% gpuTesting4=zeros(1,size(gpuTesting,2),'uint32','gpuArray');
      
for j=1:gather(max(gpuTesting(:,6),[],'all'))
    currWell=gpuTesting(gpuTesting(:,6)==j,:);
    for m=1:gather(max(currWell(:,7),[],'all'))
    currTime=currWell(currWell(:,7)==m,:);
        for k=1:gather(max(currTime(:,5),[],'all'))
            currCell=currTime(currTime(:,5)==k-1,:);
            for i=1:size(currCell,1)
           currCell(i,12:15)=mean(currCell(all(currCell(:,5:9)==[currCell(i,5:8),3],2),1:4),1);
        %    gpuTesting(i,10)= mean(gpuTesting(Product,2));
        %         Test2(Test2{i,5:8},2)

            end
            gpuTesting2=vertcat(gpuTesting2,currCell);
        end
        check=length(gpuTesting2)
        %     gpuTesting3=vertcat(gpuTesting3,gpuTesting2)
    end
    
%     gpuTesting4=vertcat(gpuTesting4,gpuTesting3)
end
% gpuTesting3=horzcat(gpuTesting,gpuTesting2);
% for i=1:size(Test22)
%     
% end