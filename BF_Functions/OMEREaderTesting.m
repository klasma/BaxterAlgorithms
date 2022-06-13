clear, close all
ImgFile=char("D:\Dropbox (VU Basic Sciences)\Duvall Confocal\Duvall Lab\Brock Fletcher\2021-09-21-DB-Addition\PSINPsDB Screen001.nd2");
r = loci.formats.Memoizer(bfGetReader(),0);
% Initialize the reader with an input file to cache the reader
r.setId(ImgFile);
% Close reader
NumSeries=r.getSeriesCount();
r.close()
nWorkers = 4;
ParSplit=[1:nWorkers:NumSeries];
% 'Hiii'
parfor i = 1 : nWorkers
    % Initialize logging at INFO level
    bfInitLogging('INFO');
    % Initialize a new reader per worker as Bio-Formats is not thread safe
    r2 = javaObject('loci.formats.Memoizer', bfGetReader(), 0);
    % Initialization should use the memo file cached before entering the
    % parallel loop
    r2.setId(ImgFile);

    % Perform work
        
        for j=ParSplit+i-2% Number of wells in ND2 File  

        % Set Current Well and other important values
        %##Would be very useful to figure out how to make this work as a parfor
        %loop, but might be quite difficult
        
        CurrSeries=j;
        %The current well that we're looking at
        r2.setSeries(CurrSeries); %##uses BioFormats function, can be swapped with something else (i forget what) if it's buggy with the GUI
         fname = r2.getSeries;
         
         %gets the name of the series using BioFormats
        Well=num2str(fname,'%05.f'); %Formats the well name for up to 5 decimal places of different wells, could increase but 5 already feels like overkill 
    %     PositionX = readeromeMeta.getPlanePositionX(CurrSeries,1).value(); %May be useful someday, but not needed here
    %     PositionY = readeromeMeta.getPlanePositionY(CurrSeries,1).value(); %May be useful someday, but not needed yet. Get's the position of the actual image. Useful for checking stuff
        T_Value = r2.getSizeT()-1;
       
    end

    % Close the reader
    r2.close()
end