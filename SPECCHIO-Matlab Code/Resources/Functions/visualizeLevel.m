function visualizeLevel(user_data, selectedIds)

[ids_QEpro, space_QEpro, spectra_QEpro, filenames_QEpro]    = restrictToSensor(user_data, 'FloX', selectedIds);
[ids_FLAME, space_FLAME, spectra_FLAME, filenames_FLAME]    = restrictToSensor(user_data, 'ROX', selectedIds);
wvl_QEpro                                                   = space_QEpro.getAverageWavelengths();
wvl_FLAME                                                   = space_FLAME.getAverageWavelengths();
time_QEpro                                                  = user_data.specchio_client.getMetaparameterValues(ids_QEpro, 'Acquisition Time (UTC)');
time_FLAME                                                  = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'Acquisition Time (UTC)');


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

%% FLUO
figure('Name', 'Checkplots')
clf
linecol = parula(size(spectra_QEpro,1));
colormap(linecol)
subplot(2,1,1)
for i=1:size(spectra_QEpro,1)
    plot(wvl_QEpro, spectra_QEpro(i,:), 'Color', linecol(i,:)); % 'Color',jet(193)
    hold 'on'
end
axis([650 800 0.01 0.2])
title([datestr(t_QEpro(1), "YYYY-mm-dd") ' FLUO'])
xlabel('Wavelength [nm]')
ylabel('Radiance [mW m^{-2} sr^{-1} nm^{-1}]')
% Colorbar
cbar = colorbar;
% Get the current location of the tick marks
ticks = get(cbar, 'ticks');
% Now create a label for each tick mark (you can modify these however you want)
labels = arrayfun(@(x) createTimeLabels(x, spectra_QEpro, t_QEpro), ticks, 'uniformoutput', false);
% Assign the labels to the colorbar
set(cbar,'Ticks', ticks, 'TickLabels', labels)
title(cbar,'Time')
hold 'off'
%% FULL
linecol = parula(size(spectra_FLAME,1));
colormap(linecol)
subplot(2,1,2)
for i=1:size(spectra_FLAME,1)
    plot(wvl_FLAME, spectra_FLAME(i,:), 'Color', linecol(i,:)); % 'Color',jet(193)
    hold 'on'
end
axis([650 800 0.01 0.2])
title([datestr(t_FLAME(1), "YYYY-mm-dd") ' FULL'])
xlabel('Wavelength [nm]')
ylabel('Radiance [mW m^{-2} sr^{-1} nm^{-1}]')
% Colorbar
cbar = colorbar;
% Get the current location of the tick marks
ticks = get(cbar, 'ticks');
% Now create a label for each tick mark (you can modify these however you want)
labels = arrayfun(@(x) createTimeLabels(x, spectra_FLAME, t_FLAME), ticks, 'uniformoutput', false);
% Assign the labels to the colorbar
set(cbar,'Ticks', ticks, 'TickLabels', labels)
title(cbar,'Time')
hold 'off'


