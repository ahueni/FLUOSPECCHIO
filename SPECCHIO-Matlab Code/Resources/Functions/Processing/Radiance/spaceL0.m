classdef spaceL0 < SpecchioSpaceInterface
    % ==================================================
    % Public Properties
    % ==================================================
    properties (Access = public) 
        space;                   % Space object
        level = 1;               % uint varible which denotes the current processing level (0,1,2,..)
        unit = 'Radiance';       % String describing the data unit (e.g. 'Radiance');
        newFolderName;   
        starterContext;          % Containing the information needed from Starter to do all calculations, qi and db-updates
        spaceSpectrumIds;        % Spectrum Ids of current Space
        provenance_spectrum_ids; % extracted spectrum id's for radiance (level one)                                            
        MetaData;                % HashMap
        ValuesToUpdate;          % HashMap
        allGroupsSpectrumIds;    % AVMatchingList of Groups containing AVMatchingList of Spectra Ids
        InstrumentType;          % Defines the current instrument type
        InstrumentId;            % current Instrument ID
        calUpCoef;               % calibration up coefficient of current instrument
        calDownCoef;             % calibration down coefficient of current instrument
        calibrationMetadata;     % Metadata of calibration used in currentInstrument
        integrationTime;         % Metadata integration time
        channelSwitched;         % True if the instrument has switched channels; % = java.util.HashMap;   
        processedIds;            % newly processed ids (from insert);
    end
    
    % ==================================================
    % Private Methods
    % ==================================================
     methods (Access = public)
         function this = spaceL0(context, space)
             this.starterContext  = context;
             this.space           = space;
         end
               
         function this = setUp(this)
             this.spaceSpectrumIds = this.space.getSpectrumIds;
             this.MetaData        = java.util.HashMap;
             this.ValuesToUpdate  = java.util.HashMap;
             this.newFolderName   = this.unit;
         end
         
         function this = helperFunctions(this)
             this = getCalibrationCoeffs(this);
         end
         
         function this = getCalibrationCoeffs(this)
            this.calUpCoef = [];
            this.calDownCoef = [];

            % get instrument and calibration
            if(this.space.get_wvl_of_band(0) < 500)
                this.InstrumentType = 1; % Broadband
            else
                this.InstrumentType = 2; % Fluorescence
            end
            
            this.InstrumentId = this.space.getInstrumentId();

            
            this.calibrationMetadata = this.starterContext.specchioClient.getInstrumentCalibrationMetadata(this.InstrumentId);

            for i = 1 : length(this.calibrationMetadata)
                cal = this.calibrationMetadata(i);
                if(strcmp(cal.getName(), 'up_coef'))
                    this.calUpCoef = cal.getFactors();
                end
                if(strcmp(cal.getName(), 'dw_coef'))
                    this.calDownCoef = cal.getFactors();
                end
            end
            this = checkChannelSwitching(this);
            if (this.channelSwitched == true)
               this = this.switchCoefficients();
            end
         end
         
         function this = checkChannelSwitching(this)
             % check if the tower is laegeren, which needs a
             % different processing
             if(strcmp(this.space.getInstrument().getInstrumentNumber(), '015'))
                 this.channelSwitched = true;
             else
                 this.channelSwitched = false;
             end
         end
         
         function this = switchCoefficients(this)
             
             tmp = this.calDownCoef;
             this.calDownCoef = this.calUpCoef;
             this.calUpCoef = tmp;

         end
         
         function this = calculations(this)
            % ==================================================
            % GET GROUPS
            % ==================================================
             this.allGroupsSpectrumIds = this.starterContext.specchioClient.sortByAttributes(...
                 this.space.getSpectrumIds, 'Acquisition Time')...
                 .getSpectrum_id_lists(); % AVMatchingListCollection-Object<AVMatchinLists> -> ArrayList<AVMatchingList>
             
             for k = 0 : (this.allGroupsSpectrumIds.size() - 1) % -1 : because matlab starts at 1, but java starts at 0
                 % get spectrum ids for a single group
                 currentGroupSpectrumIds = this.allGroupsSpectrumIds.get(k).getSpectrumIds(); % Java.util.ArrayList<Integer> spectrumids
                 currentGroupVectors = java.util.ArrayList();
                 
                 % Get vectors for currentGroup
                 % check if multiple versions of csv files available
                 if currentGroupSpectrumIds.size() ~= 5
                     global log
                     log = "Attention, there are multiple versions of csv files available: Please fix.";
                     return
                 end
                 
                 for l = 0 : currentGroupSpectrumIds.size() - 1
                     currentGroupVectors.add(this.space.getVector(currentGroupSpectrumIds.get(l))); % get Vector in same order as SpectrumIds are
                 end
                 
                 % Level 0 -> 1
                 this.integrationTime = this.starterContext.specchioClient.getMetaparameterValues(currentGroupSpectrumIds, 'Integration Time');
                 level1 = ProcessLevel0To1(this, currentGroupSpectrumIds, currentGroupVectors);
                 level1.main();
             end
         end
     end
    
    % ==================================================
    % Public Methods
    % ==================================================
    methods (Access = public)
        function this = main(this)
            this = setUp(this);
            this = helperFunctions(this);
            this = calculations(this);
            this.processedIds = insert(this);
        end 
    end
end