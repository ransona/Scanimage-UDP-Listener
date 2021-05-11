function siUDPServer()
global udpSI;
global udpCheckTimer;
global listenerStatus;
% Setup default status of listener
listenerStatus.expID = '2014-01-01_01_TEST';
listenerStatus.local = 'c:\Local_Repository';
listenerStatus.remote = '\\ar-lab-nas1\dataserver\Local_Repository';
disp('Listening');
udpSI = UDPqML('158.109.215.50',1814,1813);
udpCheckTimer = timer('StartDelay',0,'Period',1,'BusyMode','drop','TimerFcn',@checkUDP,'ExecutionMode','fixedRate');
start(udpCheckTimer);


function checkUDP(varargin)
% check the udp queue
    global udpSI;
    global hSI;
    global hSICtl;
    global siMotorData; 
    global listenerStatus;
%try
    udpData = udpSI.pull;
    
    if ~isempty(udpData)
        if strcmp(udpData.messageType,'COM')
            % if it's a command
            switch udpData.messageData
                case 'GOGO'
                    % check space on disk is > 50GB
                    FileObj      = java.io.File('C:\');
                    free_gb   = FileObj.getFreeSpace*1e-9;
                    if free_gb < 100
                        switch questdlg(['Space free = ',num2str(round(free_gb)),'GB - suggest delete data before continuing. Would you like to do this?']);
                            case 'Yes'
                                return
                        end
                    end
                    disp('=======');
                    disp('Received GOGO signal');
                    if ~strcmp(hSI.acqState,'idle')
                        disp('Already acquiring so aborting');
                        % if SI not idle then make idle
                        hSI.abort;
                        % wait for idle for max 10 secs
                        startAbort = tic;
                        while ~strcmp(hSI.acqState,'idle')&&toc(startAbort)<10
                            drawnow();
                        end
                        if ~strcmp(hSI.acqState,'idle');msgbox('Timed out waiting for SI to be ready');return;end;
                    end
                    
                    listenerStatus.expID = udpData.meta{1};
                    listenerStatus.animalID = listenerStatus.expID(15:end);
                    disp(['Exp ID: ',udpData.meta{1}]);
                    % ensure directory exists locally
                    
                    expDir = fullfile(listenerStatus.local,listenerStatus.animalID,listenerStatus.expID);
                    if ~exist(expDir,'dir')
                        mkdir(expDir)
                    end
                    
                    expDirRemote = fullfile(listenerStatus.remote,listenerStatus.animalID,listenerStatus.expID);
                    if ~exist(expDirRemote,'dir')
                        mkdir(expDirRemote)
                    end
                    
                    %hSICtl.hModel.loggingFilePath = data.local(listenerStatus.expID);
                    %hSICtl.hModel.loggingFileStem = [listenerStatus.expID,'_2P'];
                    
                    hSI.hScan2D.logFilePath = expDir;
                    hSI.hScan2D.logFileStem = [listenerStatus.expID,'_2P'];
        
                    
                    % save meta data about the acquisition such as roi
                    if isfield(siMotorData,'currentRoi')
                        imagingMeta.currentRoi = siMotorData.currentRoi;
                    else
                        imagingMeta = [];
                    end
                    metaPath = fullfile(expDir,[listenerStatus.expID,'_imageMeta.mat']);
                    if ~exist(expDir,'dir')
                        mkdir(expDir)
                    end
                    save(metaPath,'imagingMeta');

                    % start the acquisition and wait for confirmation
                    %evalin('base','hSI.startGrab');
                    % T = timer('StartDelay',5,'TimerFcn',@(src,evt)evalin('base','hSI.startGrab'));
                    hSI.startGrab
                    % start(T)
                    %hSI.startGrab;
                    % drawnow;
                    disp('Requested start grabbing');
%                     while ~strcmp(hSI.acqState,'grab')
%                         %drawnow();
%                     end
                    udpSI.send('READY','COM');
                    disp('Grabbing confirmed');
                case 'STOP'
                    hSI.abort;
                    disp('=======');
                    disp('Received STOP signal');
                    startAbort = tic;
                    while ~strcmp(hSI.acqState,'idle')&&(toc(startAbort)<10)
                        drawnow();
                    end
                    if ~strcmp(hSI.acqState,'idle');msgbox('Timed out waiting for SI to be ready');return;end;
                    udpSI.send('READY','COM');
                    disp('Stopped');
            end
        end
        
    end
    
%catch
%    disp('Error processing UDP data');
%end
