%{
Analyze_Pupil_Labs_RI (response inhibition task)
Purpose: import pupil-labs recordings into MATLAB
Author: Tom Bullock, UCSB Attention Lab
Date: 02.15.18

To do: 
Auto export from pupil player without having to go into the gui.

Notes:

%}

clear 
close all

subjects = 233;

for iSub=1:length(subjects)
    
    sjNum = subjects(iSub);
    
    for thisSession=1 %1:3
        
        % which condition (always 2)
        thisCondition = 2;

        % which rep?
        if thisSession==1
            thisRep=1;
        else
            thisRep=2;
        end
        thisTask = 'ri';
        
        % clear some vars
        annotations=[];
        pupilpositions1=[];
        gazeData=[];
        rowIndex = [];
        clear gazeDataResampled
        
        % add path to folder with analysis scripts
        addpath('/Users/tombullock/Documents/Psychology/BOSS/PUPIL_TEMP/pupil_labs/pupil_labs_matlab')
        
        % root dir
        rootDir = '/Users/tombullock/Documents/Psychology/BOSS/PUPIL_TEMP';
        
        % subject dir
        filePath = [rootDir '/b''' sprintf('BOSS_%d_%d_%d_%d_%s_Cal',sjNum,thisCondition,thisSession,thisRep,thisTask) '''/000/exports/000'];       
        %filePath = [rootDir '/b''' sprintf('BOSS_%d_%d_%d_%d_%s',sjNum,thisCondition,thisSession,thisRep,thisTask) '''/000/exports/000'];
        
        % save dir
        saveDir = '/Users/tombullock/Documents/Psychology/BOSS/PUPIL_TEMP/Processed_Data';
        
        % set annotation file name
        fileName = 'annotations.csv';
        
        % import annotations data
        disp('Importing annotation data')
        [annotations] = Import_Pupil_Labs_Annotation_Data(filePath, fileName);
        
        % set pupil_positions data file name
        fileName = 'pupil_positions.csv';
        
        % import pupil_positions data
        disp('Importing pupil positions data')
        [pupilpositions1] = Import_Pupil_Labs_Pupil_Positions_Data(filePath, fileName);
        
        % find surface gaze data csv file
        d=dir([filePath '/' 'surfaces' '/' 'gaze_positions*']);
        
        % import surface gaze data
        disp('Importing surface gaze data')
        [gazeData] = Import_Pupil_Labs_Gaze_Surface_Data(filePath, d.name);
        
        % check first timepoint
        firstGazeTimepoint = gazeData.world_timestamp(1);
        firstAnnotationTimepoint = annotations.timestamp(1);
        firstPupilPositionsTimepoint = pupilpositions1.timestamp(2);
        
        % check last timepoint
        lastGazeTimepoint = gazeData.world_timestamp(end);
        lastAnnotationTimepoint = annotations.timestamp(end);
        lastPupilPositionsTimepoint = pupilpositions1.timestamp(end);
        
        % are annotations consistent with gaze timestamp data?
        if firstGazeTimepoint<firstAnnotationTimepoint && lastGazeTimepoint>lastAnnotationTimepoint
            disp('Annotation timepoints are within gaze timepoint bounds')
        else
            disp('Annotation timepoints are NOT within gaze timepoint bounds! ABORT...')
            %%return
            break
        end
        
        % are annotations consistent with pupil position data?
        if firstPupilPositionsTimepoint<firstAnnotationTimepoint && lastPupilPositionsTimepoint>lastAnnotationTimepoint
            disp('Annotation timepoints are within pupil positions timepoint bounds')
        else
            disp('Annotation timepoints are NOT within pupil positions timepoint bounds! ABORT...')
            %%return
            break
        end
        
        
        % import pupil size data too (just this for now)
        gazeData(:,10) = {0};
        gazeData.Properties.VariableNames{10} = 'Diameter_0'; % creates label
        gazeData(:,11) = {0};
        gazeData.Properties.VariableNames{11} = 'Diameter_1'; % creates label
        for i=2:size(pupilpositions1,1) % loop through pupil positions data
            if pupilpositions1.id(i)==0
                [~, rowIndex] = min(abs(gazeData.gaze_timestamp - pupilpositions1.timestamp(i)));
                gazeData(rowIndex,10) = {pupilpositions1.diameter(i)};
            end
            if pupilpositions1.id(i)==1
                [~, rowIndex] = min(abs(gazeData.gaze_timestamp - pupilpositions1.timestamp(i)));
                gazeData(rowIndex,11) = {pupilpositions1.diameter(i)};
            end
        end
        
        % remove duplicate timepoints (currently 240 rows per sec, only 120 useful)
        disp('Removing duplicate gaze samples')
        cnt=0;
        for i=1:size(gazeData,1)
            if gazeData.Diameter_0(i)~=0
                cnt=cnt+1;
                gazeDataResampled(cnt,:) = gazeData(i,:);
            end
        end
        
        
        % match annotations with corresponding gaze timestamps and add to gaze data
        % table (column 10)
        gazeDataResampled(1,12) = {0};
        gazeDataResampled.Properties.VariableNames{12} = 'Annotation'; % creates label
        for i=1:size(annotations,1)
            i
            [~, rowIndex] = min(abs(gazeDataResampled.gaze_timestamp - annotations.timestamp(i)));
            gazeDataResampled(rowIndex,12) = {annotations.label(i)};
        end
        
        %% create epochs for different trial types e.g. 11,12,13, 110 (go trials)
        
        % select samples for each epoch ([-200 ms to 1000 ms] around event
        theseSamples = [-24,120]; % 120 Hz *2 eyes
        
        for epochType=1:4
            
            disp(['Epoching: epoch type ' num2str(epochType)])
            
            % clear stuff
            confidence = [];
            diameter0 = [];
            diameter1 = [];
            xPosition = [];
            yPosition = [];
            worldTimestamp = [];
            gazeTimestamp = [];
            blink = [];
            diameter0_open = [];
            diameter1_open = [];
            blinkPercentage = [];
            
            if epochType==1
                eventCodes = 11; % no-go human present
            elseif epochType==2
                eventCodes = 13; % no-go repeat
            elseif epochType==3
                eventCodes = [12, 110]; % go trial (12 is just 1st repeat, so "go")
            elseif epochType==4
                eventCodes = [11,12,13,110]; % all trials
            end
            
            cnt = 0;
            for i=1:size(gazeDataResampled,1)-121
                if ismember(gazeDataResampled.Annotation(i),eventCodes)
                    cnt=cnt+1;
                    %trials x times (-200 ms to 1000 ms)
                    confidence(cnt,:) = gazeDataResampled.confidence(i+theseSamples(1):i+theseSamples(2)); % pupil confidence (if low, then blink or bad tracking)
                    diameter0(cnt,:) = gazeDataResampled.Diameter_0(i+theseSamples(1):i+theseSamples(2)); % pupil 0 diameter
                    diameter1(cnt,:) = gazeDataResampled.Diameter_1(i+theseSamples(1):i+theseSamples(2)); % pupil 1 diameter
                    xPosition(cnt,:) = gazeDataResampled.x_norm(i+theseSamples(1):i+theseSamples(2)); % x eye position
                    yPosition(cnt,:) = gazeDataResampled.y_norm(i+theseSamples(1):i+theseSamples(2)); % y eye position
                    worldTimestamp(cnt,:) = gazeDataResampled.world_timestamp(i+theseSamples(1):i+theseSamples(2)); % world timestamp (coarse)
                    gazeTimestamp(cnt,:) = gazeDataResampled.gaze_timestamp(i+theseSamples(1):i+theseSamples(2)); % gaze timestamp (fine)
                end
            end
            
            % determine if blink trial (WHAT VALUE TO USE???) *** I COULD CROSS REF
            % WITH EEG TO DETERMINE CONFIDENCE ***
            for i=1:size(confidence,1)
                if min(confidence(i,:))<.9 % if confidence calls below xx on a trial, then classify as a blink
                    blink(i)=1; % eyes closed
                else
                    blink(i)=0; % eyes open 
                end
            end
            
            for i=1:size(confidence,1)
                minConfidence(i) = min(confidence(i,:));
            end
            
            
            % remove blink trials for analysis
            diameter0_open = diameter0(blink==0,:);
            diameter1_open = diameter1(blink==0,:);
            
            % replace zeros with NaNs (
            diameter0_open(diameter0_open==0) = NaN;
            diameter1_open(diameter1_open==0) = NaN;
            
            % calculate blink percentage
            blinkPercentage = sum(blink)/length(blink)*100;
            
            % enter data into structures
            if epochType==1
                epochedEyeData.noGoHumanTrials.worldTimestamp = worldTimestamp;
                epochedEyeData.noGoHumanTrials.gazeTimestamp = gazeTimestamp;
                epochedEyeData.noGoHumanTrials.xPosition = xPosition;
                epochedEyeData.noGoHumanTrials.yPosition = yPosition;
                epochedEyeData.noGoHumanTrials.confidence = confidence;
                epochedEyeData.noGoHumanTrials.diameter0 = diameter0;
                epochedEyeData.noGoHumanTrials.diameter1 = diameter1;
                epochedEyeData.noGoHumanTrials.diameter0_open = diameter0_open;
                epochedEyeData.noGoHumanTrials.diameter1_open = diameter1_open;
                epochedEyeData.noGoHumanTrials.blink = blink;
                epochedEyeData.noGoHumanTrials.blinkPercentage = blinkPercentage;
            elseif epochType==2
                epochedEyeData.noGoRepeatTrials.worldTimestamp = worldTimestamp;
                epochedEyeData.noGoRepeatTrials.gazeTimestamp = gazeTimestamp;
                epochedEyeData.noGoRepeatTrials.xPosition = xPosition;
                epochedEyeData.noGoRepeatTrials.yPosition = yPosition;
                epochedEyeData.noGoRepeatTrials.confidence = confidence;
                epochedEyeData.noGoRepeatTrials.diameter0 = diameter0;
                epochedEyeData.noGoRepeatTrials.diameter1 = diameter1;
                epochedEyeData.noGoRepeatTrials.diameter0_open = diameter0_open;
                epochedEyeData.noGoRepeatTrials.diameter1_open = diameter1_open;
                epochedEyeData.noGoRepeatTrials.blink = blink;
                epochedEyeData.noGoRepeatTrials.blinkPercentage = blinkPercentage;
            elseif epochType==3
                epochedEyeData.goTrials.worldTimestamp = worldTimestamp;
                epochedEyeData.goTrials.gazeTimestamp = gazeTimestamp;
                epochedEyeData.goTrials.xPosition = xPosition;
                epochedEyeData.goTrials.yPosition = yPosition;
                epochedEyeData.goTrials.confidence = confidence;
                epochedEyeData.goTrials.diameter0 = diameter0;
                epochedEyeData.goTrials.diameter1 = diameter1;
                epochedEyeData.goTrials.diameter0_open = diameter0_open;
                epochedEyeData.goTrials.diameter1_open = diameter1_open;
                epochedEyeData.goTrials.blink = blink;
                epochedEyeData.goTrials.blinkPercentage = blinkPercentage;
            elseif epochType==4
                epochedEyeData.allTrials.worldTimestamp = worldTimestamp;
                epochedEyeData.allTrials.gazeTimestamp = gazeTimestamp;
                epochedEyeData.allTrials.xPosition = xPosition;
                epochedEyeData.allTrials.yPosition = yPosition;
                epochedEyeData.allTrials.confidence = confidence;
                epochedEyeData.allTrials.diameter0 = diameter0;
                epochedEyeData.allTrials.diameter1 = diameter1;
                epochedEyeData.allTrials.diameter0_open = diameter0_open;
                epochedEyeData.allTrials.diameter1_open = diameter1_open;
                epochedEyeData.allTrials.blink = blink;
                epochedEyeData.allTrials.blinkPercentage = blinkPercentage;
            end
            
        end
        
        disp([ 'TOTAL ANNOTATIONS: ' num2str(size(epochedEyeData.allTrials.worldTimestamp,1))])
        
        % save epoched eye data (ADD SUBJECT NUMBER STUFF ETC)
        save([saveDir '/' sprintf('sj%d_c%d_s%d_%s_PL_Eye_Data.mat',sjNum,thisCondition,thisSession,thisTask)],'epochedEyeData','-v7.3')
        
    end
end



%% Create Plots (eventually move this to another script)

%% plot pupil diameter in different conditions
h=figure;
subplot(2,1,1)
plot(-200:1000/120:1000,nanmean(epochedEyeData.noGoHumanTrials.diameter0_open,1),'b'); hold on
plot(-200:1000/120:1000,nanmean(epochedEyeData.noGoRepeatTrials.diameter0_open,1),'g'); hold on
plot(-200:1000/120:1000,nanmean(epochedEyeData.goTrials.diameter0_open,1),'r'); hold on
xlabel('Time (ms) - PUPIL DIAMETER CAM 0 - NO BASELINE CORRECTION')
legend('noGo Human','noGo Repeat','Go')
pbaspect([3,1,1])

subplot(2,1,2)
plot(-200:1000/120:1000,nanmean(epochedEyeData.noGoHumanTrials.diameter1_open,1),'b'); hold on
plot(-200:1000/120:1000,nanmean(epochedEyeData.noGoRepeatTrials.diameter1_open,1),'g'); hold on
plot(-200:1000/120:1000,nanmean(epochedEyeData.goTrials.diameter1_open,1),'r'); hold on
xlabel('Time (ms) - PUPIL DIAMETER CAM 1 - NO BASELINE CORRECTION')
legend('noGo Human','noGo Repeat','Go')
pbaspect([3,1,1])

%% plot x/y positions in different conditions
h=figure;
subplot(2,1,1)
plot(-200:1000/120:1000,nanmean(epochedEyeData.noGoHumanTrials.xPosition,1),'b'); hold on
plot(-200:1000/120:1000,nanmean(epochedEyeData.noGoRepeatTrials.xPosition,1),'g'); hold on
plot(-200:1000/120:1000,nanmean(epochedEyeData.goTrials.xPosition,1),'r'); hold on
plot(-200:1000/120:1000,nanmean(epochedEyeData.noGoHumanTrials.yPosition,1),'b--'); hold on
plot(-200:1000/120:1000,nanmean(epochedEyeData.noGoRepeatTrials.yPosition,1),'g--'); hold on
plot(-200:1000/120:1000,nanmean(epochedEyeData.goTrials.yPosition,1),'r--'); hold on
xlabel('Time (ms) - MEAN X/Y POSITIONS ACROSS TRIALS')
legend('X noGo Human','X noGo Repeat','X Go','Y noGo Human','Y noGo Repeat','Y Go')
ylim([0 1])
pbaspect([3,1,1])


%% plot x/y positions over recording duration
subplot(2,1,2)
gazePosTime = gazeDataResampled.gaze_timestamp;
gazePosX=gazeDataResampled.x_norm;
gazePosY=gazeDataResampled.y_norm;
plot(gazePosX,'r'); hold on
plot(gazePosY,'b')
xlabel('MEAN X/Y POSITIONS ACROSS STUDY DURATION')
ylim([0 1])
pbaspect([3,1,1])