%% Visualization
addpath('Helper');
% Define Hierarchy Levels:
rawDataID           = 211;
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
linecol = parula(size(spectra_QEpro,1));
colormap(linecol)
% set(subplot(2,2,1), 'Position', [0.1 0.6 (1/3) 0.30])
subplot(2,2,1)
for i=1:size(spectra_QEpro,1)
    plot(wvl_QEpro, spectra_QEpro(i,:), 'Color', linecol(i,:)); % 'Color',jet(193)
    hold 'on'
end
axis([650 800 0.01 0.2])
plot(pO2B, 'FaceColor', 'none');
plot(pO2A, 'FaceColor', 'none');
text(686, (maxValO2B+(0.1*maxValO2B)),'O2B')
text(760, (maxValO2A+(0.1*maxValO2A)),'O2A')
title(datestr(t_QEpro(1), "YYYY-mm-dd"))
xlabel('Wavelength [nm]')
ylabel('F [mW m^{-2} sr^{-1} nm^{-1}]')
% Colorbar
cbar = colorbar;
% Get the current location of the tick marks
ticks = get(cbar, 'ticks');
% Now create a label for each tick mark (you can modify these however you want)
labels = arrayfun(@(x) timeLab(x, spectra_QEpro, t_QEpro), ticks, 'uniformoutput', false);
% Assign the labels to the colorbar
set(cbar,'Ticks', ticks, 'TickLabels', labels)
title(cbar,'Time')
hold 'off'

% Calculate total F (sum of all values, not exactly the integral but fair
% enough for the moment)
Ftot = nan(size(spectra_QEpro,1),1);
for i=1:size(spectra_QEpro,1)
   Ftot(i,1) = nansum(spectra_QEpro(i,:));
end

subplot(2,2,2)
plot(t_QEpro, Ftot)
xlabel('Time [min]')
ylabel('F [mW m^{-2} sr^{-1} nm^{-1}]')

% set(subplot(2,2,2), 'Position', [0.5 0.6 (1/3) 0.30]);
% for i=1:size(spectra_QEpro,1)
%     plot(wvl_QEpro, spectra_QEpro(i,:), 'Color', linecol(i,:)); % 'Color',jet(193)
%     H(i)= area(wvl_QEpro,spectra_QEpro(i,:));
%     set(H(i),'FaceColor',linecol(i,:));
%     hold 'on'
% end
title('F-tot')
% alpha(.5);
hold 'off'
% H=area(wvl_QEpro,spectra_QEpro(190,:));
% set(H(1),'FaceColor',linecol(190,:));
% alpha(.5);
% title('F-tot')


% Find max O2B-peak and O2A-peak of each spectrum:

% Define O2B-peak region:
spectra_QEpro_t         = spectra_QEpro';
O2B_region              = wvl_QEpro >= 670 & wvl_QEpro < 690;
O2B_peak                = spectra_QEpro_t == max(spectra_QEpro_t(O2B_region,:),[], 1, 'omitnan');
% O2B_max                 = max(spectra_QEpro_t(O2B_region,:),[], 1, 'omitnan')';

SpectrumO2B             = nan(size(spectra_QEpro_t));
SpectrumO2B(O2B_peak)   = spectra_QEpro_t(O2B_peak)';

wvlChangeO2B            = nan(size(spectra_QEpro_t));
[row,col,v]             = find(O2B_peak);
wvlChangeO2B(O2B_peak)  = wvl_QEpro(row);

subplot(2,2,3)
for i=1:size(SpectrumO2B,2)
    scatter(t_QEpro(i), wvlChangeO2B(wvlChangeO2B(:,i)>0,i),'k', 'filled')
    hold 'on'
end

% set(subplot(2,2,3), 'Position', [0.1 0.1 (1/3) 0.30]);
% for i=1:size(SpectrumO2B,2)
%     scatter(wvl_QEpro, SpectrumO2B(:,i), 50, linecol(i,:), 'filled')
%     hold 'on'
% end
% cbar = colorbar;
% % Get the current location of the tick marks
% ticks = get(cbar, 'ticks');
% % Now create a label for each tick mark (you can modify these however you want)
% labels = arrayfun(@(x) timeLab(x, spectra_QEpro, t_QEpro), ticks, 'uniformoutput', false);
% % Assign the labels to the colorbar
% set(cbar,'Ticks', ticks, 'TickLabels', labels)
title('Position of maxF<O2B>')
xlabel('Time [min]')
ylabel('Wavelength [nm]')
hold 'off'


% Define O2A-peak region:
O2A_region              = wvl_QEpro >= 735 & wvl_QEpro < 760;
spectra_QEpro_t(564,3)  = 0; % drop this value because it exists twice and will mess up the max later on
O2A_peak                = spectra_QEpro_t == max(spectra_QEpro_t(O2A_region,:),[], 1, 'omitnan');


SpectrumO2A             = nan(size(spectra_QEpro_t));
SpectrumO2A(O2A_peak)   = spectra_QEpro_t(O2A_peak)';

wvlChangeO2A            = nan(size(spectra_QEpro_t));
[row,col,v]             = find(O2A_peak);
wvlChangeO2A(O2A_peak)  = wvl_QEpro(row);

subplot(2,2,4)
for i=1:size(SpectrumO2A,2)
    scatter(t_QEpro(i), wvlChangeO2A(wvlChangeO2A(:,i)>0,i),'k', 'filled')
    hold 'on'
end
title('Position of maxF<O2A>')
xlabel('Time [min]')
ylabel('Wavelength [nm]')
hold 'off'
% 
% 
% set(subplot(2,2,4), 'Position', [0.5 0.1 (1/3) 0.3]);
% linecol = parula(size(spectra_QEpro,1));
% colormap(linecol)
% for i=1:size(SpectrumO2A,2)
%     scatter(wvl_QEpro, SpectrumO2A(:,i), 50, linecol(i,:), 'filled')
%     hold 'on'
% end
% title('maxF<O2A>')
% hold 'off'

cbar = colorbar;
% Get the current location of the tick marks
ticks = get(cbar, 'ticks');
% Now create a label for each tick mark (you can modify these however you want)
labels = arrayfun(@(x) timeLab(x, spectra_QEpro, t_QEpro), ticks, 'uniformoutput', false);
% Assign the labels to the colorbar
set(cbar,'Ticks', ticks, 'TickLabels', labels)
set(cbar, 'Position', [0.87 0.1 (1/20) 0.8])

