function [GalPals,Gal8Signal,RingMeanInt,Gal8Quant5,Gal8Quant4,Gal8Quant3,Gal8Open,Gal8TH,Gal8Quant2,Puncta,Ring] = Gal8(cyt,Gal8TophatDisk,Gal8OpenDisk,Gal8DilateDisk,Gal8MinThreshold,CytPos,Gal8OutlineDisk)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
Gal8=wiener2(cyt);
Gal8TH=imtophat(Gal8,Gal8TophatDisk);
Gal8Open=imopen(Gal8TH,Gal8OpenDisk);

Gal8MinValue= Gal8MinThreshold*intmax(class(cyt));
Gal8Quant2=Gal8Open-Gal8MinValue;
Gal8Quant2(Gal8Quant2<=0)=0;
Gal8Quant3=bwareaopen(Gal8Quant2,4);
Gal8Quant3(~CytPos)=0;
Gal8Quant3=imdilate(Gal8Quant3,Gal8DilateDisk);
Gal8Quant4=imdilate(Gal8Quant3,Gal8OutlineDisk);
Gal8Quant5=imbinarize(Gal8Quant4-Gal8Quant3);
GalPals=cyt;
GalPals(~Gal8Quant3)=0;

Puncta=regionprops(Gal8Quant3,cyt,'Area','Centroid','MeanIntensity');
Ring=regionprops(Gal8Quant5,cyt,'Area','Centroid','MeanIntensity'); %need to figure out way to subtract out surrounding brightness for each individual Point
RingMeanInt=2; %need to figure out way to subtract out surrounding brightness for each individual Point
Gal8Signal=sum((vertcat(Puncta.MeanIntensity).*vertcat(Puncta.Area)));
% Gal8Signal=Gal8Signal';
end

