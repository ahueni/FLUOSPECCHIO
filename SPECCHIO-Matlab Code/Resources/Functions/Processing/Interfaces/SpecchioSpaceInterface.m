classdef (Abstract) SpecchioSpaceInterface
    % SPECCHIOLEVELINTERFACE defines a common ground to define
    % level-classes which can execute several calculations and 
    % quality-indices on a single group
    
    % ==================================================
    % Protected Properties
    % ==================================================
    properties (Abstract)
        level;                   % uint varible which denotes the current processing level (0,1,2,..)
        unit;                    % String describing the data unit (e.g. 'Radiance');
        newFolderName;           % name of the folder in the hierarchy, required to get the hierarchy id 
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
        integrationTime;         % Metadata integration time % = java.util.HashMap;    
        channelSwitched;         % True if the instrument has switched channels; 
        processedIds;            % newly processed ids (from insert);
   end
    
    % ==================================================
    % Abstract Methods
    % ==================================================
    methods (Abstract=true)
        setUp(this)
        helperFunctions(this);
        calculations(this);
    end
    
    methods (Access = public)
        function main(this, space)
            % MAIN calls all needed methods in the correct order
            % to start processing of one space
            setUp(this, space);
            helperFunctions(this);
            calculations(this);
            insert(this)
        end
    end
end