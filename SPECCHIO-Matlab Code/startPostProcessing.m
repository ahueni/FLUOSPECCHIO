% Run script for SPECCHIO post processing
% This script is supposed to be started from a command line as follows:
% matlab -r "startPostProcessing <campaignId>"
% where <campaignId> is simply a number identifying the actual specchio
% campaign
% This will start the whole post processing by invoking the
% main method on the Starter object

function log = startPostProcessing(campaignId, connectionId, logFilePath)
    addpath(genpath('Resources'));
    % write the first entry to the processing log file:
    logFileName = ['Processing_Log_Matlab_',datestr(now, 'yyyy_mm_dd_HH_MM.txt')];
    logger = Logger(logFilePath, logFileName);
    startInfo = ['Started processing routine (campaignId =', int2str(campaignId), ', connectionId = ', int2str(connectionId), ').'];
    logger.writeLog('INFO', startInfo);
    fprintf('Process started at: %s\n', datestr(now,'HH:MM'))
    global log
    % Create a starter object
    start= Starter(uint32(campaignId), uint32(connectionId), logger);
    % call main method to start the processing
    start.main();
    log = log;
    fprintf('Process finished at: %s\n', datestr(now,'HH:MM'))
end