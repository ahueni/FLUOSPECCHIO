classdef spaceL1 < SpecchioSpaceInterface
    % ==================================================
    % Public Properties
    % ==================================================
    properties (Access = public) 
        space;                   % Space object
        level = 2;               % uint varible which denotes the current processing level (0,1,2,..)
        unit = 'Reflectance';       % String describing the data unit (e.g. 'Radiance');
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
        wavelength;              % wvl = space.getAverageWavelengths();
    end
    
    % ==================================================
    % Private Methods
    % ==================================================
     methods (Access = public)
         function this = spaceL1(context, space)
             this.starterContext  = context;
             this.space           = space;
             this.wavelength      = space.getAverageWavelengths();
         end
               
         function this = setUp(this)
             this.spaceSpectrumIds = this.space.getSpectrumIds;
             this.MetaData         = java.util.HashMap;
             this.ValuesToUpdate   = java.util.HashMap;
             this.channelSwitched  = this.starterContext.channelSwitched;
         end
         
         function this = helperFunctions(this)
             this = instrumentType(this);
         end
         
         function this = instrumentType(this)
            % get instrument and calibration
            if(this.space.get_wvl_of_band(0) < 500)
                this.InstrumentType = 1; % Broadband
            else
                this.InstrumentType = 2; % Fluorescence
            end
             
         end
         
         function this = calculations(this)
            
            % ==================================================
            % GET GROUPS
            % ==================================================
             this.allGroupsSpectrumIds = this.starterContext.specchioClient.sortByAttributes(...
                 this.space.getSpectrumIds, 'File Name')...
                 .getSpectrum_id_lists(); % AVMatchingListCollection-Object<AVMatchinLists> -> ArrayList<AVMatchingList>
             
             for k = 0 : (this.allGroupsSpectrumIds.size() - 1) % -1 : because matlab starts at 1, but java starts at 0
                 % get spectrum ids for a single group
                 currentGroupSpectrumIds = this.allGroupsSpectrumIds.get(k).getSpectrumIds(); % Java.util.ArrayList<Integer> spectrumids
                 currentGroupVectors = java.util.ArrayList();
                 
                 % Get vectors for currentGroup
                 % check if multiple versions of csv files available
                 if currentGroupSpectrumIds.size() ~= 3
                     global log
                     log = "Attention, there are multiple versions of csv files available: Please fix.";
                     return
                 end
                 
                 for l = 0 : currentGroupSpectrumIds.size() - 1
                     currentGroupVectors.add(this.space.getVector(currentGroupSpectrumIds.get(l))); % get Vector in same order as SpectrumIds are
                 end
                 
                 % Level 1 -> 2
                 level1 = ProcessLevel1To2(this, currentGroupSpectrumIds, currentGroupVectors);
                 level1.main();
                 if(this.InstrumentType == 1)
                     level1.vis();
                 end
                 
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
            insert(this);
        end 
    end
end