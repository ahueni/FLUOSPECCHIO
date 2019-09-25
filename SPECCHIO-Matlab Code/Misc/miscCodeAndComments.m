% MISC CODE REPOSITORY
% for i=0:size(all_ids)-1
%     spec = num2str(all_ids.get(i));
%     sensor = user_data.specchio_client.getSpectrum(all_ids.get(i), true).getFileFormat().toString();
%     sensor = char(sensor);   
%     disp([ 'Spectrum ' spec ' has instrument type = ' sensor]);  
% end