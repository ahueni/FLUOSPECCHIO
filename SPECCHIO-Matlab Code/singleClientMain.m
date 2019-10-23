%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   FLUOSPECCHIO - MAIN PROCESSING SCRIPT
%
%
%   INPUT:
%   fileStoragePath     : Path to the folder(s) containing the .CSV(s)
%   db_connector_id     : Index of the database connection to use
% 
%   OUTPUT:
%   Fully check, filter, process and transfer your FloX data.
%   
%   MISC:   
%   Specchio API        : https://specchio.ch/javadoc/
%   
% 
%   AUTHOR:
%   Bastian Buman, RSWS, University of Zurich
%
%   DATE:
%   12-Sep-2019 V1
%   23-Oct-2019 V2

%% Add Path
addpath(genpath('Resources'));
%% Imports
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.types.*;
import ch.specchio.gui.*;
import ch.specchio.file.reader.campaign.*;
%% transfer raw data to DB
% Define connection
connectionID    = 0;

% Connect
user_data.cf              = SPECCHIOClientFactory.getInstance();
user_data.descriptor_list = user_data.cf.getAllServerDescriptors();
user_data.specchio_client = user_data.cf.createClient(user_data.descriptor_list.get(connectionID));

% set up a campaign data loader
user_data.cdl = SpecchioCampaignDataLoader(user_data.specchio_client);

% Get campaign to be loaded by its ID (The campaign ID can be selected in
% the SPECCHIO Data Browser GUI using the context sensitive menu in the
% 'matching spectra' field
user_data.campaign = user_data.specchio_client.getCampaign(49);
disp(user_data.campaign.getName());

% Add file path
fileStoragePath = 'C:\Users\bbuman\Documents\GitHub\FLUOSPECCHIO\Example Data\CH-OE2_Oensingen\2019\190611_tinysubset';
fileName        = '190611_tinysubset';
user_data.campaign.addKnownPath(fileStoragePath)

% load campaign data
user_data.cdl.set_campaign(user_data.campaign);
user_data.cdl.start();

delay = 0.1;  % 10 milliseconds
while user_data.cdl.isAlive  
    pause(delay);  % a slight pause before checking again if thread is alive
end

disp(['Number of parsed files: ' num2str(user_data.cdl.getParsed_file_counter)])
disp(['Number of inserted files: ' num2str(user_data.cdl.getSuccessful_file_counter)])


% wait for loading thread to finish: otherwise the number of parsed and
% loaded files will be wrong as thread is still working.

%% Processing L0 -> L1
% Box setup:
switchedChannels   = true;

% int getHierarchyId(Campaign campaign,
%                    java.lang.String name,
%                    int parent_id)
%             throws SPECCHIOClientException
% 
% Get the identifier of a hierarchy node.
% 
% Parameters:
%     campaign - the campaign in which the node is located
%     name - the name of the node
%     parent_id - the parent of the node

rawDataID = user_data.specchio_client.getSubHierarchyId(fileName, 0);
% Calculate QIs-0

% Write QIs-0 to DB

% Get Radiance
node    = hierarchy_node(rawDataID, "", "");
DN_ids  = user_data.specchio_client.getSpectrumIdsForNode(node);
FLOXBOX_Level_1(connectionID, switchedChannels, DN_ids);

%% Process L1 --> L2

% Calculate QIs-1

% Write QIs-1 to DB

% Get Reflection and SIF
for j=1:size(radianceDataID,2)
    %% Level 1 -> Level 2
    % Process Level 1 (Radiance) to Level 2 (Reflectance); note that for QEpro
    % it currently stores SIF not the Reflectance.
    FLOXBOX_Level_2(radianceDataID(j), connectionID, switchedChannels);
end

% Calculate QIs-2

% Write QIs-2 to DB

