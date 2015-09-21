%% Chirp Unit Comparison
% Justaposes multiple PSTHs and SDFs for visual comparison in order to give clues for unit types 
% to cluster

% clear all, close all, clc;
%% Setup - Run startup file (if not done yet); connect to server first
startup

%% Load data
% load('/Volumes/lab/users/yannik/units_for_chirp_sorted.mat')
load('/Users/Yannik/Google Drive/SHARED Folders & Files/Academic/MATLAB gdrive/MATLAB HIWI/Miro scripts/units_for_chirp_sorted2.mat');

load('/Users/Yannik/Google Drive/SHARED Folders & Files/Academic/MATLAB gdrive/MATLAB HIWI/TrialSpikesExtra.mat');

%% Parameters
% Select units of interest
units = [1:4];

%% Sort units according to Quality Criterion
% This serves to check whether quality criteria values reflect the unit to the chirp responses visually
sortRanksum = true; 
sortQi = false;

if sortRanksum == true;
    [~, idx] = sort([units_for_chirp.ranksum]'); % find sorting index
    units_for_chirp = units_for_chirp(idx); % sort according to index
elseif sortQi == true;
    [~, idx] = sort([units_for_chirp.qi]'); % find sorting index
    units_for_chirp = units_for_chirp(idx); % sort according to index
end

count = 1; % loop-counter
fig = figure;
for unit = units;
    % get all spike times in TrialSpikeExtra as cell array
    spikeTimes = fetchn(data.TrialSpikesExtra(units_for_chirp_sorted(unit)),...
        'spike_times');
    
    spikeTimes = {MouseData.spike_times}';
    
    % Convert data format to fit plotSpikeRaster function format
    spikeTimes = cellfun(@transpose,spikeTimes,'un',0);
    nTrials = numel(spikeTimes);
        
    %% Chirp Stimulus    
    [chirpT, chirpY, onsetT] = plotChirpStim();
    
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
    ax(count) = subplot(length(units),1,count); % make as many subplots as units
    barH = bar(edges(1:end-1),spikeRates,'histc');
    set(barH, 'EdgeColor', 'none', 'FaceColor', [.7 .7 .7])
%     xlabel('Peristimulus time (s)');
    ylabel('Spike rate (Hz)');
%     title('Average spike rate as PSTH and SDF');
    infoTitle = strcat('Info: Mouse ', num2str(units_for_chirp_sorted(unit).mouse_counter),...
        ', Unit ', num2str(units_for_chirp_sorted(unit).unit_id),...
        ', Series ', num2str(units_for_chirp_sorted(unit).series_num),...
        ', Experiment ', num2str(units_for_chirp_sorted(unit).exp_num));
    title(infoTitle);
   
    % Draw onset times
    onsetT = repmat(onsetT',2);
    line(onsetT,[min(spikeRates), max(spikeRates)],'Color','r', 'LineStyle', '--');    
    hold on
    
    %% Spike Density Function (SDF) - overlaid onto PSTH
    
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
    fill([xi fliplr(xi)],...
        [sdfRateMean(1,:)+sdfRateSE(1,:) fliplr(sdfRateMean(1,:)-sdfRateSE(1,:))],...
        'b', 'facealpha', 0.25, 'EdgeColor', 'none');
    hold on
    % Plot sdf Mean
    plot(xi,sdfRateMean(1,:), 'Color', 'b', 'LineWidth', 1.5);
    hold off

    count = count+1; % update loop-counter
end
    %% adust overall plot
    xlabel('Peristimulus time (s)');
    set(ax, 'XTick', [0:5:ceil(max(chirpT))], 'XMinorTick','on',...
        'TickDir', 'out', 'box','off')
    linkaxes(ax,'x');
    xlim(ax(1),[0 max(onsetT(:,1))+1]);
