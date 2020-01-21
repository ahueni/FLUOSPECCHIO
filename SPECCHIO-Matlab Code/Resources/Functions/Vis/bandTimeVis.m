function bandTimeVis(this, campaignId, band)
% Function Visualize an x_eav_attribute gathered from the DB
%   This is a wrapper around the sensor restriction, the attribute
%   gathering and the plot functionality.
%   INPUT:
%   user_data  : variable containing connection, client, etc.
%   band       : the specific wavlength to visualize
%   xlab, ylab : plot labels
%  
%   OUTPUT:
%   Temporal plot of the signal in the selected band for all data in the DB
%              
%
%   AUTHORS:
%   Bastian Buman, RSWS, University of Zurich
%
%   DATE:
%   18-Nov-2019 V1.0
%   22-Nov-2019 V1.5
%   09-Dec-2019 V2.0
tic
ids = this.specchioClient.getIrradiance(num2str(campaignId));
spaces = this.specchioClient.getSpaces(ids, true, false, 'Acquisition Time');

[b_tmp, t_tmp, n_tmp] = getTimeBand(this, spaces(1), band);
t_1 = t_tmp;
b_1 = b_tmp;
n_1 = n_tmp;

[b_tmp, t_tmp, n_tmp] = getTimeBand(this, spaces(2), band);
t_2 = t_tmp;
b_2 = b_tmp;
n_2 = n_tmp;

figure('Name', 'Checkplots')
clf
subplot(2,1,1)
plot(t_1, b_1, '.')
title(n_1)
xlabel('Time')
ylabel('Signal')
subplot(2,1,2)
plot(t_2, b_2, '.')
title(n_2)
xlabel('Time')
ylabel('Signal')

toc
end

%% 
function  [spec, t, instrName] = getTimeBand(this, space, band)

ids = space.getSpectrumIds();
space = this.specchioClient.loadSpace(space, band);
spectra = space.getVectorsAsArray();
instrName = convertCharsToStrings(space.getInstrument.getInstrumentName.get_value);
time = this.specchioClient.getMetaparameterValues(ids, 'Acquisition Time (UTC)');

% PARSE TIME
t_tmp = NaT(size(time),1);
for i=1:size(time)
    try
        tmp_dateTime_str = time.get(i-1).toString().toCharArray';
    catch
        tmp_dateTime_str = '2000-01-01T01:01:01.000Z';
    end
    measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
    t_tmp(i, 1) = measurement_datetime;
end

% FILTER TIME
t = t_tmp(t_tmp > datetime('2000-01-01T01:01:01.000Z', 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'),1);
% FILTER SPECTRA 
spec = spectra(t_tmp > datetime('2000-01-01T01:01:01.000Z', 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'),:);
end

%% CHUNK
% signal = zeros(size(ids)/2,2);
% for i=1:length(spaces)
%     space = user_data.specchio_client.loadSpace(spaces(i), band);
%     signal(:,i) = space.getVectorsAsArray();
%     instrName(:,i) = convertCharsToStrings(space.getInstrument.getInstrumentName.get_value);
% end
% 
% instrId   = zeros(size(spaces));
% count = 1;
% for i=1:length(spaces)
%     if (find(instrId == spaces(i).getInstrumentId))
%         disp('already available');
%     else
%         instrId(i)   = spaces(i).getInstrumentId;
%         index(count) = i;
%         count = count +1;
%     end
% end


% GETTIMEBAND():
% wvl = space.getAverageWavelengths;
% b = spec(:,round(wvl) == band);
% b = mean(b, 2);