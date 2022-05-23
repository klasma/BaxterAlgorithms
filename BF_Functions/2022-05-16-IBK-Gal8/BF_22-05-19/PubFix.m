function [PrettyImg] = PubFix(NucImg,Ai9Img)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
InputImg=cat(3,Ai9Img,zeros(size(NucImg)),NucImg);


CurrImg=imtophat(InputImg,strel('disk',50));
Ai9Img=CurrImg(:,:,1);
Ai9Pos=Ai9Img>(0.02.*2^16);
Ai9PosOpen=bwareaopen(Ai9Pos,100);

Ai9Img(~Ai9PosOpen)=0;
CurrImg(:,:,1)=Ai9Img;
% CurrImg=CMAX;
    CurrImg2(:,:,1)=imadjust(CurrImg(:,:,1),[0 0.15],[]);
    CurrImg2(:,:,2)=imadjust(CurrImg(:,:,2));
    CurrImg2(:,:,3)=imadjust(CurrImg(:,:,3));
figure,imshow(CurrImg2)
PrettyImg=CurrImg2;

end

