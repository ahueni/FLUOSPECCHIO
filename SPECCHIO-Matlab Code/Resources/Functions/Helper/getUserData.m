function user_data = getUserData(connectionID, campaignID, switchChannel)
%% Imports
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.types.*;
import ch.specchio.gui.*;

user_data.cf              = SPECCHIOClientFactory.getInstance();
user_data.descriptor_list = user_data.cf.getAllServerDescriptors();
user_data.specchio_client = user_data.cf.createClient(user_data.descriptor_list.get(connectionID));
user_data.campaign        = user_data.specchio_client.getCampaign(campaignID);

% Box setup (Laegeren has switched up-and-downwelling channels):
% Channel switching (true if up and downwelling was switched)
user_data.switch_channels_for_flox = switchChannel;
user_data.switch_channels_for_rox  = switchChannel;
end
