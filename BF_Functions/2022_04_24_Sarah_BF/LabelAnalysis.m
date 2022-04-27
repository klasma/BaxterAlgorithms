function [TidyFeat3] = LabelAnalysis(LiveData,Img2,Well,Timepoint)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% Img2= LiveData{1, 4};
TidyFeat={};
for AnaPass=1:length(LiveData)
    %         wellname=matlab.lang.makeValidName(strcat('w',Well));
    %         timename=matlab.lang.makeValidName(strcat('t',Timepoint));
    
    wellnum=str2num(Well)+1;
    timenum=str2num(Timepoint)+1;
    %          area= nnz(LiveData{1,AnaPass}.bw4);
    %          PassDataStore(AnaPass,:)=PassData
    
    LabelMax=max(LiveData{1,AnaPass}.Label,[],'all');
    DataMask=LiveData{1,AnaPass}.Label;
    for ImgPlane=1:length(Img2(1,1,:))
        DataImage=Img2(:,:,ImgPlane);
        for FeatPass=1:double(LabelMax)
            CurrFeat=DataMask==FeatPass;
            %              SumFeat=sum(DataImage(CurrFeat));
            %              FeatPlace=4+ImgPlane*2;
            %              FeatData(AnaPass,Place)= SumInt;
            SumFeat=sum(DataImage(CurrFeat));
            AreaFeat=nnz(CurrFeat);
%             TidyFeat.Function{AnaPass,1}.Plane{ImgPlane,1}.Feature{FeatPass,1}.Sum=SumFeat;
            TidyFeat{FeatPass}={wellnum,timenum,AnaPass,ImgPlane,FeatPass,SumFeat,AreaFeat};
        end
        TidyFeat2{ImgPlane}=TidyFeat;
%         SumTot=sum(DataImage,'all');
%         SumImg=sum(TidyFeat.Function(AnaPass).Plane(ImgPlane).Feature(FeatPass));
%         TidyImg.Function{AnaPass}.Plane{ImgPlane}=[SumImg,SumTot,LabelMax];
    end
    TidyFeat3{AnaPass}=TidyFeat2;
end
%             SumInt=sum(DataImage(DataMask));
%             InvInt=sum(DataImage(~DataMask));
%
%             PlaneData(1)=SumInt;
%             PlaneData(2)=InvInt;
%             PlaneData=(PassData,ImgPlane,PlaneData)
%             PlaneDataStore(ImgPlane,:)=PlaneData
%
%                 SumInt=sum(DataImage(DataMask));
%                 InvInt=sum(DataImage(~DataMask));
%                 Place=4+ImgPlane*2;
%              Place2=5+ImgPlane*2;
%                 SpotData(AnaPass,Place)= SumInt;
%                 SpotData(AnaPass,Place2)= InvInt;
% %             for FeatPass=1:2
% %             end
end







% AllData(wellnum+1,timenum+1)={SpotData}


%     if isempty(ExportParamNames)
%         NamCell = {};
%         ExportParamNames = {'Well','Timepoint','Analysis Pass','Area Mask','LabelMax'};
%          for g=1:length(Img2(1,1,:))
%          IntName=strcat('P',num2str(g),'Intensity_OverMask');
%          InvName=strcat('P',num2str(g),'Intensity_NotOverMask');
%          PlaneName={IntName,InvName};
%          NamCell=[NamCell,PlaneName];
%          end
%          ExportParamNames = [ExportParamNames, NamCell];
%     end



