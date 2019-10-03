% FIND MATCHING SPECTRA FOR SENTINEL COMPARISON

%% DB
import ch.specchio.client.*;
import ch.specchio.queries.*;
import ch.specchio.gui.*;
import ch.specchio.types.*;

% connect to SPECCHIO
user_data.cf                                                = SPECCHIOClientFactory.getInstance();
user_data.db_descriptor_list                                = user_data.cf.getAllServerDescriptors();
user_data.specchio_client                                   = user_data.cf.createClient(user_data.db_descriptor_list.get(connectionID));


%% Queries; target: 2018-06-26 09:32
% Before (= later than 2018-06-26 09:30)
query = Query('spectrum');
query.setQueryType(Query.SELECT_QUERY);

query.addColumn('spectrum_id')

cond = SpectrumQueryCondition('spectrum', 'measurement_unit_id');
cond.setValue('0');
cond.setOperator('=');
query.add_condition(cond);

cond = EAVQueryConditionObject('eav', 'spectrum_x_eav', 'Acquisition Time (UTC)', 'datetime_val');
cond.setValue('20180626093100');
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

all_ids_A = user_data.specchio_client.getSpectrumIdsMatchingQuery(query);

% FILTER FOR PROCESSING LEVEL 2.0 (REFLECTANCE) ONLY
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
cond.setValue('2.0');
cond.setOperator('>=');
query.add_condition(cond);

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
cond.setValue('20180626093400');
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

all_ids_B = user_data.specchio_client.getSpectrumIdsMatchingQuery(query);

% FILTER FOR PROCESSING LEVEL 2.0 (REFLECTANCE) ONLY
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
cond.setValue('2.0');
cond.setOperator('>=');
query.add_condition(cond);

all_ids_B = user_data.specchio_client.getSpectrumIdsMatchingQuery(query);

allA = zeros(size(all_ids_B),1);
for i=0:size(all_ids_A)-1
    allA(i+1,1) = all_ids_A.get(i);
end


allB = zeros(size(all_ids_B),1);
for i=0:size(all_ids_B)-1
    allB(i+1,1) = all_ids_B.get(i);
end


% FIND MATCHING:
matched = find(ismember(allA,allB));
selected = allA(matched);

% BACK TO ARRAYLIST:
all_ids_A.clear();
for i=0:size(selected,1)-1
    all_ids_A.add(i,  int32(selected(i+1,1)));
end

[ids_QEpro, space_QEpro, spectra_QEpro, filenames_QEpro]    = restrictToSensor(user_data, 'FloX', all_ids_A);
[ids_FLAME, space_FLAME, spectra_FLAME, filenames_FLAME]    = restrictToSensor(user_data, 'ROX', all_ids_A);
wvl_QEpro                                                   = space_QEpro.getAverageWavelengths();
wvl_FLAME                                                   = space_FLAME.getAverageWavelengths();
VIs                                                         = compute_VIs(wvl_FLAME, spectra_FLAME');
insertVIs(user_data, ids_FLAME, VIs);
time_QEpro                                                  = user_data.specchio_client.getMetaparameterValues(ids_QEpro, 'Acquisition Time (UTC)');
time_FLAME                                                  = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'Acquisition Time (UTC)');
NDVI_FLAME                                                  = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'NDVI');
EVI_FLAME                                                   = user_data.specchio_client.getMetaparameterValues(ids_FLAME, 'EVI');



for i=1:size(time_FLAME)
   tmp_dateTime_str = time_FLAME.get(i-1).toString().toCharArray';
   measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
   t_FLAME(i, 1) = measurement_datetime;
end

for i=1:size(time_QEpro)
   tmp_dateTime_str = time_QEpro.get(i-1).toString().toCharArray';
   measurement_datetime = datetime(tmp_dateTime_str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
   t_QEpro(i, 1) = measurement_datetime;
end

ndvi_fl = nan(size(NDVI_FLAME),1);
for i=0:size(ndvi_fl)-1
    ndvi_fl(i+1,1) = NDVI_FLAME.get(i);
end

evi_fl = nan(size(EVI_FLAME),1);
for i=0:size(evi_fl)-1
    evi_fl(i+1,1) = EVI_FLAME.get(i);
end


figure(1) 
clf
subplot(2,3,1)
plot(wvl_FLAME, spectra_FLAME)
axis([640 850 0 1])
title('Broadrange')

subplot(2,3,2)
plot(wvl_QEpro, spectra_QEpro)
title('SIF')

% subplot(2,3,3)
% plot(t_QEpro, spectra_QEpro(:,417:670))
% title('SIF Timeseries @ 720 nm - 760 nm')
% subplot(2,3,4)
% plot(t_QEpro, spectra_QEpro(:,118:236))
% title('SIF Timeseries @ 670 nm - 690 nm')

% Plots , SIF @ 687 and 761

subplot(2,3,1)
plot(t_QEpro, mean(spectra_QEpro(:, find(wvl_QEpro >= 687 & wvl_QEpro < 688)),2)) % find wavelength, then take mean of the measurements within the given frame mean(A,2) is row mean
title('SIF Timeseries @ 687 nm')

subplot(2,3,2)
plot(t_QEpro, mean(spectra_QEpro(:, find(wvl_QEpro >= 760 & wvl_QEpro < 761)),2))
title('SIF Timeseries @ 760 nm')

% Plots , SIF @ max<F687> and max<761>

subplot(2,3,3)
plot(wvl_QEpro, nanmax(nanmean(spectra_QEpro(:, find(wvl_QEpro >= 650 & wvl_QEpro < 700)),2),[],2)) 
title('SIF Timeseries @ 687 nm')

subplot(2,3,4)
plot(wvl_QEpro,  nanmax(nanmean(spectra_QEpro(:, find(wvl_QEpro >= 700 & wvl_QEpro < 800)),2)),2)
title('SIF Timeseries @ 760 nm')


subplot(2,3,5)
plot(t_FLAME, ndvi_fl)
title('NDVI - BROADRANGE')

subplot(2,3,6)
plot(t_FLAME, evi_fl)
title('EVI - BROADRANGE')