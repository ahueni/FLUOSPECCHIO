%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   FLUOSPECCHIO - MAIN PROCESSING SCRIPT
%
%
%   INPUT:
%   fileStoragePath     : Path to the folder(s) containing the .CSV(s)
%   db_connector_id     : Index of the database connection to use
% 
%   OUTPUT:
%   Fully check, filter and process your FloX Data.
%   
%   MISC:   
%   Specchio API        : https://specchio.ch/javadoc/
%   
%
%   AUTHOR:
%   Andreas Hueni, RSL, University of Zurich
%
%   EDITOR:
%   Bastian Buman, RSWS, University of Zurich
%
%   DATE:
%   12-Sep-2019


rawDataID       = 0;
radianceDataID  = 0;

% Define Connection info:
connectionID        = 2;

% Box setup:
switchedChannels    = true;

% Add path
addpath(genpath('Resources'));

% Import specchio functionality:
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.gui.*;
import ch.specchio.types.*;
import ch.specchio.*;

% connect to SPECCHIO
user_data.cf                    = SPECCHIOClientFactory.getInstance();
user_data.db_descriptor_list    = user_data.cf.getAllServerDescriptors();
user_data.specchio_client       = user_data.cf.createClient(user_data.db_descriptor_list.get(connectionID));
%% processing
for j=1:size(rawDataID,2)
  
    node    = hierarchy_node(rawDataID(j), "", "");
    DN_ids  = user_data.specchio_client.getSpectrumIdsForNode(node);
    FLOXBOX_Level_1(connectionID, switchedChannels, DN_ids);
end 


for j=1:size(radianceDataID,2)
    %% Level 1 -> Level 2
    % Process Level 1 (Radiance) to Level 2 (Reflectance); note that for QEpro
    % it currently stores SIF not the Reflectance.
    FLOXBOX_Level_2(radianceDataID(j), connectionID, switchedChannels);
end

