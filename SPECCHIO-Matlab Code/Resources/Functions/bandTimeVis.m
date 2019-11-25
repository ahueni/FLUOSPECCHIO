function bandTimeVis(user_data, level, band)
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
tic
ids    = queryAttribute(user_data, 'Processing Level', level);
spaces = user_data.specchio_client.getSpaces(ids, 'Acquisition Time');

instrId   = zeros(size(spaces));
for i=1:length(spaces)
    if (find(instrId == spaces(i).getInstrumentId))
        disp('already available');
    else
        instrId(i)   = spaces(i).getInstrumentId;
        index(i) = i;
    end
end

[t_tmp, b_tmp, n_tmp] = getTimeBand(user_data, spaces(index(1)), band);
t_1 = t_tmp;
b_1 = b_tmp;
n_1 = n_tmp;

[t_tmp, b_tmp, n_tmp] = getTimeBand(user_data, spaces(index(2)), band);
t_2 = t_tmp;
b_2 = b_tmp;
n_2 = n_tmp;

figure('Name', 'Checkplots')
clf
subplot(2,1,1)
plot(t_1, b_1, '.')
title(n_1)
xlabel('Wavelength')
ylabel('Signal')
subplot(2,1,2)
plot(t_2, b_2, '.')
title(n_2)
xlabel('Wavelength')
ylabel('Signal')

toc
end


%% Query
function ids = queryAttribute(user_data, attribute, level)
import ch.specchio.queries.*;
query = Query('spectrum');
query.setQueryType(Query.SELECT_QUERY);

query.addColumn('spectrum_id')

cond = EAVQueryConditionObject('eav', 'spectrum_x_eav', attribute, 'double_val');
cond.setValue(num2str(level));
cond.setOperator('>=');
query.add_condition(cond);

cond = EAVQueryConditionObject('eav', 'spectrum_x_eav', attribute, 'double_val');
cond.setValue(num2str(level));
cond.setOperator('<=');
query.add_condition(cond);

ids = user_data.specchio_client.getSpectrumIdsMatchingQuery(query);
end
%% 
function  [t, b, instrName] = getTimeBand(user_data, space, band)

ids = space.getSpectrumIds();
wvl = space.getAverageWavelengths;
space = user_data.specchio_client.loadSpace(space);
spectra = space.getVectorsAsArray();
instrName = convertCharsToStrings(space.getInstrument.getInstrumentName.get_value);
time = user_data.specchio_client.getMetaparameterValues(ids, 'Acquisition Time (UTC)');
filename =  user_data.specchio_client.getMetaparameterValues(ids, 'File Name');
f =  cell(size(filename),1);

for i=1:size(filename)
   f(i,1) = cellstr(filename.get(i-1)); 
end

spectra = spectra(contains(f, 'WR'),:);
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
t_tmp = t_tmp(contains(f, 'WR'));
t = t_tmp(t_tmp > datetime('2000-01-01T01:01:01.000Z', 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'),1);

spec = spectra(t_tmp > datetime('2000-01-01T01:01:01.000Z', 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'),:);
b = spec(:,round(wvl) == band);
b = mean(b, 2);
end