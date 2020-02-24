% needs adding specchio client jar to C:\Program Files\MATLAB\R2019b\toolbox\local\classpath.txt
% 
% Written by:
% Alexander Rauber, email
% Sacha Leemann, email
% Edited and adapted by:
% Bastian Buman, email
% January, 2020

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
        currentIds;
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
            specchioClientFactory       = ch.specchio.client.SPECCHIOClientFactory.getInstance();
            serverDescriptors           = specchioClientFactory.getAllServerDescriptors();

            this.specchioClient         = specchioClientFactory.createClient(serverDescriptors.get(this.connectionId));
            this.campaign               = this.specchioClient.getCampaign(this.campaignId);
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
%             map('SFM') = this.specchioClient.getSubHierarchyId(this.campaign, 'SFM', sifId);
            this.hierarchyIdMap = map;
        end
        
        function this = process(this)
            % PROCESS starts the post processing of the current
            % campaign specified by campaignId using the 
            % SPECCHIO client in specchioClientPath
            
            unpr_hierarchies = this.specchioClient.getUnprocessedHierarchies(num2str(this.campaignId));
            count = 0;
            
            for i = 0 :(size(unpr_hierarchies) - 1) % -1 : because matlab starts at 1, but java starts at 0
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
                this.currentIds     = this.specchioClient.getSpectrumIdsForNode(node);
                    
                % Create folder structure in Hierarchy
                this    = this.createHierarchy(currentParentId);
                
                % ==================================================
                % PROCESS SPACES L0 TO L1
                % ==================================================
                
                % get L0 spaces for selected spectra
                spaces  =  this.specchioClient.getSpaces(this.currentIds, 'Spectrum Number'); % Array of spaces
              

                for j = 1 : length(spaces)
                    try
                        curSpace = this.specchioClient.loadSpace(spaces(j));
                        space = spaceL0(this, curSpace);
                        space.main();
                        
                    catch e
                        e.message
                        if(isa(e,'matlab.exception.JavaException'))
                            ex = e.ExceptionObject;
                            assert(isjava(ex));
                            ex.printStackTrace;
                        end
                    end
                end
                
                
                % ==================================================
                % PROCESS SPACES L1 TO L2
                % ==================================================
                % change the current hierarchy id
                this.currentHierarchyId = cell2mat(values(this.hierarchyIdMap, {'Radiance'}));
                node                = ch.specchio.types.hierarchy_node(this.currentHierarchyId, "", "");
                this.currentIds     = this.specchioClient.getSpectrumIdsForNode(node);
                    
                % get L1 spaces for selected spectra
                spaces  =  this.specchioClient.getSpaces(this.currentIds, 'Spectrum Number'); % Array of spaces
                
                for j = 1 : length(spaces)
                    try
                        curSpace = this.specchioClient.loadSpace(spaces(j));                     
                        space = spaceL1(this, curSpace);
                        space.main();
                    catch e
                        e.message
                        if(isa(e,'matlab.exception.JavaException'))
                            ex = e.ExceptionObject;
                            assert(isjava(ex));
                            ex.printStackTrace;
                        end
                    end
                end
                
                % ==================================================
                % PROCESS SPACE(S) L2 TO L3 (SIF PRODUCT)
                % ==================================================
                % change the current hierarchy id
                this.currentHierarchyId = cell2mat(values(this.hierarchyIdMap, {'Radiance'}));
                node                = ch.specchio.types.hierarchy_node(this.currentHierarchyId, "", "");
                this.currentIds     = this.specchioClient.getSpectrumIdsForNode(node);
                
                % get L1 spaces for selected spectra
                spaces  =  this.specchioClient.getSpaces(this.currentIds, 'Spectrum Number'); % Array of spaces
                
                for j = 1 : length(spaces)
                    try
                        curSpace = this.specchioClient.loadSpace(spaces(j));
                        if (curSpace.get_wvl_of_band(0) > 500) % FLUO
                            space = sif(this, curSpace);
                            space.main();
                        end
                    catch e
                        e.message
                        if(isa(e,'matlab.exception.JavaException'))
                            ex = e.ExceptionObject;
                            assert(isjava(ex));
                            ex.printStackTrace;
                        end
                    end
                end
                count = count + 1;
                disp(['One folder processed. ' num2str(size(unpr_hierarchies)-count) ' more to go.']);
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
%           bandTimeVis(this, this.campaignId, 760);
        end
    end
end