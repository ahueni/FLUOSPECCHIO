
for i=1:4
    
    for j=ceil(startval):ceil(endval)
        groups2(rowcount,i) = groups.get(j);
        rowcount = rowcount + 1;
    end
    startval = endval +1;
    endval = startval + endval;
end


startval = 0;
endval = round(size(groups)/4);
for i =1:4
    rowcount = 1;
    for j = startval : endval
        groups2(rowcount, i) = groups.get(j);
        rowcount = rowcount + 1;
    end
    startval = endval + 1;
    endval = startval + endval;
end