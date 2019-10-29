function [user_data] = autoLoadCampaignData(user_data, campaignID, filePath)
import ch.specchio.file.reader.campaign.*;
% set up a campaign data loader
user_data.cdl = SpecchioCampaignDataLoader(user_data.specchio_client);

% Get campaign to be loaded by its ID (The campaign ID can be selected in
% the SPECCHIO Data Browser GUI using the context sensitive menu in the
% 'matching spectra' field
user_data.campaign = user_data.specchio_client.getCampaign(campaignID);
% disp(user_data.campaign.getName());

% Add file path
user_data.campaign.addKnownPath(filePath)

% load campaign data
user_data.cdl.set_campaign(user_data.campaign);
user_data.cdl.start();

delay = 0.1;  % 10 milliseconds
while user_data.cdl.isAlive
    pause(delay);  % a slight pause before checking again if thread is alive
    disp('.');
end

disp(['Number of parsed files: ' num2str(user_data.cdl.getParsed_file_counter)])
disp(['Number of inserted files: ' num2str(user_data.cdl.getSuccessful_file_counter)])
% wait for loading thread to finish: otherwise the number of parsed and
% loaded files will be wrong as thread is still working.
end
