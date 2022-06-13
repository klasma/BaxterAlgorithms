function [Cyt_WS,Cyt_WS_perim] = CytNucWaterShed(Nuc_bw4,CytTopHat,cyt_bw4)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
    cytsize=size(CytTopHat);
	border = ones(cytsize);
    border(2:end-1,2:end-1) = 0;
    n_maxs=imerode(Nuc_bw4,strel('disk',1));
    n_maxs=bwareaopen(n_maxs,100);
    h=imhmin(CytTopHat,1);
    h_c=imcomplement(h);
    h_c_min=imimposemin(h_c, n_maxs);
    L_n = watershed(h_c_min);
    L_n(~cyt_bw4) = 0;
    borderInverse=~border;
    L_n(~borderInverse) = 0;
    howdy=L_n;
    Cyt_WS=imfill((howdy),4,'holes');
    Cyt_WS_perim = imdilate(bwperim(Cyt_WS),strel('disk',1));
    
end

