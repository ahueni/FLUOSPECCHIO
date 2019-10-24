function timeLab = createTimeLabels(x, y, t)
    formatOut = 'HH:MM';
     if x<0.01
%         timeLab = [num2str(hour(t(1))) ':' num2str(minute(t(1)))];
        timeLab = datestr(t(1),formatOut);
     else 
%         timeLab = [num2str(hour(t(round((x * size(y,1)))))) ':' num2str(minute(t(round((x * size(y,1))))))];
        timeLab = datestr(t(round((x * size(y,1)))),formatOut);
     end
end