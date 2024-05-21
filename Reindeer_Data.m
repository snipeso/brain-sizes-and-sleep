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
FooofFrequencyRange = [3 40]; % frequencies over which to fit the model
SmoothSpan = 3;
MaxError = .15;
MinRSquared = .95;
Refresh = true;

% plot parameters
ScatterSizeScaling = 20;
Alpha = .5;

% locations
DataFolder = 'D:\Data\MelanieReindeer';
Destination = fullfile(DataFolder, 'Results');
if ~exist(Destination, 'dir')
    mkdir(Destination)
end

% stages
OldEpochLength = 4;
NewEpochLength = 8; % Can be as low as 4, or as high as you want. Should be multiple of 4.
SampleRate = 128;

% time to keep
% TimeToKeep = [0.0001 60*60*1]; % in seconds


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run

Files = oscip.list_filenames(DataFolder);

%%% identify main oscillations in each recording
for FileIdx = 5%1:numel(Files)

    File = Files(FileIdx);

    if exist(fullfile(Destination, File), 'file') && ~Refresh
        load(fullfile(Destination, File))
    else
        load(fullfile(DataFolder, File), 'EEG', 'scoring')
        EEGData = EEG;
        StringScoring = scoring;

        EEG = oscip.utils.format_eeglab(EEGData, SampleRate);
        Data = EEG.data;

        % calculate power
        [EpochPower, Frequencies] = oscip.compute_power_on_epochs(Data, ...
            SampleRate, NewEpochLength, WelchWindowLength, WelchOverlap);

        % select most common score for each epoch (when new epoch is larger
        % than old)
        [Scoring, ScoringIndexes, ScoringLabels] = oscip.convert_animal_scoring(StringScoring, size(EpochPower, 2), NewEpochLength, OldEpochLength);

        SmoothPower = oscip.smooth_spectrum(EpochPower, Frequencies, SmoothSpan); % better for fooof if the spectra are smooth

        % run FOOOF
        [Slopes, Intercepts, FooofFrequencies, PeriodicPeaks, WhitenedPower, Errors, RSquared] ...
            = oscip.fit_fooof_multidimentional(SmoothPower, Frequencies, FooofFrequencyRange, MaxError, MinRSquared);

        save(fullfile(Destination, File), 'EEG', 'Scoring', 'ScoringIndexes', 'ScoringLabels', ...
            'SmoothPower', 'Frequencies', 'Slopes', 'Intercepts', ...
            'FooofFrequencies', 'PeriodicPeaks', 'WhitenedPower', 'Errors','RSquared')
    end

Scoring(Scoring==-2) = -3;
ScoringIndexes = [-3 -1 0 1];
    % plot
    if PlotIndividuals
        Title = replace(replace(File, '.mat', ''), '_', ' ');
        FigureTitle = char(extractBefore(File, '.mat'));
        oscip.plot.temporal_overview(squeeze(mean(WhitenedPower,1)), ...
            FooofFrequencies, NewEpochLength, Scoring, ScoringIndexes, ScoringLabels, Slopes, [], [], Title)
        set(gcf, 'InvertHardcopy', 'off', 'Color', 'w')
        print(fullfile(Destination, [FigureTitle, '_time']), '-dtiff', '-r1000')

        oscip.plot.frequency_overview(SmoothPower, Frequencies, PeriodicPeaks, ...
            Scoring, ScoringIndexes, ScoringLabels, ScatterSizeScaling, Alpha, true, true)
        xlim([5 20])
        ylim([1 6])
        title(Title)
        set(gcf, 'InvertHardcopy', 'off', 'Color', 'w')
        print(fullfile(Destination, [FigureTitle, '_frequency']), '-dtiff', '-r1000')

        figure('Units','centimeters', 'Position',[0 0 10 10], 'Color','w')
        for ChannelIdx = 1:size(Slopes, 1)
            subplot(size(Slopes, 1), 1, ChannelIdx)
            oscip.plot.histogram_stages(Slopes(ChannelIdx, :), Scoring, ScoringLabels, ScoringIndexes); title(num2str(ChannelIdx))
            xlim([0 3.5])
        end
        set(gcf, 'InvertHardcopy', 'off', 'Color', 'w')
        print(fullfile(Destination, [FigureTitle, '_slopes']), '-dtiff', '-r1000')
    end
end
