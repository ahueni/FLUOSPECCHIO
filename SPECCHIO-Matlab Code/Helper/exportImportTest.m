fid = fopen('C:\Users\bbuman\Downloads\Daten-Sentinel_3-Comparison\export.csv');
for i=1:28
    fgetl(fid)
end
wvl = nan(1051-28,1);
spectra = nan(1051-28, 8);

for i=1:(1051-28)
    curLine = fgetl(fid);
    curLine = regexp(curLine, ',', 'split');
    wvl(i) = str2double(curLine{1});
    for j=1:8
        spectra(i, j) = str2double(curLine{j+1});
    end
end
 

plot(wvl, spectra)
axis([640 850 0 1])
title('Broadrange')