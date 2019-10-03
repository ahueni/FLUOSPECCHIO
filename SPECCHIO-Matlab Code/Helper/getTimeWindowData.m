function matching_ids = getTimeWindowData(user_data, processing_level, startDateTime, endDateTime)
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.gui.*;
import ch.specchio.types.*;

%% Queries 
% startDateTime
query = Query('spectrum');
query.setQueryType(Query.SELECT_QUERY);

query.addColumn('spectrum_id')

cond = SpectrumQueryCondition('spectrum', 'measurement_unit_id');
cond.setValue('0');
cond.setOperator('=');
query.add_condition(cond);

cond = EAVQueryConditionObject('eav', 'spectrum_x_eav', 'Acquisition Time (UTC)', 'datetime_val');
cond.setValue(startDateTime);
cond.setOperator('>=');
query.add_condition(cond);

cond = SpectrumQueryCondition('spectrum', 'sensor_id');
cond.setValue('0');
cond.setOperator('=');
query.add_condition(cond);

cond = SpectrumQueryCondition('spectrum', 'instrument_id');
cond.setValue('0');
cond.setOperator('=');
query.add_condition(cond);

cond = SpectrumQueryCondition('spectrum', 'calibration_id');
cond.setValue('0');
cond.setOperator('=');
query.add_condition(cond);

% The following ids were acquired later or equal to startDateTime
all_ids_A = user_data.specchio_client.getSpectrumIdsMatchingQuery(query);

% FILTER the just gathered ids for the specified processing level
query = Query('spectrum');
query.setQueryType(Query.SELECT_QUERY);

query.addColumn('spectrum_id')

cond = SpectrumQueryCondition('spectrum', 'measurement_unit_id');
cond.setValue('0');
cond.setOperator('=');
query.add_condition(cond);

cond = ch.specchio.queries.QueryConditionObject('spectrum', 'spectrum_id');
cond.setValue(all_ids_A);
cond.setOperator('in');
query.add_condition(cond);

cond = EAVQueryConditionObject('eav', 'spectrum_x_eav', 'Processing Level', 'double_val');
cond.setValue(processing_level);
cond.setOperator('>=');
query.add_condition(cond);

% The following ids were acquired later or equal to startDateTime 
% and have the required processing level
all_ids_A = user_data.specchio_client.getSpectrumIdsMatchingQuery(query);


% Before (= later than 2018-06-26 09:30)
query = Query('spectrum');
query.setQueryType(Query.SELECT_QUERY);

query.addColumn('spectrum_id')

cond = SpectrumQueryCondition('spectrum', 'measurement_unit_id');
cond.setValue('0');
cond.setOperator('=');
query.add_condition(cond);

cond = EAVQueryConditionObject('eav', 'spectrum_x_eav', 'Acquisition Time (UTC)', 'datetime_val');
cond.setValue(endDateTime);
cond.setOperator('<=');
query.add_condition(cond);

cond = SpectrumQueryCondition('spectrum', 'sensor_id');
cond.setValue('0');
cond.setOperator('=');
query.add_condition(cond);

cond = SpectrumQueryCondition('spectrum', 'instrument_id');
cond.setValue('0');
cond.setOperator('=');
query.add_condition(cond);

cond = SpectrumQueryCondition('spectrum', 'calibration_id');
cond.setValue('0');
cond.setOperator('=');
query.add_condition(cond);

% The following ids were acquired earlier or equal to endDateTime
all_ids_B = user_data.specchio_client.getSpectrumIdsMatchingQuery(query);

% FILTER the just gathered ids for the specified processing level
query = Query('spectrum');
query.setQueryType(Query.SELECT_QUERY);

query.addColumn('spectrum_id')

cond = SpectrumQueryCondition('spectrum', 'measurement_unit_id');
cond.setValue('0');
cond.setOperator('=');
query.add_condition(cond);

cond = ch.specchio.queries.QueryConditionObject('spectrum', 'spectrum_id');
cond.setValue(all_ids_B);
cond.setOperator('in');
query.add_condition(cond);

cond = EAVQueryConditionObject('eav', 'spectrum_x_eav', 'Processing Level', 'double_val');
cond.setValue(processing_level);
cond.setOperator('>=');
query.add_condition(cond);

% The following ids were acquired earlier or equal to endDateTime
% and have the required processing level
all_ids_B = user_data.specchio_client.getSpectrumIdsMatchingQuery(query);


% Convert array-lists to vectors (for faster filtering)
allA = zeros(max(size(all_ids_A), size(all_ids_B)),1);
for i=0:size(all_ids_A)-1
    allA(i+1,1) = all_ids_A.get(i);
end

allB = zeros(max(size(all_ids_A), size(all_ids_B)),1);
for i=0:size(all_ids_B)-1
    allB(i+1,1) = all_ids_B.get(i);
end

% find matching values in both (--> they fall into the specified
% dateTime-Window)
matched = find(ismember(allA,allB));
selected = allA(matched);

% convert the now found ids back to an arraylist
matching_ids = java.util.ArrayList();
for i=0:size(selected,1)-1
    matching_ids.add(i,  int32(selected(i+1,1)));
end

end