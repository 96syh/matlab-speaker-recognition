%% 不同信噪比条件下的说话人识别性能分析
% 测试系统在不同噪声环境下的鲁棒性
% 作者：AI Assistant
% 日期：2024

function snr_analysis(modelPath, dataPath)
    if nargin < 1
        modelPath = './car/optimized_speaker_model.mat';
    end
    if nargin < 2
        dataPath = './car';
    end
    
    clc;
    fprintf('=== 信噪比性能分析 ===\n');
    
    %% 加载模型
    try
        fprintf('加载模型...\n');
        modelStruct = load(modelPath);
        modelData = modelStruct.modelData;
        net = modelData.net;
        normParams = modelData.normParams;
        
        % 提取参数
        fs = modelData.fs;
        frameSize = modelData.frameSize;
        frameStep = modelData.frameStep;
        numCoeffs = modelData.numCoeffs;
        maxFrames = modelData.maxFrames;
        categories_list = modelData.categories;
        
        fprintf('✓ 模型加载成功\n');
    catch ME
        error('模型加载失败: %s', ME.message);
    end
    
    %% 定义测试信噪比范围
    snr_values = [-5, 0, 5, 10, 15, 20, 25, 30];  % dB
    noise_types = {'white', 'pink', 'brown', 'speech'};
    
    fprintf('测试配置:\n');
    fprintf('• SNR范围: %s dB\n', mat2str(snr_values));
    fprintf('• 噪声类型: %s\n', strjoin(noise_types, ', '));
    
    %% 准备干净测试数据
    fprintf('\n准备测试数据...\n');
    [cleanFeatures, testLabels, audioData] = prepareCleanTestData(dataPath, fs, frameSize, frameStep, numCoeffs, maxFrames);
    
    fprintf('✓ 测试数据准备完成: %d 个样本\n', length(testLabels));
    
    %% 执行不同SNR和噪声类型的测试
    results = struct();
    
    for noiseIdx = 1:length(noise_types)
        noiseType = noise_types{noiseIdx};
        fprintf('\n处理噪声类型: %s\n', noiseType);
        
        results.(noiseType) = struct();
        results.(noiseType).snr = snr_values;
        results.(noiseType).accuracy = zeros(size(snr_values));
        results.(noiseType).eer = zeros(size(snr_values));
        results.(noiseType).minDcf = zeros(size(snr_values));
        
        for snrIdx = 1:length(snr_values)
            snr = snr_values(snrIdx);
            fprintf('  测试SNR: %+3d dB...', snr);
            
            % 添加噪声并重新提取特征
            noisyFeatures = addNoiseToAudio(audioData, snr, noiseType, ...
                                            fs, frameSize, frameStep, numCoeffs, maxFrames);
            
            % 标准化特征
            noisyFeaturesNorm = applyNormalization(noisyFeatures, normParams);
            
            % 预测 - 兼容不同MATLAB版本
            try
                [predLabels, scores] = classify(net, noisyFeaturesNorm);
            catch
                predLabels = classify(net, noisyFeaturesNorm);
                scores = [];
            end
            
            predictedProbs = predict(net, noisyFeaturesNorm);
            
            % 计算性能指标
            accuracy = mean(predLabels == testLabels);
            [avgEER, avgDCF] = computeAverageMetrics(predictedProbs, testLabels, categories_list);
            
            % 存储结果
            results.(noiseType).accuracy(snrIdx) = accuracy;
            results.(noiseType).eer(snrIdx) = avgEER;
            results.(noiseType).minDcf(snrIdx) = avgDCF;
            
            fprintf(' 准确率: %.2f%%, EER: %.2f%%\n', accuracy*100, avgEER*100);
        end
    end
    
    %% 生成分析报告和可视化
    generateSNRReport(results, snr_values, noise_types);
    visualizeSNRResults(results, snr_values, noise_types);
    
    %% 保存结果
    resultsPath = fullfile(dataPath, 'snr_analysis_results.mat');
    save(resultsPath, 'results', 'snr_values', 'noise_types', '-v7.3');
    fprintf('\n结果已保存到: %s\n', resultsPath);
    
    fprintf('\n=== SNR分析完成 ===\n');
end

%% 准备干净的测试数据（保留原始音频）
function [features, labels, audioData] = prepareCleanTestData(dataPath, fs, frameSize, frameStep, numCoeffs, maxFrames)
    speakers = dir(dataPath);
    speakers = speakers([speakers.isdir] & ~ismember({speakers.name}, {'.','..'}));
    
    features = [];
    labels = {};
    audioData = {};
    
    for spkIdx = 1:numel(speakers)
        speaker = speakers(spkIdx).name;
        audioFiles = dir(fullfile(dataPath, speaker, '*.wav'));
        
        % 每个说话人选择5个测试文件
        numTest = min(5, length(audioFiles));
        testIdx = randperm(length(audioFiles), numTest);
        
        for i = 1:numTest
            filePath = fullfile(audioFiles(testIdx(i)).folder, audioFiles(testIdx(i)).name);
            
            try
                [audio, fs_read] = audioread(filePath);
                if fs_read ~= fs
                    audio = resample(audio, fs, fs_read);
                end
                
                % 音频预处理
                audio = preprocessAudio(audio);
                
                % 存储原始音频数据
                audioData{end+1} = audio;
                
                % 提取干净特征
                mfcc = extractAdvancedMFCC(audio, fs, frameSize, frameStep, numCoeffs, maxFrames);
                features = cat(4, features, reshape(mfcc, [numCoeffs, maxFrames, 1, 1]));
                labels{end+1} = speaker;
                
            catch ME
                warning('文件处理失败: %s', ME.message);
            end
        end
    end
    
    labels = categorical(labels);
end

%% 为音频添加不同类型的噪声
function noisyFeatures = addNoiseToAudio(audioData, targetSNR, noiseType, fs, frameSize, frameStep, numCoeffs, maxFrames)
    numSamples = length(audioData);
    noisyFeatures = [];
    
    for i = 1:numSamples
        audio = audioData{i};
        
        % 生成噪声
        switch lower(noiseType)
            case 'white'
                noise = randn(size(audio));
                
            case 'pink'
                noise = generatePinkNoise(length(audio));
                
            case 'brown'
                noise = generateBrownNoise(length(audio));
                
            case 'speech'
                noise = generateSpeechNoise(length(audio), fs);
                
            otherwise
                noise = randn(size(audio));
        end
        
        % 计算音频和噪声的功率
        signalPower = mean(audio.^2);
        noisePower = mean(noise.^2);
        
        % 根据目标SNR调整噪声幅度
        targetNoisePower = signalPower / (10^(targetSNR/10));
        noiseScale = sqrt(targetNoisePower / noisePower);
        scaledNoise = noise * noiseScale;
        
        % 添加噪声
        noisyAudio = audio + scaledNoise;
        
        % 归一化防止剪切
        maxVal = max(abs(noisyAudio));
        if maxVal > 0.95
            noisyAudio = noisyAudio * 0.95 / maxVal;
        end
        
        % 提取噪声音频的特征
        mfcc = extractAdvancedMFCC(noisyAudio, fs, frameSize, frameStep, numCoeffs, maxFrames);
        noisyFeatures = cat(4, noisyFeatures, reshape(mfcc, [numCoeffs, maxFrames, 1, 1]));
    end
end

%% 生成粉红噪声
function noise = generatePinkNoise(N)
    % 生成粉红噪声 (1/f 噪声)
    white = randn(N, 1);
    
    % 设计1/f滤波器
    b = [0.049922035, -0.095993537, 0.050612699, -0.004408786];
    a = [1, -2.494956002, 2.017265875, -0.522189400];
    
    % 滤波
    noise = filter(b, a, white);
    
    % 归一化
    noise = noise / std(noise);
end

%% 生成棕色噪声
function noise = generateBrownNoise(N)
    % 生成棕色噪声 (1/f^2 噪声)
    white = randn(N, 1);
    
    % 积分滤波器近似
    noise = cumsum(white);
    
    % 去直流并归一化
    noise = noise - mean(noise);
    noise = noise / std(noise);
end

%% 生成语音噪声
function noise = generateSpeechNoise(N, fs)
    % 生成语音样噪声（多个正弦波的叠加）
    t = (0:N-1)' / fs;
    
    % 语音频率范围内的多个频率分量
    frequencies = [200, 400, 600, 800, 1000, 1200, 1600, 2000, 2400, 3200];
    noise = zeros(N, 1);
    
    for f = frequencies
        amplitude = 1/sqrt(f);  % 1/f幅度特性
        phase = 2*pi*rand();    % 随机相位
        noise = noise + amplitude * sin(2*pi*f*t + phase);
    end
    
    % 添加随机调制
    modulation = 1 + 0.3 * sin(2*pi*5*t);  % 5Hz调制
    noise = noise .* modulation;
    
    % 归一化
    noise = noise / std(noise);
end

%% 计算平均性能指标
function [avgEER, avgDCF] = computeAverageMetrics(scores, trueLabels, categories_list)
    numClasses = length(categories_list);
    eerValues = zeros(numClasses, 1);
    dcfValues = zeros(numClasses, 1);
    
    for i = 1:numClasses
        speaker = categories_list{i};
        
        % 二元分类
        binaryLabels = double(trueLabels == speaker);
        speakerScores = scores(:, i);
        
        % 计算EER
        eerValues(i) = computeEER_simple(speakerScores, binaryLabels);
        
        % 计算minDCF
        dcfValues(i) = computeMinDCF_simple(speakerScores, binaryLabels);
    end
    
    avgEER = mean(eerValues);
    avgDCF = mean(dcfValues);
end

%% 简化的EER计算
function eer = computeEER_simple(scores, labels)
    thresholds = linspace(min(scores), max(scores), 200);
    
    far = zeros(size(thresholds));
    frr = zeros(size(thresholds));
    
    for i = 1:length(thresholds)
        threshold = thresholds(i);
        predictions = scores >= threshold;
        
        tp = sum(predictions & labels);
        fp = sum(predictions & ~labels);
        tn = sum(~predictions & ~labels);
        fn = sum(~predictions & labels);
        
        far(i) = fp / max(fp + tn, eps);
        frr(i) = fn / max(fn + tp, eps);
    end
    
    [~, eerIdx] = min(abs(far - frr));
    eer = (far(eerIdx) + frr(eerIdx)) / 2;
end

%% 简化的minDCF计算
function minDcf = computeMinDCF_simple(scores, labels)
    p_target = 0.01;
    c_miss = 1;
    c_fa = 1;
    
    thresholds = linspace(min(scores), max(scores), 200);
    dcf = zeros(size(thresholds));
    
    for i = 1:length(thresholds)
        threshold = thresholds(i);
        predictions = scores >= threshold;
        
        tp = sum(predictions & labels);
        fp = sum(predictions & ~labels);
        tn = sum(~predictions & ~labels);
        fn = sum(~predictions & labels);
        
        far = fp / max(fp + tn, eps);
        frr = fn / max(fn + tp, eps);
        
        dcf(i) = p_target * c_miss * frr + (1 - p_target) * c_fa * far;
    end
    
    minDcf = min(dcf);
end

%% 生成SNR分析报告
function generateSNRReport(results, snr_values, noise_types)
    fprintf('\n╔════════════════════════════════════════════════════════════╗\n');
    fprintf('║                    SNR性能分析报告                        ║\n');
    fprintf('╠════════════════════════════════════════════════════════════╣\n');
    
    for noiseIdx = 1:length(noise_types)
        noiseType = noise_types{noiseIdx};
        fprintf('║ %s噪声环境下的性能表现:%s║\n', upper(noiseType), repmat(' ', 1, 39-length(noiseType)));
        fprintf('║ SNR(dB) │ 准确率(%%) │  EER(%%)  │ minDCF   │            ║\n');
        fprintf('║─────────┼──────────┼─────────┼─────────┼────────────║\n');
        
        for i = 1:length(snr_values)
            snr = snr_values(i);
            acc = results.(noiseType).accuracy(i) * 100;
            eer = results.(noiseType).eer(i) * 100;
            dcf = results.(noiseType).minDcf(i);
            
            fprintf('║  %+3d    │  %6.2f  │  %5.2f  │ %6.4f  │            ║\n', ...
                    snr, acc, eer, dcf);
        end
        fprintf('║                                                            ║\n');
    end
    
    % 性能汇总
    fprintf('║ 性能汇总分析:                                              ║\n');
    
    % 找到最佳和最差SNR条件
    allAccuracies = [];
    for noiseIdx = 1:length(noise_types)
        allAccuracies = [allAccuracies, results.(noise_types{noiseIdx}).accuracy];
    end
    
    [maxAcc, maxIdx] = max(allAccuracies);
    [minAcc, minIdx] = min(allAccuracies);
    
    fprintf('║ • 最佳条件: SNR=%+3ddB, 准确率=%.2f%%                      ║\n', ...
            snr_values(mod(maxIdx-1, length(snr_values))+1), maxAcc*100);
    fprintf('║ • 最差条件: SNR=%+3ddB, 准确率=%.2f%%                      ║\n', ...
            snr_values(mod(minIdx-1, length(snr_values))+1), minAcc*100);
    
    % 鲁棒性分析
    accRange = max(allAccuracies) - min(allAccuracies);
    fprintf('║ • 准确率变化范围: %.2f%% (鲁棒性指标)                      ║\n', accRange*100);
    
    % SNR阈值分析
    threshold_90 = findSNRThreshold(results, snr_values, noise_types, 0.90);
    fprintf('║ • 90%%准确率所需最低SNR: 约%+3ddB                          ║\n', threshold_90);
    
    fprintf('╚════════════════════════════════════════════════════════════╝\n');
end

%% 查找达到指定准确率的SNR阈值
function snr_threshold = findSNRThreshold(results, snr_values, noise_types, target_accuracy)
    min_snr = inf;
    
    for noiseIdx = 1:length(noise_types)
        noiseType = noise_types{noiseIdx};
        accuracies = results.(noiseType).accuracy;
        
        % 找到第一个超过目标准确率的SNR
        idx = find(accuracies >= target_accuracy, 1, 'first');
        if ~isempty(idx)
            min_snr = min(min_snr, snr_values(idx));
        end
    end
    
    if isinf(min_snr)
        snr_threshold = max(snr_values);  % 如果没有达到目标，返回最高SNR
    else
        snr_threshold = min_snr;
    end
end

%% 可视化SNR分析结果
function visualizeSNRResults(results, snr_values, noise_types)
    figure('Position', [100, 100, 1400, 1000], 'Name', 'SNR性能分析');
    
    colors = lines(length(noise_types));
    markers = {'o', 's', '^', 'd'};
    
    % 1. 准确率 vs SNR
    subplot(2, 2, 1);
    hold on;
    for i = 1:length(noise_types)
        noiseType = noise_types{i};
        plot(snr_values, results.(noiseType).accuracy * 100, ...
             'Color', colors(i,:), 'Marker', markers{i}, 'LineWidth', 2, ...
             'MarkerSize', 8, 'DisplayName', [upper(noiseType) '噪声']);
    end
    
    xlabel('SNR (dB)');
    ylabel('识别准确率 (%)');
    title('不同噪声条件下的识别准确率');
    legend('Location', 'best');
    grid on;
    ylim([0, 100]);
    
    % 添加90%和95%准确率参考线
    plot(xlim, [90, 90], 'r--', 'DisplayName', '90%基准');
    plot(xlim, [95, 95], 'g--', 'DisplayName', '95%目标');
    
    % 2. EER vs SNR
    subplot(2, 2, 2);
    hold on;
    for i = 1:length(noise_types)
        noiseType = noise_types{i};
        plot(snr_values, results.(noiseType).eer * 100, ...
             'Color', colors(i,:), 'Marker', markers{i}, 'LineWidth', 2, ...
             'MarkerSize', 8, 'DisplayName', [upper(noiseType) '噪声']);
    end
    
    xlabel('SNR (dB)');
    ylabel('等错误率 EER (%)');
    title('不同噪声条件下的EER');
    legend('Location', 'best');
    grid on;
    set(gca, 'YScale', 'log');
    
    % 3. minDCF vs SNR
    subplot(2, 2, 3);
    hold on;
    for i = 1:length(noise_types)
        noiseType = noise_types{i};
        plot(snr_values, results.(noiseType).minDcf, ...
             'Color', colors(i,:), 'Marker', markers{i}, 'LineWidth', 2, ...
             'MarkerSize', 8, 'DisplayName', [upper(noiseType) '噪声']);
    end
    
    xlabel('SNR (dB)');
    ylabel('最小检测代价 minDCF');
    title('不同噪声条件下的minDCF');
    legend('Location', 'best');
    grid on;
    
    % 4. 性能对比热图
    subplot(2, 2, 4);
    
    % 创建性能矩阵 (噪声类型 x SNR)
    perfMatrix = zeros(length(noise_types), length(snr_values));
    for i = 1:length(noise_types)
        perfMatrix(i, :) = results.(noise_types{i}).accuracy * 100;
    end
    
    imagesc(snr_values, 1:length(noise_types), perfMatrix);
    colormap('parula');
    colorbar;
    
    % 添加数值标注
    for i = 1:length(noise_types)
        for j = 1:length(snr_values)
            text(snr_values(j), i, sprintf('%.1f', perfMatrix(i, j)), ...
                 'HorizontalAlignment', 'center', 'Color', 'white', ...
                 'FontWeight', 'bold');
        end
    end
    
    xlabel('SNR (dB)');
    ylabel('噪声类型');
    title('识别准确率热图 (%)');
    yticks(1:length(noise_types));
    yticklabels(upper(noise_types));
    
    sgtitle('说话人识别系统 - SNR鲁棒性分析', 'FontSize', 16, 'FontWeight', 'bold');
    
    % 保存图表
    saveas(gcf, 'snr_analysis_results.png');
    fprintf('SNR分析图表已保存为: snr_analysis_results.png\n');
    
    % 创建详细的性能趋势图
    figure('Position', [150, 150, 1200, 400], 'Name', 'SNR性能趋势');
    
    subplot(1, 3, 1);
    plot(snr_values, mean(perfMatrix, 1), 'b-o', 'LineWidth', 3, 'MarkerSize', 8);
    xlabel('SNR (dB)');
    ylabel('平均准确率 (%)');
    title('平均性能趋势');
    grid on;
    ylim([0, 100]);
    
    subplot(1, 3, 2);
    errorbar(snr_values, mean(perfMatrix, 1), std(perfMatrix, 0, 1), ...
             'b-o', 'LineWidth', 2, 'MarkerSize', 6);
    xlabel('SNR (dB)');
    ylabel('准确率 (%)');
    title('性能变异性分析');
    grid on;
    ylim([0, 100]);
    
    subplot(1, 3, 3);
    bar(snr_values, std(perfMatrix, 0, 1));
    xlabel('SNR (dB)');
    ylabel('标准差 (%)');
    title('不同SNR下的性能稳定性');
    grid on;
    
    sgtitle('性能稳定性分析', 'FontSize', 14, 'FontWeight', 'bold');
    
    saveas(gcf, 'snr_performance_trend.png');
    fprintf('性能趋势图已保存为: snr_performance_trend.png\n');
end

%% 复用函数
function audio = preprocessAudio(audio)
    audio = audio - mean(audio);
    preEmphasis = 0.97;
    audio = filter([1 -preEmphasis], 1, audio);
    if max(abs(audio)) > 0
        audio = audio / max(abs(audio)) * 0.95;
    end
end

function mfccs = extractAdvancedMFCC(audio, fs, frameSize, frameStep, numCoeffs, maxFrames)
    basicMfcc = extractBasicMFCC(audio, fs, frameSize, frameStep, 13, maxFrames);
    deltaMfcc = computeDelta(basicMfcc);
    deltaDeltaMfcc = computeDelta(deltaMfcc);
    mfccs = [basicMfcc; deltaMfcc; deltaDeltaMfcc];
    
    if size(mfccs, 1) ~= numCoeffs
        mfccs = mfccs(1:min(numCoeffs, size(mfccs, 1)), :);
        if size(mfccs, 1) < numCoeffs
            mfccs = [mfccs; zeros(numCoeffs - size(mfccs, 1), size(mfccs, 2))];
        end
    end
    
    if size(mfccs, 2) ~= maxFrames
        if size(mfccs, 2) > maxFrames
            mfccs = mfccs(:, 1:maxFrames);
        else
            mfccs = [mfccs, zeros(size(mfccs, 1), maxFrames - size(mfccs, 2))];
        end
    end
end

function mfccs = extractBasicMFCC(audio, fs, frameSize, frameStep, numCoeffs, maxFrames)
    frameLen = round(frameSize * fs);
    stepLen = round(frameStep * fs);
    numFrames = floor((length(audio) - frameLen) / stepLen) + 1;
    
    if numFrames < 1
        mfccs = zeros(numCoeffs, maxFrames);
        return;
    end
    
    frames = zeros(frameLen, numFrames);
    for i = 1:numFrames
        startIdx = (i-1) * stepLen + 1;
        endIdx = min(startIdx + frameLen - 1, length(audio));
        frames(1:(endIdx-startIdx+1), i) = audio(startIdx:endIdx);
    end
    
    window = hamming(frameLen);
    frames = frames .* window;
    
    NFFT = 2^nextpow2(frameLen);
    magFFT = abs(fft(frames, NFFT));
    
    numFilters = 26;
    melFilter = createMelFilterBank(fs, NFFT, numFilters);
    
    filterOut = melFilter * magFFT(1:NFFT/2+1, :);
    filterOut = max(filterOut, eps);
    
    mfccs = dct(log(filterOut));
    mfccs = mfccs(1:numCoeffs, :);
    
    if size(mfccs, 2) > maxFrames
        mfccs = mfccs(:, 1:maxFrames);
    else
        mfccs = [mfccs, zeros(numCoeffs, maxFrames - size(mfccs, 2))];
    end
end

function delta = computeDelta(features)
    [numCoeffs, numFrames] = size(features);
    delta = zeros(numCoeffs, numFrames);
    
    for t = 1:numFrames
        if t == 1
            delta(:, t) = features(:, 2) - features(:, 1);
        elseif t == numFrames
            delta(:, t) = features(:, numFrames) - features(:, numFrames-1);
        else
            delta(:, t) = (features(:, t+1) - features(:, t-1)) / 2;
        end
    end
end

function melFilter = createMelFilterBank(fs, NFFT, numFilters)
    lowFreq = 80;
    highFreq = fs / 2;
    
    lowMel = 2595 * log10(1 + lowFreq / 700);
    highMel = 2595 * log10(1 + highFreq / 700);
    
    melPoints = linspace(lowMel, highMel, numFilters + 2);
    hzPoints = 700 * (10.^(melPoints / 2595) - 1);
    
    bin = floor((NFFT + 1) * hzPoints / fs);
    
    melFilter = zeros(numFilters, NFFT/2 + 1);
    
    for m = 1:numFilters
        left = bin(m);
        center = bin(m + 1);
        right = bin(m + 2);
        
        for k = left:center
            if center > left
                melFilter(m, k + 1) = (k - left) / (center - left);
            end
        end
        
        for k = center:right
            if right > center
                melFilter(m, k + 1) = (right - k) / (right - center);
            end
        end
    end
end

function normalizedData = applyNormalization(data, params)
    [numCoeffs, numFrames, numChannels, numSamples] = size(data);
    normalizedData = data;
    
    for i = 1:numSamples
        sample = reshape(data(:, :, :, i), [], 1);
        normalizedSample = (sample - params.mean) ./ max(params.std, eps);
        normalizedData(:, :, :, i) = reshape(normalizedSample, numCoeffs, numFrames, numChannels);
    end
end 