classdef sif < SpecchioSpaceInterface
    % ==================================================
    % Public Properties
    % ==================================================
    properties (Access = public) 
        space;                   % Space object
        level = 3;               % uint varible which denotes the current processing level (0,1,2,..)
        unit = 'SIF';            % String describing the data unit (e.g. 'Radiance');
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
        nl_coefs;
        auto_nulling;
        calibrationMetadata;     % Metadata of calibration used in currentInstrument
        integrationTime;         % Metadata integration time
        channelSwitched;         % True if the instrument has switched channels; % = java.util.HashMap;
        processedIds;            % newly processed ids (from insert);
        wavelength;              % wvl = space.getAverageWavelengths();
        outF_SFM_ValuesToUpdate;
        outF_SpecFit_ValuesToUpdate;
        outR_SFM_ValuesToUpdate;
        outR_SpecFit_ValuesToUpdate;
        outF_SFM_Metadata;
        outF_SpecFit_Metadata;
        outR_SFM_Metadata;
        outR_SpecFit_Metadata;
    end
    
    % ==================================================
    % Private Methods
    % ==================================================
     methods (Access = public)
         function this = sif(context, space)
             this.starterContext  = context;
             this.space           = space;
             this.wavelength      = space.getAverageWavelengths();
         end
               
         function this = setUp(this)
             this.spaceSpectrumIds              = this.space.getSpectrumIds;
             this.MetaData                      = java.util.HashMap;
             this.ValuesToUpdate                = java.util.HashMap;
%            SPECFIT  
             this.outF_SpecFit_ValuesToUpdate   = java.util.HashMap;
%              this.outR_SpecFit_ValuesToUpdate   = java.util.HashMap;
             this.outF_SpecFit_Metadata         = java.util.HashMap;
%              this.outR_SpecFit_Metadata         = java.util.HashMap;
%            SFM
%              this.outR_SFM_Metadata             = java.util.HashMap;
%              this.outF_SFM_Metadata             = java.util.HashMap;
%              this.outF_SFM_ValuesToUpdate       = java.util.HashMap;
%              this.outR_SFM_ValuesToUpdate       = java.util.HashMap;
         end
         
         function this = helperFunctions(this)
              this = instrumentType(this);
             this = checkChannelSwitching(this);
         end
         
         function this = instrumentType(this)
            % get instrument and calibration
            if(this.space.get_wvl_of_band(0) < 500)
                this.InstrumentType = 1; % Broadband
            else
                this.InstrumentType = 2; % Fluorescence
            end
         end
         
         function this = checkChannelSwitching(this)
             % check if the tower is laegeren, which needs a
             % different processing
             if(strcmp(this.space.getInstrument().getInstrumentNumber(), '015')&& ...
                      this.InstrumentType == 1)
                 this.channelSwitched = true;
             else
                 this.channelSwitched = false;
             end
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
                 if currentGroupSpectrumIds.size() ~= 3
                     global log
                     log = "Attention, there are multiple versions of csv files available: Please fix.";
                     return
                 end
                 
                 for l = 0 : currentGroupSpectrumIds.size() - 1
                     currentGroupVectors.add(this.space.getVector(currentGroupSpectrumIds.get(l))); % get Vector in same order as SpectrumIds are
                 end
                 
                 % Level 2 -> 3
                 level3 = ProcessLevel2To3(this, currentGroupSpectrumIds, currentGroupVectors);
                 level3.main();
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
            
            % SIF from SpecFit
            this.ValuesToUpdate = this.outF_SpecFit_ValuesToUpdate;
            this.MetaData       = this.outF_SpecFit_Metadata;
            this.newFolderName  = 'SpecFit';
            insert(this);
            
%             % True reflectance from SpecFit
%             this.newFolderName  = 'True Reflectance';
%             this.ValuesToUpdate = this.outR_SpecFit_ValuesToUpdate;
%             this.MetaData       = this.outR_SpecFit_Metadata;
%             insert(this);           
%             % SIF from SFM
%             this.ValuesToUpdate = this.outF_SFM_ValuesToUpdate;
%             this.MetaData       = this.outF_SFM_Metadata;
%             this.newFolderName  = 'SFM';
%             insert(this);
%             % True reflectance from SFM
%             this.ValuesToUpdate = this.outR_SFM_ValuesToUpdate;
%             this.MetaData       = this.outR_SFM_Metadata;
%             insert(this);
        end 
    end
end