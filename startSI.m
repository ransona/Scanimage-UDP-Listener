clearvars –global hSI hSICtl;
[hSI,hSICtl] = scanimage;
while or(~exist('hSI'),~exist('hSICtl'))
    % wait for SI to make these stuctures
    drawnow
end
global hSI
global hSICtl
siListener