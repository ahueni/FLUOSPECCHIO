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

%% Processing
% Define Hierarchy Levels:
rawDataID           = 175;
radianceDataID      = 177;
reflectanceDataID   = 178;

% Define Connection info:
connectionID        = 2;

switchedChannels = true;

% Import specchio functionality:
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.gui.*;
import ch.specchio.types.*;
import ch.specchio.*;

% connect to SPECCHIO
user_data.cf = SPECCHIOClientFactory.getInstance();
user_data.db_descriptor_list = user_data.cf.getAllServerDescriptors();
user_data.specchio_client = user_data.cf.createClient(user_data.db_descriptor_list.get(connectionID));

% get spectra ids for this hierarchy
node = hierarchy_node(rawDataID, "", "");
DN_ids = user_data.specchio_client.getSpectrumIdsForNode(node);

% group spectra by spectral number: but as the spectral number can be
% repeated within a day, it is better to group by UTC or Acquisition time
% group_collection = user_data.specchio_client.sortByAttributes(user_data.space.getSpectrumIds, 'Spectrum Number');
group_collection = user_data.specchio_client.sortByAttributes(DN_ids, 'Acquisition Time (UTC)');
groups = group_collection.getSpectrum_id_lists;


% Split DNs up into a reasonable amount of threads figure out a good way to
% do it
threads = 4;
remainder = mod(size(groups),threads);
split = floor(size(groups)/threads);
Gr_a = java.util.ArrayList(groups.subList (0, split-1));
Gr_b = java.util.ArrayList(groups.subList (split, 2*split-1));
Gr_c = java.util.ArrayList(groups.subList (2*split, 3*split-1));
Gr_d = java.util.ArrayList(groups.subList (3*split, 4*split+remainder));    
Gr_all = java.util.ArrayList();
Gr_all.add(0, Gr_a);
Gr_all.add(1, Gr_b);
Gr_all.add(2, Gr_c);
Gr_all.add(3, Gr_d);

Gr_selected_DNs = java.util.ArrayList();


for i=0:size(Gr_all)-1
    selection = java.util.ArrayList();
    for k=0:size(Gr_all.get(i))-1
        for l=0:size(Gr_all.get(i).get(k).getSpectrumIds)-1
            selection.add(k,int32(Gr_all.get(i).get(k).getSpectrumIds.get(l)));
        end
    end
    disp(num2str(i));
    Gr_selected_DNs.add(i, selection);
end

% Process Level 0 (DN) to Level 1 (Radiance)
parfor i=0:size(Gr_selected_DNs)-1
    FLOXBOX_Level_1(connectionID, switchedChannels, Gr_selected_DNs.get(i));
end


% Process Level 1 (Radiance) to Level 2 (Reflectance); note that for QEpro
% it currently stores SIF not the Reflectance.
FLOXBOX_Level_2(radianceDataID, connectionID, switchedChannels);


%% Visualization
% connect to SPECCHIO
user_data.cf                                                = SPECCHIOClientFactory.getInstance();
user_data.db_descriptor_list                                = user_data.cf.getAllServerDescriptors();
user_data.specchio_client                                   = user_data.cf.createClient(user_data.db_descriptor_list.get(connectionID));
node                                                        = hierarchy_node(reflectanceDataID, "", "");
all_ids                                                     = user_data.specchio_client.getSpectrumIdsForNode(node);
[ids_QEpro, space_QEpro, spectra_QEpro, filenames_QEpro]    = restrictToSensor(user_data, 'FloX', all_ids);
[ids_FLAME, space_FLAME, spectra_FLAME, filenames_FLAME]    = restrictToSensor(user_data, 'ROX', all_ids);
wvl_QEpro                                                   = space_QEpro.getAverageWavelengths();
wvl_FLAME                                                   = space_FLAME.getAverageWavelengths();
VIs                                                         = compute_VIs(wvl_FLAME, spectra_FLAME');
insertVIs(user_data, ids_FLAME, VIs);
time_QEpro                                                  = user_data.specchio_client.getMetaparameterValues(ids_QEpro, 'Acquisition Time (UTC)');
time_FLAME                                                  = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'Acquisition Time (UTC)');
NDVI_FLAME                                                  = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'NDVI');
EVI_FLAME                                                   = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'EVI');
Garb_FLAME                                                  = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'Garbage Flag');


for i=1:size(time_QEpro)
   tmp_dateTime_str = time_QEpro.get(i-1).toString().toCharArray';
   measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
   t_QEpro(i, 1) = measurement_datetime;
end

for i=1:size(time_FLAME)
   tmp_dateTime_str = time_FLAME.get(i-1).toString().toCharArray';
   measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
   t_FLAME(i, 1) = measurement_datetime;
end

ndvi_fl = nan(size(NDVI_FLAME),1);
for i=0:size(ndvi_fl)-1
    ndvi_fl(i+1,1) = NDVI_FLAME.get(i);
end

evi_fl = nan(size(EVI_FLAME),1);
for i=0:size(evi_fl)-1
    evi_fl(i+1,1) = EVI_FLAME.get(i);
end


figure(1) 
clf
subplot(2,3,1)
plot(wvl_FLAME, spectra_FLAME)
axis([640 850 0 1])
title('Broadrange')

subplot(2,3,2)
plot(wvl_QEpro, spectra_QEpro)
title('SIF')

% subplot(2,3,3)
% plot(t_QEpro, spectra_QEpro(:,417:670))
% title('SIF Timeseries @ 720 nm - 760 nm')
% subplot(2,3,4)
% plot(t_QEpro, spectra_QEpro(:,118:236))
% title('SIF Timeseries @ 670 nm - 690 nm')

% Plots , SIF @ 687 and 761

subplot(2,3,1)
plot(t_QEpro, mean(spectra_QEpro(:, find(wvl_QEpro >= 687 & wvl_QEpro < 688)),2)) % find wavelength, then take mean of the measurements within the given frame mean(A,2) is row mean
title('SIF Timeseries @ 687 nm')

subplot(2,3,2)
plot(t_QEpro, mean(spectra_QEpro(:, find(wvl_QEpro >= 760 & wvl_QEpro < 761)),2))
title('SIF Timeseries @ 760 nm')

% Plots , SIF @ max<F687> and max<761>

subplot(2,3,3)
plot(wvl_QEpro, nanmax(nanmean(spectra_QEpro(:, find(wvl_QEpro >= 650 & wvl_QEpro < 700)),2),[],2)) 
title('SIF Timeseries @ 687 nm')

subplot(2,3,4)
plot(wvl_QEpro,  nanmax(nanmean(spectra_QEpro(:, find(wvl_QEpro >= 700 & wvl_QEpro < 800)),2)),2)
title('SIF Timeseries @ 760 nm')


subplot(2,3,5)
plot(t_QEpro, ndvi_fl)
title('NDVI - BROADRANGE')

subplot(2,3,6)
plot(t_QEpro, evi_fl)
title('EVI - BROADRANGE')

find(wvl_FLAME<=760)
find(wvl_FLAME>=761)
% 
% subplot(2,3,6)
% plot(t_QEpro, garb_fl)
% title('Garbage Flagged Points')
% 




% VIsArray = table2array(VIs);
% figure(2) 
% clf
% for i=1:10
%     subplot(5,2,i)
%     plot(VIsArray(:,i))
%     title(VIs.Properties.VariableNames(i))
% end


