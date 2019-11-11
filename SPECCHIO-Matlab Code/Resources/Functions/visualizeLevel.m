function visualizeLevel(user_data, selectedIds, level, isSIF)
%% Function visualize a certain level of data
%   INPUT:
%   user_data           : variable containing connection, client, etc.
%   selectedIds         : spectrum ids to process
% 
%   OUTPUT:
%   Plot to validate FLUO and FULL Levels
%              
%
%   AUTHORS:
%   Bastian Buman, RSWS, University of Zurich
%
%   DATE:
%   24-Oct-2019 V1.0

%% Get Data
if(not(isSIF))
    [ids_QEpro, space_QEpro, spectra_QEpro, filenames_QEpro]    = restrictToSensor(user_data, 'FloX', selectedIds);
    [ids_FLAME, space_FLAME, spectra_FLAME, filenames_FLAME]    = restrictToSensor(user_data, 'ROX', selectedIds);
    wvl_QEpro                                                   = space_QEpro.getAverageWavelengths();
    wvl_FLAME                                                   = space_FLAME.getAverageWavelengths();
    time_QEpro                                                  = user_data.specchio_client.getMetaparameterValues(ids_QEpro, 'Acquisition Time (UTC)');
    time_FLAME                                                  = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'Acquisition Time (UTC)');
else
    [ids_QEpro, space_QEpro, spectra_QEpro, filenames_QEpro]    = restrictToSensor(user_data, 'FloX', selectedIds);
    wvl_QEpro                                                   = space_QEpro.getAverageWavelengths();
    time_QEpro                                                  = user_data.specchio_client.getMetaparameterValues(ids_QEpro, 'Acquisition Time (UTC)');
end


t_QEpro = NaT(size(time_QEpro),1);
for i=1:size(time_QEpro)
    try
        tmp_dateTime_str = time_QEpro.get(i-1).toString().toCharArray';
    catch 
        tmp_dateTime_str = '2000-01-01T01:01:01.000Z';
    end
    measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
    t_QEpro(i, 1) = measurement_datetime;
end
if(not(isSIF))
    t_FLAME = NaT(size(time_FLAME), 1);
    for i=1:size(time_FLAME)
        try
            tmp_dateTime_str = time_FLAME.get(i-1).toString().toCharArray';
        catch
            tmp_dateTime_str = '2000-01-01T01:01:01.000Z';
        end
        measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
        t_FLAME(i, 1) = measurement_datetime;
    end
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

title([datestr(t_QEpro(5), "YYYY-mm-dd") ' FLUO'])
xlabel('Wavelength [nm]')
if(level == 0)
    ylabel('Count [DN]')
elseif(level == 1)
    ylabel('Radiance [mW m^{-2} sr^{-1} nm^{-1}]')
    axis([650 800 0.0 max(max(spectra_QEpro(:,:)))])
elseif(level == 2)
    ylabel('Reflectance')
    axis([400 800 0.0 2.0])
else
    disp(num2str(level));
end
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
if(not(isSIF))
    linecol = parula(size(spectra_FLAME,1));
    colormap(linecol)
    subplot(2,1,2)
    for i=1:size(spectra_FLAME,1)
        plot(wvl_FLAME, spectra_FLAME(i,:), 'Color', linecol(i,:)); % 'Color',jet(193)
        hold 'on'
    end
    
    title([datestr(t_FLAME(1), "YYYY-mm-dd") ' FULL'])
    xlabel('Wavelength [nm]')
    if(level == 0)
        ylabel('Count [DN]')
    elseif(level == 1)
        ylabel('Radiance [mW m^{-2} sr^{-1} nm^{-1}]')
        axis([400 800 0.0 max(max(spectra_FLAME(:,:)))])
    elseif(level == 2)
        ylabel('Reflectance')
        axis([400 800 0.0 2])
    else
        disp(num2str(level));
    end
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
end


