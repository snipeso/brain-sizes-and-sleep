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
WelchWindowLength = 4; % in seconds
WelchOverlap = .5; % 50% of the welch windows will overlap

% fooof
FooofFrequencyRange = [3 40]; % frequencies over which to fit the model
SmoothSpan = 3;
MaxError = .15;
MinRSquared = .95;
Refresh = true;

% plot parameters
ScatterSizeScaling = 20;
Alpha = .1;
EpochLength = 20;

% locations
DataFolder = 'D:\Data\SophiaHoomans';
Destination = fullfile(DataFolder, 'Results_Animalia');
if ~exist(Destination, 'dir')
    mkdir(Destination)
end


% time to keep
% TimeToKeep = [0.0001 60*60*1]; % in seconds
ScoringIndexes = -3:1;
ScoringLabels = {'N3', 'N2', 'N1', 'W', 'R'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run

Files = oscip.list_filenames(DataFolder);

%%% identify main oscillations in each recording
for FileIdx = 2 %1:numel(Files)

    File = Files(FileIdx);

    if exist(fullfile(Destination, File), 'file') && ~Refresh
        load(fullfile(Destination, File))
    else
        load(fullfile(DataFolder, File), 'EEG', 'visnum')

        Data = EEG.data;
        SampleRate = EEG.srate;
        Scoring = visnum;
        Scoring(Scoring==1) = 2;
        Scoring(Scoring==0) = 1;
        Scoring(Scoring==2) = 0;
        Scoring(end+1) = nan;

        % calculate power
        [EpochPower, Frequencies] = oscip.compute_power_on_epochs(Data, ...
            SampleRate, EpochLength, WelchWindowLength, WelchOverlap);

        SmoothPower = oscip.smooth_spectrum(EpochPower, Frequencies, SmoothSpan); % better for fooof if the spectra are smooth

        % run FOOOF
        [Slopes, Intercepts, FooofFrequencies, PeriodicPeaks, WhitenedPower, Errors, RSquared] ...
            = oscip.fit_fooof_multidimentional(SmoothPower, Frequencies, FooofFrequencyRange, MaxError, MinRSquared);

        save(fullfile(Destination, File), 'EEG', 'Scoring', 'ScoringIndexes', 'ScoringLabels', ...
            'SmoothPower', 'Frequencies', 'Slopes', 'Intercepts', ...
            'FooofFrequencies', 'PeriodicPeaks', 'WhitenedPower', 'Errors','RSquared')
    end

    
    % plot
    if PlotIndividuals
        Title = replace(replace(File, '.mat', ''), '_', ' ');
        FigureTitle = char(extractBefore(File, '.mat'));
        oscip.plot.temporal_overview(squeeze(mean(WhitenedPower,1)), ...
            FooofFrequencies, EpochLength, Scoring, ScoringIndexes, ScoringLabels, Slopes, [], [], Title)
        set(gcf, 'InvertHardcopy', 'off', 'Color', 'w')
        print(fullfile(Destination, [FigureTitle, '_time']), '-dtiff', '-r1000')

        oscip.plot.frequency_overview(SmoothPower, Frequencies, PeriodicPeaks, ...
            Scoring, ScoringIndexes, ScoringLabels, ScatterSizeScaling, Alpha, true, true)
        title(Title)
        set(gcf, 'InvertHardcopy', 'off', 'Color', 'w')
        print(fullfile(Destination, [FigureTitle, '_frequency']), '-dtiff', '-r1000')

        figure('Units','centimeters', 'Position',[0 0 10 15], 'Color','w')
        for ChannelIdx = 1:3
            subplot(3, 1, ChannelIdx)
            oscip.plot.histogram_stages(Slopes(ChannelIdx, :), Scoring, ScoringLabels, ScoringIndexes); title(num2str(ChannelIdx))
            xlim([0 4])
        end
        set(gcf, 'InvertHardcopy', 'off', 'Color', 'w')
        print(fullfile(Destination, [FigureTitle, '_slopes']), '-dtiff', '-r1000')
    end
end
