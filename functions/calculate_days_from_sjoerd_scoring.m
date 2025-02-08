function [Days, ScoringString] = calculate_days_from_sjoerd_scoring(ScoringString, ...
    EEGPoints, SampleRate, EpochLength)
% identifies what time in seconds to seperate the EEG into 24 h days, and
% adjusts the scoring string with blanks (or cuts) to make sure it matches
% the provided EEG. WARNING: this will avoid crashing, but could lead to
% incorrect results if the scoring doesn't actually correspond to the EEG.

Day = 60*60*24;
RecordingDuration = EEGPoints/SampleRate;
Epochs = 0:EpochLength:RecordingDuration;
nEpochs = numel(Epochs);


if isempty(ScoringString)
    ScoringString = repmat('w', 1, nEpochs);
else
    if nEpochs<numel(ScoringString)
        warning(['Scoring longer than file by ', num2str(numel(ScoringString)-nEpochs)])
        ScoringString = ScoringString(1:nEpochs);
    elseif nEpochs>numel(ScoringString)
        warning(['File longer than scoring by ', num2str(nEpochs-numel(ScoringString))])
        NewScoringString = repmat('?', 1, nEpochs);
        NewScoringString(1:numel(ScoringString)) = ScoringString;
        ScoringString = NewScoringString;
    end
end
Days = Epochs(dsearchn(Epochs', [0:Day:RecordingDuration+Day]'));
