function [SpotData] = LabelAnalysis(LiveData,Img2,Well,Timepoint)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% Img2= LiveData{1, 4};   
for stella=1:length(LiveData)
%         wellname=matlab.lang.makeValidName(strcat('w',Well));
%         timename=matlab.lang.makeValidName(strcat('t',Timepoint));
%         wellnum=str2num(Well);
%         timenum=str2num(Timepoint);
        
         area= nnz(LiveData{1,stella}.bw4);
         LabelMax=max(LiveData{1,stella}.Label,[],'all');
         SpotData(stella,1)= str2num(Well);
         SpotData(stella,2)= str2num(Timepoint);
         SpotData(stella,3)= stella;
         SpotData(stella,4)= area;
         SpotData(stella,5)= LabelMax;
         
        for milo=1:length(Img2(1,1,:))
            DataImage=Img2(:,:,milo);
            DataMask=LiveData{1,stella}.bw4;
            SumInt=sum(DataImage(DataMask));
            InvInt=sum(DataImage(~DataMask));
            Place=4+milo*2;
            Place2=5+milo*2;
            SpotData(stella,Place)= SumInt;
            SpotData(stella,Place2)= InvInt;
            
        end
        
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
    
end

