%%%%%%%%%%%%%%%%%%%%%%%%%%
% Logger for the processing routines
%
% July 2020
% @ Bastian Buman, bastian.buman@geo.uzh.ch
%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef Logger
    
    properties
        logFilePath;
        logFileName;
    end
    
    methods
        function this = writeLog(this, descriptor, message)
            fid = fopen(fullfile(this.logFilePath, this.logFileName), 'a');
            if fid == -1
              error('Cannot open log file.');
            end
            fprintf(fid, '%s - %s - %s\n', datestr(now, 'yyyy/mm/dd:HH:MM:SS'), descriptor, message); %27/Jul/2020:13:31:49 - message \n
            fclose(fid);
        end
        
         function this = Logger(logFilePath, logFileName)
            % Constructor for Logger class
            this.logFilePath = logFilePath;  
            this.logFileName = logFileName;
        end
    end
   
end