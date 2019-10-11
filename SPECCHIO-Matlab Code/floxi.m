%  FLOX L1
function floxi(connectionID, channelswitched, hierarchyID)
%% Start connection
% Import specchio functionality:
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.gui.*;
import ch.specchio.types.*;
import ch.specchio.*;

% Connect to SPECCHIO
user_data.cf                    = SPECCHIOClientFactory.getInstance();
user_data.db_descriptor_list    = user_data.cf.getAllServerDescriptors();
user_data.specchio_client       = user_data.cf.createClient(user_data.db_descriptor_list.get(connectionID));

%% Get IDS and also prepare the folder for the processed data
% Have a look at the selected data
node    = hierarchy_node(hierarchyID, "", "");
ids     = user_data.specchio_client.getSpectrumIdsForNode(node);

% Channel switching (true if up and downwelling was switched  --> LAEGEREN)
user_data.switch_channels_for_flox  = channelswitched;
user_data.switch_channels_for_rox   = channelswitched;

% controls the level where the radiance folder is created in the DB
user_data.settings.radiance_hierarchy_level = 1;

% Prepare the folder to store the data
% load first spectrum to get the hierarchy
space                   = user_data.specchio_client.getSpaces(selectedIds, 'Acquisition Time');
s                       = user_data.specchio_client.getSpectrum(space(1).getSpectrumIds.get(1), false); 
current_hierarchy_id    = s.getHierarchyLevelId(); 

% move within hierarchy to the level where the new directory is to be
% created
for i=1:user_data.settings.radiance_hierarchy_level
    parent_id               = user_data.specchio_client.getHierarchyParentId(current_hierarchy_id);
    current_hierarchy_id    = parent_id;
end

% Get the campaign 
campaign                            = user_data.specchio_client.getCampaign(s.getCampaignId());
% Creates the folder if not already there
user_data.processed_hierarchy_id    = user_data.specchio_client.getSubHierarchyId(campaign, 'Radiance', parent_id);

%% 





    

