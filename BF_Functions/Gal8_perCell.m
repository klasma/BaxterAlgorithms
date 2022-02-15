function [GalPals,Gal8Signal,Gal_bw_Perim,Puncta,Background] = Gal8_perCell(Img,Gal8MinThreshold,CytPos,MiPerPix,Cyt_WS)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
            Gal8TophatDisk=strel('disk',round(6*(0.34/MiPerPix)));% EditHere
            Gal8OpenDisk =strel('square',round(2*(0.34/MiPerPix)));
            Gal8DilateDisk=strel('disk',round(1*(0.34/MiPerPix)));
            Gal8OutlineDisk=strel('disk',round(2*(0.34/MiPerPix)));

Gal8_Img=wiener2(Img);
Gal8TH=imtophat(Gal8_Img,Gal8TophatDisk);
Gal8Open=imopen(Gal8TH,Gal8OpenDisk);

Gal8MinValue= Gal8MinThreshold*intmax(class(Img));
Gal8Quant2=Gal8Open-Gal8MinValue;
Gal8Quant2(Gal8Quant2<=0)=0;
Gal8Quant3=bwareaopen(Gal8Quant2,4);
% Gal8Quant3(~Cyt_WS)=0;
Gal8Quant3(~CytPos)=0;
Gal8Quant3=imdilate(Gal8Quant3,Gal8DilateDisk);
Gal8Quant4=imdilate(Gal8Quant3,Gal8OutlineDisk);
Gal_bw_Perim=imbinarize(Gal8Quant4-Gal8Quant3);
GalPals=Img;
GalPals(~Gal8Quant3)=0;

 NucOpenDisk= strel('disk',round(10*(0.34/MiPerPix)));
 Gal8Fuzz=imopen(Img,NucOpenDisk);

Puncta=regionprops(Gal8Quant3,Img,'Area','Centroid','MeanIntensity');
Background=regionprops(Gal8Quant3,Gal8Fuzz,'Area','Centroid','MeanIntensity');
for i=1:length([Puncta(:).MeanIntensity])
    Puncta(i).Background = Background(i).MeanIntensity;
    CellNumber=round(Puncta(i).Centroid);
    Puncta(i).Cell = Cyt_WS(CellNumber(1),CellNumber(2));
end
%need to figure out way to subtract out surrounding brightness for each individual Point
RingMeanInt=2; %need to figure out way to subtract out surrounding brightness for each individual Point
Gal8Signal=sum((vertcat(Puncta.MeanIntensity).*vertcat(Puncta.Area)));
% Gal8Signal=Gal8Signal';
end

