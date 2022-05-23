CurrImg=imtophat(PSiNP,strel('disk',50));
% CurrImg=CMAX;
    CurrImg2(:,:,1)=imadjust(CurrImg(:,:,1),[0 0.15],[]);
    CurrImg2(:,:,2)=imadjust(CurrImg(:,:,2));
    CurrImg2(:,:,3)=imadjust(CurrImg(:,:,3),[0.005 0.075],[]);
figure,imshow(CurrImg2)
PSiNP2=CurrImg2;

