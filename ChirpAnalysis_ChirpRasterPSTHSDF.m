%% ChirpAnalysis_Chirp-Raster-PSTH-SDF
% Plots Chirp Stimulus, Raster Plot, PSTH & SDF as subplots into one figure

% clear all, close all, clc;
clear all;
%% Setup - Run startup file (if not done yet); connect to server first
startup_cin

%% Load data
% load('/Volumes/lab/users/yannik/units_for_chirp_sorted.mat')
% load('/Users/Yannik/Documents/MATLAB/HIWI/units_for_chirp_sorted')
load('/Users/Yannik/Google Drive/SHARED Folders & Files/Academic/MATLAB gdrive/MATLAB HIWI/Miro scripts/units_for_chirp_sorted2.mat')

% Select units of interest
units = [48];

for unit = units;
    % get all spike times in TrialSpikeExtra as cell array
    spikeTimes = fetchn(data.TrialSpikesExtra(units_for_chirp_sorted(unit)),...
        'spike_times');
    
    % Convert data format to fit plotSpikeRaster function format
    spikeTimes = cellfun(@transpose,spikeTimes,'un',0);
    
    %% Chirp Stimulus
    
    [chirpT, chirpY, onsetT] = plotChirpStim();
    
    % Create figure for Chirp, Raster Plot, PSTH and SDF - start with Chirp
    fig = figure;
    ax1 = subplot(4,1,1);
    plot(chirpT,chirpY)
%     title('Chirp Stimulus (presented as fullfield stimulus)')
    % xlabel('Peristimulus time (s)');
    ylabel('Intensity (a.u.)');
    set(ax1, 'XTick', [0:5:ceil(max(chirpT))], 'XMinorTick','on',...
        'XTickLabel', [],'TickDir', 'out', 'box','off');
    % Draw onset times
    onsetT = repmat(onsetT',2);
    line(onsetT,ax1.YLim,'Color','r', 'LineStyle', '--');
    
    %% Raster Plot
    
    % Draw Raster Plot using function plotSpikeRaster
    ax2 = subplot(4,1,2);
    spikeH = plotSpikeRaster(spikeTimes,'PlotType','vertline');
    % xlabel('Peristimulus time (s)');
    ylabel('Trial');
%     title('Spike Raster Plot')
    set(ax2, 'XTick', [0:5:ceil(max(chirpT))], 'XMinorTick','on',...
        'XTickLabel', [],'TickDir', 'out', 'box','off')
    
    % Draw onset times
    nTrials = numel(spikeTimes);
    lineH = line(onsetT,ax2.YLim,'Color','r', 'LineStyle', '--');
    
    %% PSTH
    
    % Parameters
    binWidth = 0.05; % 50 ms
    
    % Compute maximum bin edge (rather than merely hardcoding edges=0:0.05:35;)
    binMax = cellfun(@(x)max(x(:)), spikeTimes); % max time per trial
    binMaxAll = round(max(binMax(:)))+1; % overall max time of all trials
    edges = 0:binWidth:binMaxAll;
    
    % Compute counts for every trial, averages over trials and spike rate (Hz)
    for i = 1:numel(spikeTimes)
        [counts(i,:)] = histcounts(spikeTimes{i},edges); % counts
    end
    meanCounts = mean(counts); % averages per bin
    spikeRates = meanCounts*(1/binWidth); % spike rates (Hz)
    
    % Plot average spike rate PSTH for multiple trials
    ax3 = subplot(4,1,3);
    barH = bar(edges(1:end-1),spikeRates,'histc');
    set(barH, 'EdgeColor', 'none', 'FaceColor', 'k')
    % xlabel('Peristimulus time (s)');
    ylabel('Spike rate (Hz)');
%     title('Average spike rate PSTH');
    set(ax3, 'XTick', [0:5:ceil(max(chirpT))], 'XMinorTick','on',...
        'XTickLabel', [],'TickDir', 'out', 'box','off')
    % Draw onset times
    line(onsetT,ax3.YLim,'Color','r', 'LineStyle', '--');
    
    %% Spike Density Function (SDF)
    
    % Parameters
    kernelWidth = 0.040; % = 40 ms ??? Ad Hoc, THEORETICAL MOTIVATION ???
    pts = (0:0.005:binMaxAll); % evaluate at 5 ms resolution
    
    % Estimate probability density function (pdf) for each trial
    sdf = zeros(numel(spikeTimes), length(pts)); % Initialize for speed
    for i = 1:numel(spikeTimes)
        [sdf(i,:),xi,bw] = ksdensity(spikeTimes{i}, pts, 'bandwidth',kernelWidth);
    end
    
    % Calculate average and SD of pdf and convert into spike rates
    sdfMean = mean(sdf);
    sdfSE = std(sdf)/sqrt(nTrials);
    nSpikesAll = sum(sum(counts(:))); % Total spike count
    sdfRateMean = sdfMean * (nSpikesAll/nTrials); % Firing Rate (Hz)
    sdfRateSE = sdfSE * (nSpikesAll/nTrials);
    sdfRates = sdf * (nSpikesAll/nTrials); % Firing Rates of indiv trials (Hz)

    % Plot SDF
    ax4 = subplot(4,1,4);
%     for sdfTrial = 1:nTrials
%         plot(xi,sdfRates(sdfTrial,:), 'Color', [.5 .5 .5]);
%     hold on
%     end
    % Plot sdf SE area first
    fill([xi fliplr(xi)],...
        [sdfRateMean(1,:)+sdfRateSE(1,:) fliplr(sdfRateMean(1,:)-sdfRateSE(1,:))],...
        [.75 .75 1], 'EdgeColor', 'none');
    hold on
    % Plot sdf Mean
    plot(xi,sdfRateMean(1,:), 'Color', 'b', 'LineWidth', 1.5);
    hold off
    xlabel('Peristimulus time (s)');
    ylabel('Spike rate (Hz)');
%     title('Spike Density Function (SDF)')
    set(ax4, 'XTick', [0:5:ceil(max(chirpT))], 'XMinorTick','on',...
        'TickDir', 'out', 'box','off')

    % Draw onset times
    line(onsetT,ax4.YLim,'Color','r', 'LineStyle', '--');
    
    %% adust overall plot
    
    % Adjust axes and subplot spacing
    linkaxes([ax1,ax2,ax3,ax4],'x');
    xlim(ax1,[0 max(onsetT(:,1))+1]);    
    subplotSpace = 0.013;
    ax4.Position(2) = 0 + 0.07;
    ax3.Position(2) = ax4.Position(2) + ax4.Position(4) + subplotSpace;
    ax2.Position(2) = ax3.Position(2) + ax3.Position(4) + subplotSpace;
    ax1.Position(2) = ax2.Position(2) + ax2.Position(4) + subplotSpace;
    ax1.Position(4) = 0.075; % reduce height of chirp-stimulus plot
    
    % Use tightfig function to minimize figure window margins
    tightfig
    
    % Create Info panel: mouse, unit, series, experiment
    % NB: plot after using tightfig!
    infoTitle = strcat('Info: Mouse:', num2str(units_for_chirp_sorted(unit).mouse_counter),...
        ', Unit:', num2str(units_for_chirp_sorted(unit).unit_id),...
        ', Series:', num2str(units_for_chirp_sorted(unit).series_num),...
        ', Experiment:', num2str(units_for_chirp_sorted(unit).exp_num));
    axSupTitle = suptitle(infoTitle); 
    axSupTitle.Position(2) = -0.15; % lower supertitle
    
end

%% For figure export as pdf in correct size execute this code to update figure paper size
% Seems necessary after playing with window size which does not get updated
% for pdf export function
% 
% clear fig
% fig2 = get(gcf);

fig.Units = 'centimeters';
fig.PaperUnits = 'centimeters';
fig.PaperPosition = fig.Position;
fig.PaperSize = [fig.Position(3) fig.Position(4)];
fig.PaperOrientation = 'landscape';

