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
plot(wvl_QEpro, spectra_QEpro); % 'Color',jet(193)
hold 'on'
plot(pO2B, 'FaceColor', 'none');
plot(pO2A, 'FaceColor', 'none');
text(686, (maxValO2B+(0.1*maxValO2B)),'O2B')
text(760, (maxValO2A+(0.1*maxValO2A)),'O2A')
title('A - Time Series and Oxygen Absorption Bands')
hold 'off'


% Find max O2B-peak and O2A-peak of each spectrum:

% Define O2B-peak region:
spectra_QEpro_t         = spectra_QEpro';
O2B_region              = wvl_QEpro >= 670 & wvl_QEpro < 690;
O2B_peak                = spectra_QEpro_t == max(spectra_QEpro_t(O2B_region,:),[], 1, 'omitnan');

SpectrumO2B             = nan(size(spectra_QEpro_t));
SpectrumO2B(O2B_peak)   = spectra_QEpro_t(O2B_peak)';

subplot(2,2,2)
for i=1:size(SpectrumO2B,2)
    scatter(wvl_QEpro, SpectrumO2B(:,i), 100)
    hold 'on'
end
title('maxF<O2B>')
hold 'off'


% Define O2A-peak region:
O2A_region              = wvl_QEpro >= 735 & wvl_QEpro < 760;
O2A_peak                = spectra_QEpro_t == max(spectra_QEpro_t(O2A_region,:),[], 1, 'omitnan');
SpectrumO2A             = nan(size(spectra_QEpro_t));
SpectrumO2A(O2A_peak)   = spectra_QEpro_t(O2A_peak)';

subplot(2,2,3)
for i=1:size(SpectrumO2A,2)
    scatter(wvl_QEpro, SpectrumO2A(:,i), 100)
    hold 'on'
end
title('maxF<O2A>')
hold 'off'

% plot(wvl_QEpro, spectra_QEpro_t(:,50)); % 'Color',jet(193)
% hold 'on'
% fill_color = [.929 .694 .125];
% fh = fill(wvl_QEpro(points), spectra_QEpro_t(points,50),fill_color);
% hold 'on'
% fill(wvl_QEpro(end), 0, fill_color)
% 
% trapz(wvl_QEpro, spectra_QEpro_t(:,1), 'omitnan')



