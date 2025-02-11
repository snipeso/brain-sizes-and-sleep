function chop_and_save_recording_by_days(EEG, ScoringString, LightString, EpochLength, Destination, FilenameCore)
% takes a multi-day recording, and divides it by 24 h days. Chops the EEG,
% the scoring and light/dark strings. Saves a mat file in the destination
% folder containing the variables "EEG", "ScoringString" and "LightString"

% assign temp name for whole recordings
EEGWhole = EEG;
ScoringStringWhole = ScoringString;
LightStringWhole = LightString;

% figure out where the breaks are
[Days, nEpochs] = days_in_recording(size(EEGWhole.data, 2), EEGWhole.srate, EpochLength);
ScoringStringWhole = adjust_scoring_string(ScoringStringWhole, nEpochs);
LightStringWhole = adjust_scoring_string(LightStringWhole, nEpochs);

ScoringTime = 0:EpochLength:Days(end)+EpochLength;

for DayIdx =  1:numel(Days)-1
    Start = Days(DayIdx);
    End = Days(DayIdx+1);

    if End > size(EEGWhole.data,2)
        End = size(EEGWhole.data,2);
    end

    EEG = pop_select(EEGWhole, 'time', [Start, End]);
    ScoringCuts = dsearchn(ScoringTime',[Start; End]);
    ScoringString = ScoringStringWhole(ScoringCuts(1):ScoringCuts(2));
    LightString = LightStringWhole(ScoringCuts(1):ScoringCuts(2));

    save(fullfile(Destination, [FilenameCore, '_Day', num2str(DayIdx), '.mat']), 'EEG', 'ScoringString', 'LightString', 'EpochLength',  '-v7.3')
   disp(['Finished day ', num2str(DayIdx)])
end