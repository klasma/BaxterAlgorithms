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
            SumFeat=sum(DataImage(CurrFeat));
            AreaFeat=nnz(CurrFeat);

            TidyFeat{FeatPass}={wellnum,timenum,AnaPass,ImgPlane,FeatPass,SumFeat,AreaFeat};
        end
        TidyFeat2{ImgPlane}=TidyFeat;
       
    end
    TidyFeat3{AnaPass}=TidyFeat2;
end

end




