function [bw4,Cyt_WS_perim,Cyt_WS,Data] = CytNucWaterShed(Nuc_bw4,Cyt,cyt_bw4,AnaSettings)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
    Sensitivity=AnaSettings{3};  

    cytsize=size(Cyt);
	border = ones(cytsize);
    border(2:end-1,2:end-1) = 0;
      
%     n_maxs=imerode(Nuc_bw4,strel('disk',2));
    n_maxs=Nuc_bw4;
%     n_maxs=bwareaopen(n_maxs,50);
    cyt_bw4 = cyt_bw4 | Nuc_bw4;
     
    h=imgaussfilt(Cyt,1);
    h(~cyt_bw4)=0;
    h_c=imcomplement(h);
%      h_c(n_maxs)=0;
    h_c_min=imimposemin(h_c, n_maxs);
% %     h_c_min=imhmin(h_c,Sensitivity);
%      h_c_min=imimposemin(h, n_maxs);
%     h(n_maxs)=0;
%         h_c_min=h_c;
%     h_c_min=h;
    L_n = watershed(h_c_min);
    L_n(~cyt_bw4) = 0;
    borderInverse=~border;
    L_n(~borderInverse) = 0;
    howdy=L_n;
    Cyt_WS=uint16(bwlabel(imfill((howdy),4,'holes')));
    bw4=imbinarize(Cyt_WS);
    Cyt_WS_perim = imdilate(bwperim(Cyt_WS),strel('disk',1));
     rgb=label2rgb(Cyt_WS);
    figure,
    imshow(imadjust(h_c_min))
     figure,
    imshow(rgb)
    Data = {};
end

