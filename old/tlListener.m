function tlListener()
% when started this function will listen for UDP events on port 1807 and
% when a GOGOExpID*srcIP command is received will start timeline using
% ExpID as the experiment reference and confirm receipt with OK.  A STOP
% command will stop timeline.

while true
    % wait for UDPs
    drawnow;
    try
        % check if a command has come through
        command = udp.judp('RECEIVE',1807,1000,500);
        % if it gets this far something has been received
        command = char(command)';
        
        disp(command);
        
        if strcmp(command(1:4),'GOGO')
            % start timeline
            disp('Start timeline message received');
            command=command(5:end);
            command=strsplit(command,'*');
            tl.start(command{1});
            % send back confirmation
            pause(2);
            udp.judp('SEND',1808,command{2},int8('OK'));
        elseif strcmp(command(1:4),'STOP')    
            % stop timeline
            disp('Stop timeline message received');
            command=command(5:end);
            command=strsplit(command,'*');
            tl.stop;
            udp.judp('SEND',1808,command{2},int8('OK'));
        elseif strcmp(command(1:4),'INFO')
            % add the info to the timeline as a timestamped event
            % msg comes in form INFOeventtype%eventlabel*srcIP
            command=command(5:end);
            command=strsplit(command,'*');
            command2=strsplit(command{1},'%');
            tl.record(command2{1},command2{2});
            udp.judp('SEND',1808,command{2},int8('OK'));
        end
            
    catch exception
       
    end
end


end

