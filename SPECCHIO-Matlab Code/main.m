%% Script: Main processing routine for the FLOXBOX 
%   INPUT:
%   hierarchy_id        : hierarchy_id of the SPECCHIO DN hierarchy
%   Java class path     : \MATLAB\R2019a\toolbox\local\classpath.txt -->
%                         make sure to include your specchio installation (specchio-client.jar)
%                         at the top of the classpath.txt
%
%   db_connector_id     : index into the list of known database connection (identical to SPECCHIO client app)
% 
%   OUTPUT:
%   Processing raw (Level-0) FLOXBOX data to Radiance (Level-1) and
%   Reflectance (Level-2)
%   
%   MISC:   
%   The FLOXBOX has two sensors: (1) is the FLAME (in these files sometimes called ROX), full range sensor, files
%   are named F*.csv; (2) is the QEpro, higher resolution for SIF retrieval (in these files someties called FLOX), files are named *.csv. 
%   Naming these sensors ROX or FLOX respectively is wrong, and will be changed to FLAME and QEpro.
%
%   AUTHOR:
%   Bastian Buman, RSWS, University of Zurich
%
%   EDITOR:
%  
%
%   DATE:
%   V1, 19-Sep-2019
%   V2, 25-Sep-2019

%% Define Hierarchy Levels:
rawDataID           = 81;
radianceDataID      = 129;
reflectanceDataID   = 130;
connectionID        = 2;
switchedChannels    = true;
% tic;
FLOXBOX_Level_1(rawDataID, connectionID, switchedChannels);
FLOXBOX_Level_2(radianceDataID, connectionID, switchedChannels);
% toc;


%% Plot Data
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.gui.*;
import ch.specchio.types.*;

% connect to SPECCHIO
user_data.cf                                                = SPECCHIOClientFactory.getInstance();
user_data.db_descriptor_list                                = user_data.cf.getAllServerDescriptors();
user_data.specchio_client                                   = user_data.cf.createClient(user_data.db_descriptor_list.get(connectionID));
hierarchy_id                                                = reflectanceDataID;
node                                                        = hierarchy_node(hierarchy_id, "", "");
all_ids                                                     = user_data.specchio_client.getSpectrumIdsForNode(node);
[ids_QEpro, space_QEpro, spectra_QEpro, filenames_QEpro]    = restrictToSensor(user_data, 'FloX', all_ids);
[ids_FLAME, space_FLAME, spectra_FLAME, filenames_FLAME]    = restrictToSensor(user_data, 'ROX', all_ids);
wvl_QEpro                                                   = space_QEpro.getAverageWavelengths();
wvl_FLAME                                                   = space_FLAME.getAverageWavelengths();
time_QEpro                                                  = user_data.specchio_client.getMetaparameterValues(ids_QEpro, 'Acquisition Time');



for i=1:size(time_QEpro)
   tmp_dateTime_str = time_QEpro.get(i-1).toString().toCharArray';
   measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
   t_QEpro(i, 1) = measurement_datetime;
end
figure(1) 
clf
subplot(2,2,1)
plot(wvl_FLAME, spectra_FLAME)
axis([640 850 0 1])
title('Broadrange')

subplot(2,2,2)
plot(wvl_QEpro, spectra_QEpro)
title('SIF')

subplot(2,2,3)
plot(t_QEpro, spectra_QEpro(:,417:670))
title('SIF Timeseries @ 720 nm - 760 nm')

subplot(2,2,4)
plot(t_QEpro, spectra_QEpro(:,118:236))
title('SIF Timeseries @ 670 nm - 690 nm')

VIs = compute_VIs(wvl_FLAME, spectra_FLAME');
insertVIs(user_data, ids_FLAME, VIs)

VIsArray = table2array(VIs);
figure(2) 
clf
for i=1:10
    subplot(5,2,i)
    plot(VIsArray(:,i))
    title(VIs.Properties.VariableNames(i))
end


