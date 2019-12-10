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
%   20-Nov-2019 V1.1

ids    = queryAttribute(user_data, 'Processing Level', level);
spaces = user_data.specchio_client.getSpaces(ids, 'Acquisition Time');

for i=1:length(spaces)
    instrId(i) = spaces(i).getInstrumentId;
end
uniqueInstrId = unique(instrId(:));

if(length(uniqueInstrId) > 1)
    [t_FULL, band_FULL,...
    t_FLUO, band_FLUO]...
    = getInfoMultSensor(user_data, ids, band);
    
    figure('Name', 'Checkplots')
    clf
    plot(t_FLUO, band_FLUO,'.', t_FULL, band_FULL, '.'); 
    legend('FLUO','FULL')
    title(['Average of bands rounded to ' num2str(band) ' [nm]'])
    xlabel('Wavelength')
    ylabel('W')
end

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
function  [t_FULL, band_FULL,...
    t_FLUO, band_FLUO] = getInfoMultSensor(user_data, ids, band)

[ids_FLUO, space_FLUO, spectra_FLUO, filenames_FLUO] = restrictToSensor(user_data, 'FloX', ids);
[ids_FULL, space_FULL, spectra_FULL, filenames_FULL] = restrictToSensor(user_data, 'ROX', ids);
wvl_FLUO                                             = space_FLUO.getAverageWavelengths;
wvl_FULL                                             = space_FULL.getAverageWavelengths;
time_FLUO                                            = user_data.specchio_client.getMetaparameterValues(ids_FLUO, 'Acquisition Time (UTC)');
time_FULL                                            = user_data.specchio_client.getMetaparameterValues(ids_FULL, 'Acquisition Time (UTC)');



t_FLUO_tmp = NaT(size(time_FLUO),1);
for i=1:size(time_FLUO)
    try
        tmp_dateTime_str = time_FLUO.get(i-1).toString().toCharArray';
    catch 
        tmp_dateTime_str = '2000-01-01T01:01:01.000Z';
    end
    measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
    t_FLUO_tmp(i, 1) = measurement_datetime;
end
t_FLUO = t_FLUO_tmp(t_FLUO_tmp > datetime('2000-01-01T01:01:01.000Z', 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'),1);

spec_FLUO = spectra_FLUO(t_FLUO_tmp > datetime('2000-01-01T01:01:01.000Z', 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'),:);
band_FLUO = spec_FLUO(:,round(wvl_FLUO) == band);
band_FLUO = mean(band_FLUO, 2);

t_FULL = NaT(size(time_FULL), 1);
for i=1:size(time_FULL)
    try
        tmp_dateTime_str = time_FULL.get(i-1).toString().toCharArray';
    catch
        tmp_dateTime_str = '2000-01-01T01:01:01.000Z';
    end
    measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
    t_FULL(i, 1) = measurement_datetime;
end
t_FULL = t_FULL(t_FULL > datetime('2000-01-01T01:01:01.000Z', 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'),1);

spec_FULL = spectra_FULL(t_FULL > datetime('2000-01-01T01:01:01.000Z', 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'),:);
band_FULL = spec_FULL(:,round(wvl_FULL) == band);
band_FULL = mean(band_FULL, 2);
end