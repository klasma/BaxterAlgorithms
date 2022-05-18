function [TidyFeat] = LabelAnalysis(LiveData,Img2,LabelInput)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% Img2= LiveData{1, 4};
Well=LabelInput{1};
Timepoint=LabelInput{2};
CytosolicPass=LabelInput{3};
 CytoMask=LiveData{CytosolicPass,1}.Label;
 CytoMask=gpuArray(CytoMask);
 CytMatch=0;
 Img2=gpuArray(Img2);
 TidyFeat=cell(length(LiveData)*length(Img2(1,1,:)),7);
pass=0;
for AnaPass=1:length(LiveData)

    wellnum=str2double(Well)+1;
    timenum=str2double(Timepoint)+1;

    
%     LabelMax=max(LiveData{AnaPass,1}.Label,[],'all');
    DataMask=gpuArray(LiveData{AnaPass,1}.Label);
%     DataMask=gpuArray(DataMask);  
    
    for ImgPlane=1:length(Img2(1,1,:))
        pass=pass+1;
        DataImage=Img2(:,:,ImgPlane);
        stats=regionprops(DataMask,DataImage,'Area','Centroid','BoundingBox','MaxIntensity','MeanIntensity','MinIntensity','EquivDiameter','Extent');       
        SumFeats=sum([stats.Area].*[stats.MeanIntensity],'all');
        AreaFeats=sum([stats.Area],'all');
        
        if ImgPlane==1
             
                CytMatch=gpuArray([stats.Centroid]);
                CytMatch=round(CytMatch);
                CytMatch=reshape(CytMatch,2,[])';
                CytMatch=sub2ind(size(DataMask),CytMatch(:,2),CytMatch(:,1));
                CellBody=CytoMask(CytMatch);
                CellBody2=num2cell(gather(CellBody));
            
            
        end  
        
        [stats.Cell]=deal(CellBody2{:});
        
        Data={wellnum,timenum,AnaPass,ImgPlane,SumFeats,AreaFeats,stats};
        TidyFeat(pass,:)=Data;

    end
    

end

end




