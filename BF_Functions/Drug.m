%%BasicThresh Code
function [bw4,bw4_perim,Label,Data] = Drug(AnaImage,AnaSettings,MiPerPix)
    
    DilateDisk=strel('disk',round(1*(0.34/MiPerPix)));
    OutlineDisk=strel('disk',round(2*(0.34/MiPerPix)));
    Drug_threshold=AnaSettings{1};
    
    Drug_threshold = Drug_threshold *intmax(class(AnaImage));
    bw4=AnaImage>Drug_threshold;
    Quant3=imdilate(bw4,DilateDisk);
    Quant4=imdilate(Quant3,OutlineDisk);
    bw4_perim=imbinarize(Quant4-Quant3);

    Conn=bwconncomp(bw4);
    Label = labelmatrix(Conn);
    Data = {};
end

