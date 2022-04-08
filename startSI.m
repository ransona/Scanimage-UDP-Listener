clearvars –global hSI hSICtl;
global hSI
global hSICtl
[hSI,hSICtl] = scanimage;
% while or(~exist('hSI'),~exist('hSICtl'))
    while or(~exist('hSI'),~exist('hSICtl'))
    % wait for SI to make these stuctures
    drawnow
    end
siListener