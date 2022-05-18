function [TidyFeat] = LabelAnalysis(LiveData,Img2,LabelInput)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% Img2= LiveData{1, 4};
Well=LabelInput{1};
Timepoint=LabelInput{2};
CytosolicPass=LabelInput{3};
 CytoMask=LiveData{CytosolicPass,1}.Label;
 CytoMask=gpuArray(CytoMask);

 TidyFeat=cell(length(LiveData)*length(Img2(1,1,:)),7);
pass=0;
for AnaPass=1:length(LiveData)
    %         wellname=matlab.lang.makeValidName(strcat('w',Well));
    %         timename=matlab.lang.makeValidName(strcat('t',Timepoint));
    
    wellnum=str2double(Well)+1;
    timenum=str2double(Timepoint)+1;
    %          area= nnz(LiveData{1,AnaPass}.bw4);
    %          PassDataStore(AnaPass,:)=PassData
    
    LabelMax=max(LiveData{1,AnaPass}.Label,[],'all');
    DataMask=LiveData{AnaPass,1}.Label;
    DataMask=gpuArray(DataMask);  
    
    for ImgPlane=1:length(Img2(1,1,:))
        pass=pass+1;
        DataImage=gpuArray(Img2(:,:,ImgPlane));
        stats=regionprops(DataMask,DataImage,'Area','Centroid','BoundingBox','MaxIntensity','MeanIntensity','MinIntensity','EquivDiameter','Extent');    
        
        if CytMatch==0
            if LabelMax>=2
                CytMatch=[stats.Centroid];
                CytMatch=reshape(CytMatch,2,[])';
                CytMatch=round(CytMatch);
                CytMatch=sub2ind(size(DataMask),CytMatch(:,1),CytMatch(:,2))
                CellBody=CytoMask(CytMatch);
                CellBody2=num2cell(gather(CellBody));
            else
                CytMatch=1;
                CellBody2=num2cell;
            end
        end   
        [stats.Cell]=deal(CellBody2{:});
        
        SumFeats=sum([stats.Area].*[stats.MeanIntensity],'all');
        AreaFeats=sum([stats.Area],'all');
        Data={wellnum,timenum,AnaPass,ImgPlane,SumFeats,AreaFeats,stats};
        TidyFeat(pass,:)=Data;
        %         TidyFeat=vertcat(TidyFeat,Data);

        
        %         TidyFeat{ImgPlane}={wellnum,timenum,AnaPass,ImgPlane,stats};
        
%         for FeatPass=1:double(LabelMax)
%             CurrFeat=DataMask==FeatPass;
%             SumFeat=sum(DataImage(CurrFeat));
%             AreaFeat=nnz(CurrFeat);

%             TidyFeat{FeatPass}={wellnum,timenum,AnaPass,ImgPlane,FeatPass,SumFeat,AreaFeat};
%         end
%         TidyFeat2{ImgPlane}=TidyFeat;
%        TidyFeat3{AnaPass}=TidyFeat;
    end
    CytMatch=0
%     if LabelMax>=2
%         CytMatch=[stats.Centroid];
%         CytMatch=reshape(CytMatch,2,[])';
%         CytMatch=round(CytMatch);
%         CytMatch=sub2ind(size(DataMask),CytMatch(:,1),CytMatch(:,2))
%     CytosolicPass    
%     
%     
%     else
%             CytMatch=1;
%     end
    
    
%     TidyFeat3{AnaPass}=TidyFeat;
    %     TidyFeat3{AnaPass}=TidyFeat2;
end

end




