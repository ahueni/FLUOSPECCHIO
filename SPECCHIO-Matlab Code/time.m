%% Start
% Define Hierarchy Levels:
rawDataID           = 81;
radianceDataID      = 129;
reflectanceDataID   = 130;
connectionID        = 2;
switchedChannels    = true;

% Process Level 0 (DN) to Level 1 (Radiance)
FLOXBOX_Level_1(rawDataID, connectionID, switchedChannels);

% Process Level 1 (Radiance) to Level 2 (Reflectance); note that for QEpro
% it currently stores SIF not the Reflectance.
FLOXBOX_Level_2(radianceDataID, connectionID, switchedChannels);

