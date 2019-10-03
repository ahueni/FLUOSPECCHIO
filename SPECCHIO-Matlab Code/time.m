%% Start
% Define Hierarchy Levels:
rawDataID           = [153, 154, 155];
radianceDataID      = [157, 156, 158];
reflectanceDataID   = ;
connectionID        = 2;
switchedChannels    = true;

% Process Level 0 (DN) to Level 1 (Radiance)
% parfor i=1:size(rawDataID,2) % Theoretically works but at some point
% throws web client exception: returned a response status of 500 Internal Server Error
for i=2:size(rawDataID,2)
    FLOXBOX_Level_1(rawDataID(i), connectionID, switchedChannels);
end

% Process Level 1 (Radiance) to Level 2 (Reflectance); note that for QEpro
% it currently stores SIF not the Reflectance.
for i=1:size(radianceDataID,2)
    FLOXBOX_Level_2(radianceDataID(i), connectionID, switchedChannels);
end
