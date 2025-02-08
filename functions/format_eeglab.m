function EEG = format_eeglab(data, chanlocs)
% converts the fieldtrip output into the standard EEGLAB format. This
% should exist somewhere, but I wasn't getting it to work.
arguments
    data
    chanlocs = [];
end

Data = data.trial{1};
EEG = struct();
EEG.data = Data;
EEG.srate = data.fsample;


if isempty(chanlocs)
for ChIdx = 1:size(EEG.data, 1)
    chanlocs(ChIdx).label = data.label(ChIdx);
    chanlocs(ChIdx).X = nan;
    chanlocs(ChIdx).Y = nan;
    chanlocs(ChIdx).Z = nan;
end
end
    EEG.chanlocs = chanlocs;
EEG.xmax = size(Data, 2)/EEG.srate;
EEG.xmin = 0;
EEG.time = data.time{1};
EEG.trials = 1;
EEG.pnts = size(EEG.data, 2);
EEG.nbchan = size(EEG.data, 1);
EEG.event = [];
EEG.setname = '';
EEG.icasphere = '';
EEG.icaweights = '';
EEG.icawinv = '';
EEG.etc = [];

EEG = eeg_checkset(EEG);