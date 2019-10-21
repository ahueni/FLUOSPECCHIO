function [ids_rstr, space_rstr, spectra_rstr, filenames_rstr] = restrictToSensor(user_data, sensorType, all_ids)
import ch.specchio.queries.*; 
query = Query('spectrum');
query.setQueryType(Query.SELECT_QUERY);

query.addColumn('spectrum_id')


cond = ch.specchio.queries.QueryConditionObject('spectrum', 'spectrum_id');
cond.setValue(all_ids);
cond.setOperator('in');
query.add_condition(cond);


cond = SpectrumQueryCondition('spectrum', 'file_format_id');
file_format_id = user_data.specchio_client.getFileFormatId(sensorType);
cond.setValue(num2str(file_format_id));
cond.setOperator('=');
query.add_condition(cond);

ids = user_data.specchio_client.getSpectrumIdsMatchingQuery(query);

spaces = user_data.specchio_client.getSpaces(ids, 'Spectrum Number');
ids_rstr = spaces(1).getSpectrumIds(); % get ids sorted by  'Spectrum Number'
space_rstr = user_data.specchio_client.loadSpace(spaces(1));
spectra_rstr = space_rstr.getVectorsAsArray();
filenames_rstr = user_data.specchio_client.getMetaparameterValues(ids_rstr, 'File Name');

end 
