%% Visualization
% Define Hierarchy Levels:
rawDataID           = 175;
radianceDataID      = 177;
reflectanceDataID   = 178;

% Define Connection info:
connectionID        = 2;

% Import specchio functionality:
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.gui.*;
import ch.specchio.types.*;
import ch.specchio.*;

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
% VIs                                                         = compute_VIs(wvl_FLAME, spectra_FLAME');
% insertVIs(user_data, ids_FLAME, VIs);
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

% The polyshape function creates a polygon defined by 2-D vertices, 
% and returns a polyshape object with properties describing its vertices, 
% solid regions, and holes. For example, pgon = polyshape([0 0 1 1],[1 0 0 1]) 
% creates the solid square defined by the four points (0,1), (0,0), (1,0), and (1,1).
% >> pgon = polyshape([0 0 1 1],[1 0 0 1])
% >> plot(pgon)
% Find the entries in the spectra that correspond to the O2 bands (A and
% B):
O2B         = find(wvl_QEpro >= 687 & wvl_QEpro < 688);
maxValO2B   = nanmax(nanmax(spectra_QEpro(:, O2B)));
pO2B        = polyshape([686.5 687.5 687.5 686.5], [0 0 maxValO2B maxValO2B]);

O2A         = find(wvl_QEpro >= 760 & wvl_QEpro < 761);
maxValO2A   = nanmax(nanmax(spectra_QEpro(:, O2A)));
pO2A        = polyshape([759.5 760.5 760.5 759.5], [0 0 maxValO2A maxValO2A]);

figure('Name', 'SIF') 
clf
subplot(2,2,1)
plot(wvl_QEpro, spectra_QEpro);
hold 'on'
plot(pO2B, 'FaceColor', 'none');
plot(pO2A, 'FaceColor', 'none');
text(686, (maxValO2B+(0.1*maxValO2B)),'O2B')
text(760, (maxValO2A+(0.1*maxValO2A)),'O2A')
title('A - Time Series and Oxygen Absorption Bands')
hold 'off'


% Find max O2B-peak and O2A-peak of each spectrum:
% Define O2B-peak region:

spectra_QEpro_t     = spectra_QEpro';
testSpectrum        = spectra_QEpro_t(:, 1);
O2B_region          = find(testSpectrum(find(wvl_QEpro >= 650 & wvl_QEpro < 700)));
O2B_peaks           = find(testSpectrum(:) == max(testSpectrum(O2B_region)));
subplot(2,2,2)





% subplot(2,3,2)
% plot(wvl_FLAME, spectra_FLAME)
% axis([640 850 0 1])
% title('Broadrange')

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
