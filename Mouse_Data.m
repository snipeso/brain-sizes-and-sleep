% Runs the code on animal data (from A. Osorio-Forero). This repo does not include the data, you'll need to have your own. Sorry :/
clear
close all
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% setup

% choose what to do
PlotIndividuals = true;

%%% analysis parameters

% power
WelchWindowLength = 1; % in seconds
WelchOverlap = .5; % 50% of the welch windows will overlap

% fooof
FooofFrequencyRange = [5 50]; % frequencies over which to fit the model
SmoothSpan = 3;
MaxError = .15;
MinRSquared = .95;
Refresh = true;

% plot parameters
ScatterSizeScaling = 50;
Alpha = .1;

% locations
% DataFolder = 'D:\Data\AlejoMouseInhibReticThalam';
% ChannelsToKeep = 1:4;
DataFolder = 'D:\Data\AlejoMouseSD';
ChannelsToKeep = [1 2 5 6];
ChannelsToPlot = [1:2];
Destination = fullfile(DataFolder, 'Results2');
if ~exist(Destination, 'dir')
    mkdir(Destination)
end

% stages
StageLabels = {'W', 'R', 'NR'};
StageIndexes = {0, 1, -1};
EpochLength = 4; % Can be as low as 4, or as high as you want. Should be multiple of 4.
NewSampleRate = 200;
OldSampleRate = 1000;

% time to keep
% TimeToKeep = [0.0001 60*60*1]; % in seconds


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run

Files = oscip.list_filenames(DataFolder);

%%% identify main oscillations in each recording
for FileIdx = 1:numel(Files)

    File = Files(FileIdx);

    if exist(fullfile(Destination, File), 'file') && ~Refresh
        load(fullfile(Destination, File))
    else
        load(fullfile(DataFolder, File), 'traces', 'b', 'traceName')
        % EEGData = traces(ChannelsToKeep, ceil(TimeToKeep(1)*OldSampleRate):floor(TimeToKeep(2)*OldSampleRate));
         EEGData = traces(ChannelsToKeep, :);
        % StringScoring = b(ceil(TimeToKeep(1)/4):floor(TimeToKeep(2)/4));
        StringScoring = b;
        traceName = traceName(ChannelsToKeep);

        EEG = oscip.utils.format_eeglab(EEGData, OldSampleRate);

        % downsample to decent values
        EEG = pop_resample(EEG, NewSampleRate);

        Data = EEG.data;

        % calculate power
        [EpochPower, Frequencies] = oscip.compute_power_on_epochs(Data, ...
            NewSampleRate, EpochLength, WelchWindowLength, WelchOverlap);

        % select most common score for each epoch (when new epoch is larger
        % than old)
        [Scoring, ScoringIndexes, ScoringLabels] = oscip.convert_animal_scoring(StringScoring, size(EpochPower, 2), EpochLength, 4);

        SmoothPower = oscip.smooth_spectrum(EpochPower, Frequencies, SmoothSpan); % better for fooof if the spectra are smooth

        % run FOOOF
        [Slopes, Intercepts, FooofFrequencies, PeriodicPeaks, WhitenedPower, Errors, RSquared] ...
            = oscip.fit_fooof_multidimentional(SmoothPower, Frequencies, FooofFrequencyRange, MaxError, MinRSquared);

        save(fullfile(Destination, File), 'EEG', 'Scoring', 'ScoringIndexes', 'ScoringLabels', ...
            'SmoothPower', 'Frequencies', 'Slopes', 'Intercepts', ...
            'FooofFrequencies', 'PeriodicPeaks', 'WhitenedPower', 'Errors','RSquared', 'traceName')
    end


    % plot
    if PlotIndividuals
        Title = replace(replace(File, '.mat', ''), '_', ' ');
        FigureTitle = char(extractBefore(File, '.mat'));
        oscip.plot.temporal_overview(squeeze(mean(WhitenedPower,1)), ...
            FooofFrequencies, EpochLength, Scoring, ScoringIndexes, ScoringLabels, Slopes, [], [], Title)
        set(gcf, 'InvertHardcopy', 'off', 'Color', 'w')
        % saveas(gcf, fullfile(Destination, [FigureTitle, '_time.svg']));
        print(fullfile(Destination, [FigureTitle, '_time']), '-dtiff', '-r1000')

        oscip.plot.frequency_overview(SmoothPower(ChannelsToPlot, :, :), Frequencies, PeriodicPeaks(ChannelsToPlot, :, :), ...
            Scoring, ScoringIndexes, ScoringLabels, ScatterSizeScaling, Alpha, true, true)
        title(Title)
                set(gcf, 'InvertHardcopy', 'off', 'Color', 'w')
        print(fullfile(Destination, [FigureTitle, '_frequency']), '-dtiff', '-r1000')

        figure('Units','centimeters', 'Position',[0 0 10 30], 'Color','w')
        for ChannelIdx = 1:size(Slopes, 1)
            subplot(4, 1, ChannelIdx)
            oscip.plot.histogram_stages(Slopes(ChannelIdx, :), Scoring, ScoringLabels, ScoringIndexes); title(traceName(ChannelIdx))
            xlim([0 3.5])
        end
                set(gcf, 'InvertHardcopy', 'off', 'Color', 'w')
        print(fullfile(Destination, [FigureTitle, '_slopes']), '-dtiff', '-r1000')
    end
end
