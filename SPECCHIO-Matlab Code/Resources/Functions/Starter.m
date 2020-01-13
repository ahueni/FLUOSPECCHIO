% needs adding specchio client jar to C:\Program Files\MATLAB\R2019b\toolbox\local\classpath.txt
classdef Starter
    % ==================================================
    % Constant Properties
    % ==================================================
    properties(Constant = true)
        % Path to SPECCHIO-client.jar as String must be set on installation
        specchioClientPath string = 'C:\Program Files\SPECCHIO\specchio-client.jar';
    end
    
    % ==================================================
    % Public Properties
    % ==================================================
    properties (Access = public)
        campaignId;             % campaign Id to be processed as 64 bit unsigned Integer
        campaign;               % campaign object
        connectionId;           % the id to be used to connect to the server
        specchioClient;         % SPECCHIO-client instance to be used
        hierarchyIdMap;         % Key = (String) Name of Hierarchy, Value = (uint) Id of Hierarchy
        newHierarchyId;         % new hierarchy id
        currentHierarchyId;     % current hierarchy id
        currentSpace;           % space that is currently processed
        currentDNIds;           % current Hierarchy DNIds
        allGroupsSpectrumIds;   % AVMatchingList of Groups containing AVMatchingList of Spectra Ids
        currentInstrumentType;  % Defines the current instrument type
        currentInstrumentId;    % current Instrument ID
        calUpCoef;              % calibration up coefficient of current instrument
        calDownCoef;            % calibration down coefficient of current instrument
        calibrationMetadata;    % Metadata of calibration used in currentInstrument
        integrationTime;        % Metadata integration time
        channelSwitched;        % True if the instrument has switched channels
    end
    
    % ==================================================
    % Private Methods
    % ==================================================
    methods(Access = private)
        function this = setUp(this)
            % SETUP setup class for SPECCHIO post processing
            % adds the current specchioClientPath to dynamic 
            % java classpath
            % javaaddpath(this.specchioClientPath); does not work currently
                        
            % connect to server
            specchioClientFactory   = ch.specchio.client.SPECCHIOClientFactory.getInstance();
            serverDescriptors       = specchioClientFactory.getAllServerDescriptors();

            this.specchioClient     = specchioClientFactory.createClient(serverDescriptors.get(this.connectionId));
            this.campaign           = this.specchioClient.getCampaign(this.campaignId);
        end
        
        function this = getCalibrationCoeffs(this, space)
            % CALIBRATESPACE sets the calibration coefficients as well as 
            % instrumentType, instrumentId and calibrationMetadata
            
            this.calUpCoef = [];
            this.calDownCoef = [];

            % get instrument and calibration
            if(space.get_wvl_of_band(0) < 500)
                this.currentInstrumentType = 1; % Broadband
            else
                this.currentInstrumentType = 2; % Fluorescence
            end
            
            this.currentInstrumentId = space.getInstrumentId();
            
            if space.getInstrument().getInstrumentNumber() == '015'
               this.channelSwitched = true;
               this.switchCoefficients();
            end
            this.calibrationMetadata = this.specchioClient.getInstrumentCalibrationMetadata(this.currentInstrumentId);

            for i = 1 : length(this.calibrationMetadata)
                cal = this.calibrationMetadata(i);
                if(strcmp(cal.getName(), 'up_coef'))
                    this.calUpCoef = cal.getFactors();
                end
                if(strcmp(cal.getName(), 'dw_coef'))
                    this.calDownCoef = cal.getFactors();
                end
            end 
        end
        
        function this = createHierarchy(this, parentId)
            map = containers.Map;
            map('Parent') = parentId;
            % Radiance
            map('Radiance') = this.specchioClient.getSubHierarchyId(this.campaign, 'Radiance', parentId);
            % Reflectance
            reflectanceId = this.specchioClient.getSubHierarchyId(this.campaign, 'Reflectance', parentId);
            map('Reflectance') = reflectanceId;
            % SIF
            sifId = this.specchioClient.getSubHierarchyId(this.campaign, 'SIF', parentId);
            map('SIF') = sifId;
            % Subdirectories of Reflectance
            map('Apparent Reflectance') = this.specchioClient.getSubHierarchyId(this.campaign, 'Apparent Reflectance', reflectanceId);
            map('True Reflectance') = this.specchioClient.getSubHierarchyId(this.campaign, 'True Reflectance', reflectanceId);
            % Subdirectories of SIF
            map('SpecFit') = this.specchioClient.getSubHierarchyId(this.campaign, 'SpecFit', sifId);
            map('SFM') = this.specchioClient.getSubHierarchyId(this.campaign, 'SFM', sifId);
            this.hierarchyIdMap = map;
        end
              
        function this = switchCoefficients(this)
            if this.currentInstrumentType == 2
                tmp = this.calDownCoef;
                this.calDownCoef = this.calUpCoef;
                this.calUpCoef = tmp;
            end
        end
        
        function this = process(this)
            % PROCESS starts the post processing of the current
            % campaign specified by campaignId using the 
            % SPECCHIO client in specchioClientPath
            
            unpr_hierarchies = this.specchioClient.getUnprocessedHierarchies(num2str(this.campaignId));
            
            for i = 0 :(length(unpr_hierarchies) - 1) % -1 : because matlab starts at 1, but java starts at 0
                try
                    this.currentHierarchyId = unpr_hierarchies.get(i);
                catch e
                    global log
                    log = "No unprocessed hierarchy available";
                    return
                end
                
                % Go trough current hierarchy
                currentParentId     = this.specchioClient.getHierarchyParentId(this.currentHierarchyId);
                node                = ch.specchio.types.hierarchy_node(this.currentHierarchyId, "", "");
                this.currentDNIds   = this.specchioClient.getSpectrumIdsForNode(node);
                    
                % Create folder structure in Hierarchy
                this    = this.createHierarchy(currentParentId);

                % get spaces for selected spectra
                spaces  =  this.specchioClient.getSpaces(this.currentDNIds, 'File Name'); % Array of spaces

                % for each space process all levels
                for j = 1 : length(spaces)

                    % Load Space
                    try
                        this.currentSpace = this.specchioClient.loadSpace(spaces(j));
                    catch e
                        e.message
                        if(isa(e,'matlab.exception.JavaException'))
                            ex = e.ExceptionObject;
                            assert(isjava(ex));
                            ex.printStackTrace;
                        end
                    end

                    % Get calibration data
                    this = getCalibrationCoeffs(this, this.currentSpace);

                    % Get Spectrum ids of all Groups in current Space
                    this.allGroupsSpectrumIds = this.specchioClient.sortByAttributes(...
                        this.currentSpace.getSpectrumIds, 'Acquisition Time')...
                        .getSpectrum_id_lists(); % AVMatchingListCollection-Object<AVMatchinLists> -> ArrayList<AVMatchingList>

                    for k = 0 : (this.allGroupsSpectrumIds.size() - 1) % -1 : because matlab starts at 1, but java starts at 0
                        % get spectrum ids for a single group
                        currentGroupSpectrumIds = this.allGroupsSpectrumIds.get(k).getSpectrumIds(); % Java.util.ArrayList<Integer> spectrumids
                        currentGroupVectors = java.util.ArrayList();

                        % Get vectors for currentGroup
                        % check if multiple versions of csv files available
                        if currentGroupSpectrumIds.size() ~= 5
                            global log
                            log = "Attention, there are multiple versions of csv files available: Please fix by hand";
                            return
                        end
                        
                        for l = 0 : currentGroupSpectrumIds.size() - 1
                            currentGroupVectors.add(this.currentSpace.getVector(currentGroupSpectrumIds.get(l))); % get Vector in same order as SpectrumIds are
                        end

                        % Level 0 -> 1
                        this.integrationTime = this.specchioClient.getMetaparameterValues(currentGroupSpectrumIds, 'Integration Time');
                        level1 = ProcessLevel0To1(this, currentGroupSpectrumIds, currentGroupVectors);
                        % save the new spectra ids
                        newSpectrumIds = level1.main();
                       
                        % Level 1 -> 2
                        %level2 = ProcessLevel1To2(this, newSpectrumIds);
                        % save the change space to be used in next level
                        %newSpectrumIds = level2.main();

                        % Level 2 -> 3
                        %level3 = ProcessLevel2To3(this, space);
                        %level3.main();
                    end
                end
            end
        end
    end
    
    % ==================================================
    % Public Methods
    % ==================================================
    methods (Access = public)
        function this = Starter(campaignId, connectionId)
            % STARTER Constructor for Starter class
            % campaignId is a 64bit unsigned integer refering to
            % an existing SPECCHIO campaignId
            this.campaignId = campaignId;  
            this.connectionId = connectionId;
            this.channelSwitched = false;
        end
               
        function main(this)
            % write success log, if error occurs this log will be
            % overwritten
            global log
            log = "Successfully calculated spectra levels and qi's";
            % MAIN calls all needed methods in the correct order 
            % to start processing all data
            this = setUp(this);
            this = process(this);
        end
    end
end