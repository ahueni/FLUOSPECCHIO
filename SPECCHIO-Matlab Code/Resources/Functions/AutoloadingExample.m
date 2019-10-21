%% Automated Data Loading Example 
% 
% Requirements: SPECCHIO V3.3.0.1 or higher
% Classpath: configured for a standard installation under macOS
%
% (c) ahueni, 17.10.2017
%
%%

% dynamic classpath setting: adapt according to your system installation
javaaddpath ({'/Applications/SPECCHIO/SPECCHIO.app/Contents/Java/specchio-client.jar', ...
    '/Applications/SPECCHIO/SPECCHIO.app/Contents/Java/specchio-types.jar'});


import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.types.*;
import ch.specchio.gui.*;
import ch.specchio.file.reader.campaign.*;

% connect to server
cf = SPECCHIOClientFactory.getInstance();
descriptor_list = cf.getAllServerDescriptors();
specchio_client = cf.createClient(descriptor_list.get(0)); % connect to n-th connection description

% set up a campaign data loader
cdl = SpecchioCampaignDataLoader(specchio_client);

% Get campaign to be loaded by its ID (The campaign ID can be selected in
% the SPECCHIO Data Browser GUI using the context sensitive menu in the
% 'matching spectra' field
campaign = specchio_client.getCampaign(18);

% optional: add a new path to the campaign from which to load
% campaign.addKnownPath('/SPECCHIO Project/Campaigns/DeltaLoadingTest');

% optional: tell the campaign from which path to load
% campaign.setPath('/SPECCHIO Project/Campaigns/DeltaLoadingTest');

% load campaign data
cdl.set_campaign(campaign);
cdl.start();

% wait for loading thread to finish: otherwise the number of parsed and
% loaded files will be wrong as thread is still working.
delay = 0.01;  % 10 milliseconds
while cdl.isAlive  
    pause(delay);  % a slight pause before checking again if thread is alive
end

disp(['Number of parsed files: ' num2str(cdl.getParsed_file_counter)])
disp(['Number of inserted files: ' num2str(cdl.getSuccessful_file_counter)])





