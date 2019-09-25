%% Define Hierarchy Levels:
rawDataID           = 81;
radianceDataID      = 85;
reflectanceDataID   = 83;
connectionID        = 2;
switchedChannels    = true;
%  tic;
FLOXBOX_Level_1(rawDataID, connectionID, switchedChannels);
FLOXBOX_Level_2(radianceDataID, connectionID, switchedChannels);
%  toc;
