function attributeTimeVis(user_data, attribute, min, max, xlab, ylab)
% Function Visualize an x_eav_attribute gathered from the DB
%   This is a wrapper around the sensor restriction, the attribute
%   gathering and the plot functionality.
%   INPUT:
%   user_data  : variable containing connection, client, etc.
%   attribute  : an eav type of string (already existing in the DB)
%   min, max   : specify the range for the attribute
%   xlab, ylab : plot labels
%  
%   OUTPUT:
%   Temporal plot of the attribute for all data in the DB
%              
%
%   AUTHORS:
%   Bastian Buman, RSWS, University of Zurich
%
%   DATE:
%   18-Nov-2019 V1.0
%   20-Nov-2019 V1.1

ids    = queryAttribute(user_data, attribute, min, max);
spaces = user_data.specchio_client.getSpaces(ids, 'Acquisition Time');

for i=1:length(spaces)
    instrId(i) = spaces(i).getInstrumentId;
end
uniqueInstrId = unique(instrId(:));

if(length(uniqueInstrId) > 1)
    [t_FULL, attr_FULL,...
    t_FLUO, attr_FLUO]...
    = getInfoMultSensor(user_data, ids, attribute);
    
    figure('Name', 'Checkplots')
    clf
    subplot(2,1,1)
    plot(t_FLUO, attr_FLUO, 'o');
    title(['FLUO ' attribute])
    xlabel(xlab)
    ylabel(ylab)
    
    subplot(2,1,2)
    plot(t_FULL, attr_FULL, 'o');
    title(['FULL ' attribute])
    xlabel(xlab)
    ylabel(ylab)
else
    [t, attr]...
    = getInfoSingleSensor(user_data, ids, attribute);
    plot(t, attr, 'o');
    title(attribute)
    xlabel(xlab)
    ylabel(ylab)
end

end


%% Query
function ids = queryAttribute(user_data, attribute, min, max)
import ch.specchio.queries.*;
if(min == max)
    
    query = Query('spectrum');
    query.setQueryType(Query.SELECT_QUERY);
    
    query.addColumn('spectrum_id')
    
    cond = EAVQueryConditionObject('eav', 'spectrum_x_eav', attribute, 'double_val');
    cond.setValue(num2str(min));
    cond.setOperator('>=');
    query.add_condition(cond);
    ids = user_data.specchio_client.getSpectrumIdsMatchingQuery(query);
else
    query = Query('spectrum');
    query.setQueryType(Query.SELECT_QUERY);
    
    query.addColumn('spectrum_id')
    
    cond = EAVQueryConditionObject('eav', 'spectrum_x_eav', attribute, 'double_val');
    cond.setValue(num2str(min));
    cond.setOperator('>=');
    query.add_condition(cond);
    
    cond = EAVQueryConditionObject('eav', 'spectrum_x_eav', attribute, 'double_val');
    cond.setValue(num2str(max));
    cond.setOperator('<=');
    query.add_condition(cond);
    
    ids = user_data.specchio_client.getSpectrumIdsMatchingQuery(query);
end
end
%% 
function  [t_FULL, attr_FULL,...
    t_FLUO, attr_FLUO] = getInfoMultSensor(user_data, ids, attribute)

[ids_FLUO, space_FLUO, spectra_FLUO, filenames_FLUO] = restrictToSensor(user_data, 'FloX', ids);
[ids_FULL, space_FULL, spectra_FULL, filenames_FULL] = restrictToSensor(user_data, 'ROX', ids);
time_FLUO                                            = user_data.specchio_client.getMetaparameterValues(ids_FLUO, 'Acquisition Time (UTC)');
time_FULL                                            = user_data.specchio_client.getMetaparameterValues(ids_FULL, 'Acquisition Time (UTC)');
attribute_FULL                                       = user_data.specchio_client.getMetaparameterValues(ids_FULL, attribute);
attribute_FLUO                                       = user_data.specchio_client.getMetaparameterValues(ids_FLUO, attribute);

t_FLUO = NaT(size(time_FLUO),1);
for i=1:size(time_FLUO)
    try
        tmp_dateTime_str = time_FLUO.get(i-1).toString().toCharArray';
    catch 
        tmp_dateTime_str = '2000-01-01T01:01:01.000Z';
    end
    measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
    t_FLUO(i, 1) = measurement_datetime;
end
t_FLUO = t_FLUO(t_FLUO > datetime('2000-01-01T01:01:01.000Z', 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'),1);


attr_FLUO = nan(size(attribute_FLUO),1);
for i=1:size(attribute_FLUO)
    if(isfinite(attribute_FLUO.get(i-1)))
        attr_FLUO(i,1) = attribute_FLUO.get(i-1);
    end
end
attr_FLUO = attr_FLUO(t_FLUO > datetime('2000-01-01T01:01:01.000Z', 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'),1);

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

attr_FULL = nan(size(attribute_FULL),1);
for i=1:size(attribute_FULL)
    if(isfinite(attribute_FULL.get(i-1)))
    attr_FULL(i,1) = attribute_FULL.get(i-1);
    end
end
attr_FULL = attr_FULL(t_FULL > datetime('2000-01-01T01:01:01.000Z', 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'),1);

end
%%
function [t, attr] = getInfoSingleSensor(user_data, ids, attribute)
timeVal                                            = user_data.specchio_client.getMetaparameterValues(ids, 'Acquisition Time (UTC)');
attributeVal                                       = user_data.specchio_client.getMetaparameterValues(ids, attribute);

t = NaT(size(timeVal),1);
for i=1:size(timeVal)
    try
        tmp_dateTime_str = timeVal.get(i-1).toString().toCharArray';
    catch 
        tmp_dateTime_str = '2000-01-01T01:01:01.000Z';
    end
    measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
    t(i, 1) = measurement_datetime;
end
t = t(t > datetime('2000-01-01T01:01:01.000Z', 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'),1);


attr = nan(size(attributeVal),1);
for i=1:size(attributeVal)
    if(isfinite(attributeVal.get(i-1)))
        attr(i,1) = attributeVal.get(i-1);
    end
end
attr = attr(t > datetime('2000-01-01T01:01:01.000Z', 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'),1);

end