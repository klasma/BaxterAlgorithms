function [LiveData] = BronkSegment(ImageAnalyses,Img2,MiPerPix,SegDirectory,Well,BaxterName,MakeCompImage,OverlaidDirectory)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
    for k =1:length(ImageAnalyses)

        Analysis=ImageAnalyses{k,:}{1}{1};
        AnaChan=ImageAnalyses{k,:}{2}{1};
        AnaImage=Img2(:,:,AnaChan);
        AnaSettings= ImageAnalyses{k,:}{3};

        switch Analysis
            case 'Nuc'
                [bw4,bw4_perim,Label,Data]= NuclearStain(AnaImage,AnaSettings,MiPerPix);
            case 'Cyt'
                [bw4,bw4_perim,Label,Data] = Cytosol(AnaImage,AnaSettings,MiPerPix);
            case 'CytWS'
                NucChan=ImageAnalyses{k,:}{3}{1};
                CytChan=ImageAnalyses{k,:}{3}{2};
                Cyt=LiveData{CytChan}.AnaImage;
                Nuc_bw4=LiveData{NucChan}.bw4;
                Cyt_bw4=LiveData{CytChan}.bw4;
                [Label,bw4_perim,Data] = CytNucWaterShed(Nuc_bw4,Cyt,Cyt_bw4);
            case 'Gal8'
                CytChan=ImageAnalyses{k,:}{3}{2};
                Cyt_bw4=LiveData{CytChan}.bw4;
                [bw4_perim,bw4,Label,Data] = Gal8(AnaImage,AnaSettings,Cyt_bw4,MiPerPix);
        end
        LiveData{k}.AnaImage = AnaImage;
        LiveData{k}.bw4 = bw4;
        LiveData{k}.bw4_perim = bw4_perim;
        LiveData{k}.Label=Label;
        LiveData{k}.Data=Data;

        if ImageAnalyses{k,:}{6}{1}
            SegDir=fullfile(strcat(SegDirectory,Analysis,'_',num2str(k)),Well);
            if ~exist(SegDir,'file')
                mkdir(SegDir);
            end
            ImName=strcat(BaxterName,'c' ,num2str(AnaChan,'%02.f'),'.tif');
            SegFile=fullfile(SegDir,ImName);
            imwrite(Label,SegFile);
        end
        if logical(MakeCompImage)
            if ~isempty(ImageAnalyses{k,:}{4})
                ImColor=ImageAnalyses{k,:}{4}{1};
                CompImage(:,:,ImColor)=imadjust(AnaImage,[0 Data{1}],[]);
            end
        end
    end
    if exist("CompImage",'var')
        if size(CompImage,3)<3
        CompImage(:,:,3)=zeros(size(CompImage,1),size(CompImage,2));
        colorscheme=[0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250];
         
        for k =1:length(ImageAnalyses)
            CompPerim=LiveData{k}.bw4_perim;
            CurrColor=[colorscheme(k,:)];
            CompImage=imoverlay(CompImage,CompPerim,CurrColor);
        end
        end
        CompFile=fullfile(OverlaidDirectory,strcat(BaxterName,'.tif'));
        imwrite(CompImage,CompFile);
    end
end

