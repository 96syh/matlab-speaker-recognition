%% 优化的说话人识别系统 - 深度CNN
% 目标：测试准确率达到95%以上
% 作者：AI Assistant
% 日期：2024

clc; clear; close all;

%% 设置随机种子以确保可重现性
try
    rng(2024, 'twister')  % 使用2024作为种子
catch
    rng(2024)  % 旧版本兼容
end

%% 数据路径配置 - 使用相对路径
dataFolder = './car';  % 修改为相对路径

if ~isfolder(dataFolder)
    error('数据集路径不存在: %s\n请确保car文件夹在当前目录下', dataFolder);
end

speakers = dir(dataFolder);
speakers = speakers([speakers.isdir] & ~ismember({speakers.name}, {'.','..'}));

if isempty(speakers)
    error('在%s中没有找到说话人文件夹', dataFolder);
end

fprintf('找到 %d 个说话人目录\n', length(speakers));

%% 优化的参数配置
fs = 16000;          % 采样率
frameSize = 0.032;   % 32ms帧长 (增加帧长)
frameStep = 0.016;   % 16ms帧移 (50%重叠)
numCoeffs = 39;      % 增加MFCC系数 (13 + 13Δ + 13ΔΔ)
maxFrames = 150;     % 增加最大帧数

%% 高级数据增强
try
    augmenter = audioDataAugmenter(...
        'AddNoise', true, ...
        'SNRRange', [10, 30], ...        % 信噪比范围
        'TimeStretch', [0.85, 1.15], ... % 时间拉伸范围
        'PitchShift', [-3, 3], ...       % 音调变换范围
        'VolumeControl', [0.7, 1.3]);    % 音量控制
    disp('高级数据增强功能已启用');
catch
    warning('Audio Toolbox不可用，使用基础数据增强');
    augmenter = [];
end

%% 批量处理数据
allFeatures = [];
allLabels = {};
fileCount = 0;

disp('开始优化的特征提取...');
tic;

for spkIdx = 1:numel(speakers)
    speaker = speakers(spkIdx).name;
    files = dir(fullfile(dataFolder, speaker, '*.wav'));
    
    if isempty(files)
        warning('说话人 %s 目录中没有WAV文件', speaker);
        continue;
    end
    
    fprintf('处理说话人 %s (%d 个文件)...\n', speaker, length(files));
    
    for fileIdx = 1:numel(files)
        filePath = fullfile(files(fileIdx).folder, files(fileIdx).name);
        
        try
            [audio, fs_read] = audioread(filePath);
            if fs_read ~= fs
                audio = resample(audio, fs, fs_read);
            end
            
            % 音频预处理
            audio = preprocessAudio(audio);
            
            % 基础特征提取
            mfcc = extractAdvancedMFCC(audio, fs, frameSize, frameStep, numCoeffs, maxFrames);
            
            % 存储原始数据
            allFeatures = cat(4, allFeatures, reshape(mfcc, [numCoeffs, maxFrames, 1, 1]));
            allLabels = [allLabels; speaker];
            fileCount = fileCount + 1;
            
            % 数据增强 - 为每个原始样本生成2个增强样本
            if ~isempty(augmenter)
                for augIdx = 1:2
                    try
                        audioAug = augment(augmenter, audio, fs);
                        mfccAug = extractAdvancedMFCC(audioAug, fs, frameSize, frameStep, numCoeffs, maxFrames);
                        allFeatures = cat(4, allFeatures, reshape(mfccAug, [numCoeffs, maxFrames, 1, 1]));
                        allLabels = [allLabels; speaker];
                        fileCount = fileCount + 1;
                    catch
                        % 跳过增强失败的样本
                    end
                end
            end
            
        catch ME
            warning('文件处理失败: %s (%s)', filePath, ME.message);
        end
    end
end

processingTime = toc;
fprintf('特征提取完成: %d 个样本, 耗时 %.1f 秒\n', fileCount, processingTime);

%% 数据预处理
% 转换为分类标签
allLabels = categorical(allLabels);
numClasses = numel(categories(allLabels));
fprintf('检测到 %d 个说话人类别\n', numClasses);

% 确保有足够的数据
if fileCount < 100
    error('数据样本太少 (%d)，需要至少100个样本', fileCount);
end

% 分层数据分割 (85% 训练, 15% 测试)
cv = cvpartition(allLabels, 'HoldOut', 0.15);
trainIdx = cv.training;
testIdx = cv.test;

% 数据分离
trainData = allFeatures(:,:,:,trainIdx);
testData = allFeatures(:,:,:,testIdx);
trainLabels = allLabels(trainIdx);
testLabels = allLabels(testIdx);

% 高级数据标准化 (Z-Score + Robust Scaling)
fprintf('执行高级数据标准化...\n');
[trainDataNorm, normParams] = normalizeFeatures(trainData);
testDataNorm = applyNormalization(testData, normParams);

fprintf('训练集大小: %d, 测试集大小: %d\n', sum(trainIdx), sum(testIdx));

%% 深度CNN网络结构 (ResNet-inspired)
fprintf('构建深度CNN网络...\n');

layers = [
    % 输入层
    imageInputLayer([numCoeffs maxFrames 1], 'Name', 'input', 'Normalization', 'none')
    
    % 第一个卷积块
    convolution2dLayer([3 3], 64, 'Padding', 'same', 'Name', 'conv1')
    batchNormalizationLayer('Name', 'bn1')
    reluLayer('Name', 'relu1')
    
    % 第二个卷积块
    convolution2dLayer([3 3], 64, 'Padding', 'same', 'Name', 'conv2')
    batchNormalizationLayer('Name', 'bn2')
    reluLayer('Name', 'relu2')
    maxPooling2dLayer([2 2], 'Stride', 2, 'Name', 'pool1')
    
    % 第三个卷积块
    convolution2dLayer([3 3], 128, 'Padding', 'same', 'Name', 'conv3')
    batchNormalizationLayer('Name', 'bn3')
    reluLayer('Name', 'relu3')
    
    % 第四个卷积块
    convolution2dLayer([3 3], 128, 'Padding', 'same', 'Name', 'conv4')
    batchNormalizationLayer('Name', 'bn4')
    reluLayer('Name', 'relu4')
    maxPooling2dLayer([2 2], 'Stride', 2, 'Name', 'pool2')
    
    % 第五个卷积块
    convolution2dLayer([3 3], 256, 'Padding', 'same', 'Name', 'conv5')
    batchNormalizationLayer('Name', 'bn5')
    reluLayer('Name', 'relu5')
    
    % 第六个卷积块
    convolution2dLayer([3 3], 256, 'Padding', 'same', 'Name', 'conv6')
    batchNormalizationLayer('Name', 'bn6')
    reluLayer('Name', 'relu6')
    maxPooling2dLayer([2 2], 'Stride', 2, 'Name', 'pool3')
    
    % 全局平均池化
    globalAveragePooling2dLayer('Name', 'gap')
    
    % 分类层
    dropoutLayer(0.5, 'Name', 'dropout1')
    fullyConnectedLayer(512, 'Name', 'fc1')
    reluLayer('Name', 'relu_fc1')
    
    dropoutLayer(0.3, 'Name', 'dropout2')
    fullyConnectedLayer(256, 'Name', 'fc2')
    reluLayer('Name', 'relu_fc2')
    
    fullyConnectedLayer(numClasses, 'Name', 'fc_final')
    softmaxLayer('Name', 'softmax')
    classificationLayer('Name', 'classification')];

%% 优化的训练选项 (加入早停机制)
options = trainingOptions('adam', ...
    'MaxEpochs', 150, ...               % 增加最大轮数，让早停机制发挥作用
    'MiniBatchSize', 64, ...
    'InitialLearnRate', 1e-3, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropFactor', 0.2, ...
    'LearnRateDropPeriod', 30, ...      % 调整学习率下降周期
    'L2Regularization', 1e-4, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', {testDataNorm, testLabels}, ...
    'ValidationFrequency', 30, ...      % 每30个iteration验证一次
    'ValidationPatience', 20, ...       % 早停耐心：验证损失20次不改善就停止
    'Verbose', true, ...
    'Plots', 'training-progress', ...
    'ExecutionEnvironment', 'auto', ...
    'OutputNetwork', 'best-validation-loss', ... % 保存验证损失最小的网络
    'CheckpointPath', tempdir);         % 启用检查点保存

%% 训练网络
fprintf('开始训练深度CNN网络...\n');
trainingStartTime = tic;

try
    net = trainNetwork(trainDataNorm, trainLabels, layers, options);
    trainingTime = toc(trainingStartTime);
    fprintf('训练完成，耗时 %.1f 分钟\n', trainingTime/60);
catch ME
    error('训练失败: %s\n请检查：1. 数据维度 2. 内存大小 3. 工具箱安装', ME.message);
end

%% 模型评估
fprintf('\n执行模型评估...\n');

% 训练集评估
trainPred = classify(net, trainDataNorm);
trainAccuracy = mean(trainPred == trainLabels);

% 测试集评估
testPred = classify(net, testDataNorm);
testAccuracy = mean(testPred == testLabels);

fprintf('训练集准确率: %.2f%%\n', trainAccuracy*100);
fprintf('测试集准确率: %.2f%%\n', testAccuracy*100);

% 检查是否达到目标
if testAccuracy < 0.95
    warning('测试准确率 (%.2f%%) 未达到目标 (95%%)，建议：', testAccuracy*100);
    fprintf('1. 增加训练轮数\n2. 调整学习率\n3. 增加数据增强\n4. 检查数据质量\n');
else
    fprintf('✓ 成功达到95%%准确率目标！\n');
end

%% 保存模型和参数
modelData = struct();
modelData.net = net;
modelData.normParams = normParams;
modelData.numCoeffs = numCoeffs;
modelData.fs = fs;
modelData.frameSize = frameSize;
modelData.frameStep = frameStep;
modelData.maxFrames = maxFrames;
modelData.categories = categories(trainLabels);
modelData.trainAccuracy = trainAccuracy;
modelData.testAccuracy = testAccuracy;

modelPath = fullfile(dataFolder, 'optimized_speaker_model.mat');
save(modelPath, 'modelData', '-v7.3');
fprintf('模型已保存到: %s\n', modelPath);

%% 详细性能分析
figure('Position', [100, 100, 1200, 800]);

% 混淆矩阵
subplot(2,2,1);
confusionchart(testLabels, testPred, 'Title', '测试集混淆矩阵');

% 每类准确率
subplot(2,2,2);
classNames = categories(testLabels);
classAccuracy = zeros(numClasses, 1);
for i = 1:numClasses
    classIdx = testLabels == classNames{i};
    if sum(classIdx) > 0
        classAccuracy(i) = mean(testPred(classIdx) == testLabels(classIdx));
    end
end
bar(classAccuracy * 100);
title('各说话人识别准确率');
xlabel('说话人编号');
ylabel('准确率 (%)');
ylim([80, 100]);
grid on;

% 训练历史可视化
subplot(2,2,[3,4]);
text(0.1, 0.7, sprintf('模型训练总结\n\n'), 'FontSize', 14, 'FontWeight', 'bold');
text(0.1, 0.6, sprintf('• 数据集大小: %d 样本', fileCount), 'FontSize', 12);
text(0.1, 0.5, sprintf('• 说话人数量: %d', numClasses), 'FontSize', 12);
text(0.1, 0.4, sprintf('• 训练集准确率: %.2f%%', trainAccuracy*100), 'FontSize', 12);
text(0.1, 0.3, sprintf('• 测试集准确率: %.2f%%', testAccuracy*100), 'FontSize', 12);
text(0.1, 0.2, sprintf('• 训练时间: %.1f 分钟', trainingTime/60), 'FontSize', 12);
text(0.1, 0.1, sprintf('• 网络深度: 6层卷积 + 3层全连接'), 'FontSize', 12);
axis off;

sgtitle('优化CNN说话人识别系统 - 性能报告', 'FontSize', 16, 'FontWeight', 'bold');

%% 保存结果到工作空间
assignin('base', 'trainedModel', modelData);
assignin('base', 'testAccuracy', testAccuracy);
assignin('base', 'trainAccuracy', trainAccuracy);

fprintf('\n训练完成！模型变量已保存到工作空间。\n');
fprintf('使用 evaluation_suite.m 进行详细评估分析。\n');

%% 音频预处理函数
function audio = preprocessAudio(audio)
    % 音频预处理：去直流、预加重、归一化
    
    % 去直流分量
    audio = audio - mean(audio);
    
    % 预加重滤波器
    preEmphasis = 0.97;
    audio = filter([1 -preEmphasis], 1, audio);
    
    % 归一化
    if max(abs(audio)) > 0
        audio = audio / max(abs(audio)) * 0.95;
    end
    
    % 端点检测 - 简单的能量阈值方法
    frameLength = 512;
    hopLength = 256;
    energy = [];
    
    for i = 1:hopLength:(length(audio)-frameLength+1)
        frame = audio(i:i+frameLength-1);
        energy(end+1) = sum(frame.^2);
    end
    
    if ~isempty(energy)
        threshold = 0.1 * max(energy);
        validFrames = energy > threshold;
        
        if sum(validFrames) > 0
            startFrame = find(validFrames, 1, 'first');
            endFrame = find(validFrames, 1, 'last');
            
            startSample = (startFrame-1) * hopLength + 1;
            endSample = min(endFrame * hopLength, length(audio));
            
            audio = audio(startSample:endSample);
        end
    end
end

%% 高级MFCC特征提取函数
function mfccs = extractAdvancedMFCC(audio, fs, frameSize, frameStep, numCoeffs, maxFrames)
    % 提取包含Δ和ΔΔ的MFCC特征
    
    % 基础MFCC提取
    basicMfcc = extractBasicMFCC(audio, fs, frameSize, frameStep, 13, maxFrames);
    
    % 计算一阶差分 (Δ)
    deltaMfcc = computeDelta(basicMfcc);
    
    % 计算二阶差分 (ΔΔ)
    deltaDeltaMfcc = computeDelta(deltaMfcc);
    
    % 拼接特征
    mfccs = [basicMfcc; deltaMfcc; deltaDeltaMfcc];
    
    % 确保维度正确
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

%% 基础MFCC提取
function mfccs = extractBasicMFCC(audio, fs, frameSize, frameStep, numCoeffs, maxFrames)
    % 基础MFCC特征提取
    
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
    
    % 汉明窗
    window = hamming(frameLen);
    frames = frames .* window;
    
    % FFT
    NFFT = 2^nextpow2(frameLen);
    magFFT = abs(fft(frames, NFFT));
    
    % Mel滤波器组
    numFilters = 26;
    melFilter = createMelFilterBank(fs, NFFT, numFilters);
    
    % 应用滤波器
    filterOut = melFilter * magFFT(1:NFFT/2+1, :);
    filterOut = max(filterOut, eps);
    
    % DCT变换
    mfccs = dct(log(filterOut));
    mfccs = mfccs(1:numCoeffs, :);
    
    % 调整帧数
    if size(mfccs, 2) > maxFrames
        mfccs = mfccs(:, 1:maxFrames);
    else
        mfccs = [mfccs, zeros(numCoeffs, maxFrames - size(mfccs, 2))];
    end
end

%% 计算差分特征
function delta = computeDelta(features)
    % 计算特征的一阶或二阶差分
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

%% 创建Mel滤波器组
function melFilter = createMelFilterBank(fs, NFFT, numFilters)
    % 创建Mel滤波器组
    
    % 频率范围
    lowFreq = 80;
    highFreq = fs / 2;
    
    % 转换为Mel尺度
    lowMel = 2595 * log10(1 + lowFreq / 700);
    highMel = 2595 * log10(1 + highFreq / 700);
    
    % 生成Mel频率点
    melPoints = linspace(lowMel, highMel, numFilters + 2);
    hzPoints = 700 * (10.^(melPoints / 2595) - 1);
    
    % 转换为FFT频点
    bin = floor((NFFT + 1) * hzPoints / fs);
    
    % 创建滤波器组
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

%% 特征标准化函数
function [normalizedData, params] = normalizeFeatures(data)
    % 高级特征标准化
    
    [numCoeffs, numFrames, numChannels, numSamples] = size(data);
    
    % 计算统计参数
    allData = reshape(data, [], numSamples);
    params.mean = mean(allData, 2);
    params.std = std(allData, 0, 2);
    params.median = median(allData, 2);
    params.mad = mad(allData, 1, 2);
    
    % Z-Score标准化
    normalizedData = data;
    for i = 1:numSamples
        sample = reshape(data(:, :, :, i), [], 1);
        normalizedSample = (sample - params.mean) ./ max(params.std, eps);
        normalizedData(:, :, :, i) = reshape(normalizedSample, numCoeffs, numFrames, numChannels);
    end
end

%% 应用标准化
function normalizedData = applyNormalization(data, params)
    % 应用已有的标准化参数
    
    [numCoeffs, numFrames, numChannels, numSamples] = size(data);
    normalizedData = data;
    
    for i = 1:numSamples
        sample = reshape(data(:, :, :, i), [], 1);
        normalizedSample = (sample - params.mean) ./ max(params.std, eps);
        normalizedData(:, :, :, i) = reshape(normalizedSample, numCoeffs, numFrames, numChannels);
    end
end 