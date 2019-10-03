%% Start
% Define Hierarchy Levels:
rawDataID           = [153, 154, 155];
radianceDataID      = ;
reflectanceDataID   = ;
connectionID        = 2;
switchedChannels    = true;

% Process Level 0 (DN) to Level 1 (Radiance)
parfor i=1:size(rawDataID,2)
    FLOXBOX_Level_1(rawDataID(i), connectionID, switchedChannels);
end

% Process Level 1 (Radiance) to Level 2 (Reflectance); note that for QEpro
% it currently stores SIF not the Reflectance.
FLOXBOX_Level_2(radianceDataID, connectionID, switchedChannels);

