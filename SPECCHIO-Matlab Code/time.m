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



%% connect to SPECCHIO
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.gui.*;
import ch.specchio.types.*;
user_data.cf                                                = SPECCHIOClientFactory.getInstance();
user_data.db_descriptor_list                                = user_data.cf.getAllServerDescriptors();
user_data.specchio_client                                   = user_data.cf.createClient(user_data.db_descriptor_list.get(connectionID));

%% Filter for requested data user_data, processing_level, startDateTime, endDateTime
ids_a = getTimeWindowData(user_data, '2.0', '20180626093100', '20180626093300');
ids_b = getTimeWindowData(user_data, '2.0', '20180719093500', '20180719093700');
ids_c = getTimeWindowData(user_data, '2.0', '20180911093400', '20180911093600');

%% Prepare data for visualization - 2018-06-26
[ids_QEpro, space_QEpro, spectra_QEpro, filenames_QEpro]    = restrictToSensor(user_data, 'FloX', ids_a);
[ids_FLAME, space_FLAME, spectra_FLAME, filenames_FLAME]    = restrictToSensor(user_data, 'ROX', ids_a);
wvl_QEpro                                                   = space_QEpro.getAverageWavelengths();
wvl_FLAME                                                   = space_FLAME.getAverageWavelengths();
% VIs                                                         = compute_VIs(wvl_FLAME, spectra_FLAME');
% insertVIs(user_data, ids_FLAME, VIs);
time_QEpro                                                  = user_data.specchio_client.getMetaparameterValues(ids_QEpro, 'Acquisition Time (UTC)');
time_FLAME                                                  = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'Acquisition Time (UTC)');
NDVI_FLAME                                                  = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'NDVI');
EVI_FLAME                                                   = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'EVI');



for i=1:size(time_FLAME)
   tmp_dateTime_str = time_FLAME.get(i-1).toString().toCharArray';
   measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
   t_FLAME(i, 1) = measurement_datetime;
end

for i=1:size(time_QEpro)
   tmp_dateTime_str = time_QEpro.get(i-1).toString().toCharArray';
   measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
   t_QEpro(i, 1) = measurement_datetime;
end

ndvi_fl = nan(size(NDVI_FLAME),1);
for i=0:size(ndvi_fl)-1
    ndvi_fl(i+1,1) = NDVI_FLAME.get(i);
end

evi_fl = nan(size(EVI_FLAME),1);
for i=0:size(evi_fl)-1
    evi_fl(i+1,1) = EVI_FLAME.get(i);
end


figure('Name', '2018-06-26') 
clf
subplot(2,1,1)
plot(wvl_FLAME, spectra_FLAME)
axis([640 850 0 1])
title('Broadrange')

subplot(2,1,2)
plot(wvl_QEpro, spectra_QEpro)
title('SIF')

subplot(2,2,3)
plot(t_FLAME, ndvi_fl)
title('NDVI - BROADRANGE')

subplot(2,2,4)
plot(t_FLAME, evi_fl)
title('EVI - BROADRANGE')

%% Prepare data for visualization - 2018-07-19
[ids_QEpro, space_QEpro, spectra_QEpro, filenames_QEpro]    = restrictToSensor(user_data, 'FloX', ids_b);
[ids_FLAME, space_FLAME, spectra_FLAME, filenames_FLAME]    = restrictToSensor(user_data, 'ROX', ids_b);
wvl_QEpro                                                   = space_QEpro.getAverageWavelengths();
wvl_FLAME                                                   = space_FLAME.getAverageWavelengths();
VIs                                                         = compute_VIs(wvl_FLAME, spectra_FLAME');
insertVIs(user_data, ids_FLAME, VIs);
time_QEpro                                                  = user_data.specchio_client.getMetaparameterValues(ids_QEpro, 'Acquisition Time (UTC)');
time_FLAME                                                  = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'Acquisition Time (UTC)');
NDVI_FLAME                                                  = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'NDVI');
EVI_FLAME                                                   = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'EVI');



for i=1:size(time_FLAME)
   tmp_dateTime_str = time_FLAME.get(i-1).toString().toCharArray';
   measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
   t_FLAME(i, 1) = measurement_datetime;
end

for i=1:size(time_QEpro)
   tmp_dateTime_str = time_QEpro.get(i-1).toString().toCharArray';
   measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
   t_QEpro(i, 1) = measurement_datetime;
end

ndvi_fl = nan(size(NDVI_FLAME),1);
for i=0:size(ndvi_fl)-1
    ndvi_fl(i+1,1) = NDVI_FLAME.get(i);
end

evi_fl = nan(size(EVI_FLAME),1);
for i=0:size(evi_fl)-1
    evi_fl(i+1,1) = EVI_FLAME.get(i);
end


figure('Name', '2018-07-19') 
clf
subplot(2,2,1)
plot(wvl_FLAME, spectra_FLAME)
axis([640 850 0 1])
title('Broadrange')

subplot(2,2,2)
plot(wvl_QEpro, spectra_QEpro)
title('SIF')

subplot(2,2,3)
plot(t_FLAME, ndvi_fl)
title('NDVI - BROADRANGE')

subplot(2,2,4)
plot(t_FLAME, evi_fl)
title('EVI - BROADRANGE')

%% Prepare data for visualization - 2018-09-11
[ids_QEpro, space_QEpro, spectra_QEpro, filenames_QEpro]    = restrictToSensor(user_data, 'FloX', ids_c);
[ids_FLAME, space_FLAME, spectra_FLAME, filenames_FLAME]    = restrictToSensor(user_data, 'ROX', ids_c);
wvl_QEpro                                                   = space_QEpro.getAverageWavelengths();
wvl_FLAME                                                   = space_FLAME.getAverageWavelengths();
VIs                                                         = compute_VIs(wvl_FLAME, spectra_FLAME');
insertVIs(user_data, ids_FLAME, VIs);
time_QEpro                                                  = user_data.specchio_client.getMetaparameterValues(ids_QEpro, 'Acquisition Time (UTC)');
time_FLAME                                                  = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'Acquisition Time (UTC)');
NDVI_FLAME                                                  = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'NDVI');
EVI_FLAME                                                   = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'EVI');



for i=1:size(time_FLAME)
   tmp_dateTime_str = time_FLAME.get(i-1).toString().toCharArray';
   measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
   t_FLAME(i, 1) = measurement_datetime;
end

for i=1:size(time_QEpro)
   tmp_dateTime_str = time_QEpro.get(i-1).toString().toCharArray';
   measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
   t_QEpro(i, 1) = measurement_datetime;
end

ndvi_fl = nan(size(NDVI_FLAME),1);
for i=0:size(ndvi_fl)-1
    ndvi_fl(i+1,1) = NDVI_FLAME.get(i);
end

evi_fl = nan(size(EVI_FLAME),1);
for i=0:size(evi_fl)-1
    evi_fl(i+1,1) = EVI_FLAME.get(i);
end


figure('Name', '2018-09-11') 
clf
subplot(2,2,1)
plot(wvl_FLAME, spectra_FLAME)
axis([640 850 0 1])
title('Broadrange')

subplot(2,2,2)
plot(wvl_QEpro, spectra_QEpro)
title('SIF')

subplot(2,2,3)
plot(t_FLAME, ndvi_fl)
title('NDVI - BROADRANGE')

subplot(2,2,4)
plot(t_FLAME, evi_fl)
title('EVI - BROADRANGE')