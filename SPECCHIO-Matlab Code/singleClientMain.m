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
%% Load Raw Data 
% Define connection
connectionID    = 2;
% Connect
user_data.cf              = SPECCHIOClientFactory.getInstance();
user_data.descriptor_list = cf.getAllServerDescriptors();
user_data.specchio_client = cf.createClient(descriptor_list.get(connectionID));

% set up a campaign data loader
user_data.cdl = SpecchioCampaignDataLoader(specchio_client);

% Get campaign to be loaded by its ID (The campaign ID can be selected in
% the SPECCHIO Data Browser GUI using the context sensitive menu in the
% 'matching spectra' field
user_data.campaign = specchio_client.getCampaign(49);

% Add file path
fileStoragePath = 'C:\Users\bbuman\Documents\GitHub\FLUOSPECCHIO\Example Data\CH-OE2_Oensingen\2019\190611_tinysubset';
user_data.campaign.addKnownPath(fileStoragePath)

% load campaign data
user_data.cdl.set_campaign(campaign);
user_data.cdl.start();

% wait for loading thread to finish: otherwise the number of parsed and
% loaded files will be wrong as thread is still working.
delay = 0.01;  % 10 milliseconds
while cdl.isAlive  
    pause(delay);  % a slight pause before checking again if thread is alive
end

disp(['Number of parsed files: ' num2str(cdl.getParsed_file_counter)])
disp(['Number of inserted files: ' num2str(cdl.getSuccessful_file_counter)])


% Box setup:
switchedChannels    = true;

%% Processing L0 -> L1

user_data.campaign = specchio_client.getCampaign(49);

% Calculate QIs

% Get Radiance
for j=1:size(rawDataID,2)
    node    = hierarchy_node(rawDataID(j), "", "");
    DN_ids  = user_data.specchio_client.getSpectrumIdsForNode(node);
    FLOXBOX_Level_1(connectionID, switchedChannels, DN_ids);
end 

%% Process L1 --> L2

% Calculate QIs

% Get Reflection and SIF
for j=1:size(radianceDataID,2)
    %% Level 1 -> Level 2
    % Process Level 1 (Radiance) to Level 2 (Reflectance); note that for QEpro
    % it currently stores SIF not the Reflectance.
    FLOXBOX_Level_2(radianceDataID(j), connectionID, switchedChannels);
end

% Calculate QIs 

