function [FiberMask,FiberPerim,HistoMask,HistoPerim] = Histo(AnaImage,MiPerPix)
%   UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    
    % Find and outline high brightness areas
    TophatDisk=strel('disk',round(250*(0.34/MiPerPix))); % EditHere
    OpenDisk =strel('disk',round(5*(0.34/MiPerPix)));
    ErodeDisk=strel('disk',round(2*(0.34/MiPerPix)));
    CloseDisk=strel('disk',round(5*(0.34/MiPerPix))); 
    
    CytTopHat=imtophat(AnaImage,TophatDisk); % Clean image with tophat filter for thresholding 
    CytOpen=imerode(CytTopHat,OpenDisk);
    CytOpen=imreconstruct(CytOpen,CytTopHat);
    cyt_bw2=imerode(CytOpen,ErodeDisk);
    cyt_bw3 = bwareaopen(cyt_bw2, 2000); %%Be sure to check this threshold
    HistoMask = imclose(cyt_bw3, CloseDisk);
    HistoPerim = imdilate(bwperim(HistoMask),strel('disk',5));


    % Find and outline muscle fibers
    DilateSE = strel('disk',1);
    ErodeSE = strel('disk',3);

    BinaryImg = imbinarize(AnaImage,0.0002); % start at 0.0002 for muscle fibers
    FilterImg = imtophat(BinaryImg,TophatDisk);
    ErodeImg = imerode(FilterImg,ErodeSE);
    ReconImg = imreconstruct(ErodeImg,FilterImg);
    DilateImg = imdilate(ReconImg,DilateSE);
    nospots = bwareaopen(DilateImg,10000);
    FiberMask = imdilate(nospots,ErodeSE);
    FiberPerim = imdilate(bwperim(FiberMask),strel('disk',5));
end

