%% 说话人识别系统 - 主控制脚本
% 集成训练、评估和SNR分析的完整流程
% 作者：AI Assistant
% 日期：2024

function main_speaker_recognition(operation)
    % 主函数：说话人识别系统的完整流程
    % 输入：
    %   operation - 操作类型: 'train', 'evaluate', 'quick_test', 'snr_test', 'all'
    
    if nargin < 1
        operation = 'all';  % 默认执行完整流程
    end
    
    clc; close all;
    fprintf('╔══════════════════════════════════════════════════════════════╗\n');
    fprintf('║              说话人识别系统 - 主控制台                      ║\n');
    fprintf('║                    版本 2.0                                  ║\n');
    fprintf('║              目标: 95%%+ 准确率，完整评估指标                ║\n');
    fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');
    
    % 检查环境和依赖
    checkEnvironment();
    
    % 设置路径
    dataPath = './car';
    modelPath = fullfile(dataPath, 'optimized_speaker_model.mat');
    
    % 根据操作类型执行相应功能
    switch lower(operation)
        case 'train'
            fprintf('🚀 开始模型训练...\n\n');
            runTraining(dataPath, modelPath);
            
        case 'evaluate'
            fprintf('📊 开始模型评估...\n\n');
            runEvaluation(modelPath, dataPath);
            
        case 'quick_test'
            fprintf('⚡ 开始快速性能测试...\n\n');
            runQuickTest(modelPath, dataPath);
            
        case 'snr_test'
            fprintf('🔊 开始SNR鲁棒性测试...\n\n');
            runSNRAnalysis(modelPath, dataPath);
            
        case 'all'
            fprintf('🎯 执行完整流程: 训练 → 评估 → SNR测试\n\n');
            runCompleteWorkflow(dataPath, modelPath);
            
        otherwise
            error('无效的操作类型。支持的操作: train, evaluate, quick_test, snr_test, all');
    end
    
    fprintf('\n✅ 所有操作完成！\n');
    displayUsageGuide();
end

%% 环境检查
function checkEnvironment()
    fprintf('🔍 检查运行环境...\n');
    
    % 检查MATLAB版本
    matlabVersion = version('-release');
    fprintf('  • MATLAB版本: %s\n', matlabVersion);
    
    % 检查必要工具箱
    toolboxes = {'Deep Learning Toolbox', 'Signal Processing Toolbox', 'Audio Toolbox'};
    missing = {};
    
    for i = 1:length(toolboxes)
        try
            switch toolboxes{i}
                case 'Deep Learning Toolbox'
                    ver('deeplearning');
                case 'Signal Processing Toolbox'
                    ver('signal');
                case 'Audio Toolbox'
                    ver('audio');
            end
            fprintf('  ✓ %s\n', toolboxes{i});
        catch
            missing{end+1} = toolboxes{i}; %#ok<AGROW>
            fprintf('  ✗ %s (缺失)\n', toolboxes{i});
        end
    end
    
    if ~isempty(missing)
        warning('缺少以下工具箱: %s\n部分功能可能受限', strjoin(missing, ', '));
    end
    
    % 检查数据目录
    if ~isfolder('./car')
        error('数据目录 ./car 不存在！请确保音频数据在正确位置。');
    else
        fprintf('  ✓ 数据目录存在\n');
    end
    
    % 检查GPU可用性
    try
        gpu = gpuDevice;
        fprintf('  ✓ GPU可用: %s (内存: %.1fGB)\n', gpu.Name, gpu.AvailableMemory/1024^3);
    catch
        fprintf('  ⚠ GPU不可用，将使用CPU训练\n');
    end
    
    fprintf('环境检查完成\n\n');
end

%% 运行训练
function runTraining(dataPath, modelPath)
    fprintf('═══ 步骤 1: 模型训练 ═══\n');
    
    % 检查是否已存在模型
    if exist(modelPath, 'file')
        choice = input('模型已存在，是否重新训练？(y/n): ', 's');
        if ~strcmpi(choice, 'y')
            fprintf('跳过训练，使用现有模型\n\n');
            return;
        end
    end
    
    try
        % 运行优化训练脚本
        fprintf('开始训练深度CNN模型...\n');
        
        % 记录开始时间（使用更安全的方式）
        trainingStartTime = datetime('now');
        fprintf('训练开始时间: %s\n', datestr(trainingStartTime));
        
        % 运行训练脚本（注意：这会清除工作空间变量）
        train_optimized;  % 调用训练脚本
        
        % 计算训练时间（使用结束时间减去开始时间）
        trainingEndTime = datetime('now');
        trainingDuration = trainingEndTime - trainingStartTime;
        trainingTime = seconds(trainingDuration);
        
        fprintf('✅ 训练完成！耗时: %.1f 分钟\n\n', trainingTime/60);
        
        % 验证模型是否保存成功
        if exist(modelPath, 'file')
            fprintf('✓ 模型已保存到: %s\n', modelPath);
            
            % 获取模型文件信息
            modelInfo = dir(modelPath);
            fprintf('✓ 模型文件大小: %.2f MB\n', modelInfo.bytes/1024/1024);
            fprintf('✓ 创建时间: %s\n', datestr(modelInfo.datenum));
        else
            error('模型保存失败');
        end
        
    catch ME
        if contains(ME.message, 'startTime') || contains(ME.message, '已清除的变量')
            % 如果是startTime变量被清除的错误，提供更友好的信息
            fprintf('⚠️  训练可能已完成，但计时变量被清除\n');
            fprintf('检查模型是否已成功保存...\n');
            
            if exist(modelPath, 'file')
                fprintf('✅ 模型文件存在，训练应该已完成\n');
                modelInfo = dir(modelPath);
                fprintf('✓ 模型文件大小: %.2f MB\n', modelInfo.bytes/1024/1024);
                fprintf('✓ 创建时间: %s\n', datestr(modelInfo.datenum));
                return;  % 成功返回
            else
                error('训练失败：模型文件未生成');
            end
        else
            fprintf('❌ 训练失败: %s\n', ME.message);
            rethrow(ME);
        end
    end
end

%% 运行评估
function runEvaluation(modelPath, dataPath)
    fprintf('═══ 步骤 2: 模型评估 ═══\n');
    
    if ~exist(modelPath, 'file')
        error('模型文件不存在: %s\n请先运行训练！', modelPath);
    end
    
    try
        fprintf('执行完整评估套件...\n');
        
        % 运行评估套件
        evaluation_suite(modelPath, dataPath);
        
        fprintf('✅ 评估完成！\n\n');
        
    catch ME
        fprintf('❌ 评估失败: %s\n', ME.message);
        rethrow(ME);
    end
end

%% 运行快速测试
function runQuickTest(modelPath, dataPath)
    fprintf('═══ 快速性能测试 ═══\n');
    
    if ~exist(modelPath, 'file')
        fprintf('⚠️  模型文件不存在: %s\n', modelPath);
        fprintf('尝试运行快速训练来生成模型...\n\n');
        
        % 询问是否要先训练模型
        choice = input('是否先运行训练？(y/n): ', 's');
        if strcmpi(choice, 'y')
            runTraining(dataPath, modelPath);
        else
            fprintf('❌ 无法进行测试，请先训练模型\n');
            return;
        end
    end
    
    try
        fprintf('开始快速性能评估...\n');
        
        % 运行快速评估
        results = quick_evaluation(modelPath, dataPath);
        
        if ~isempty(results)
            fprintf('\n📈 测试结果总结:\n');
            if results.accuracy >= 0.95
                fprintf('✅ 模型性能优秀！测试准确率: %.2f%% (≥95%%目标)\n', results.accuracy*100);
                fprintf('💡 建议: 可以进行完整评估和SNR测试\n');
            elseif results.accuracy >= 0.90
                fprintf('⚠️  模型性能良好，测试准确率: %.2f%% (接近95%%目标)\n', results.accuracy*100);
                fprintf('💡 建议: 考虑继续训练或调整参数\n');
            else
                fprintf('❌ 模型性能需要改进，测试准确率: %.2f%% (<90%%)\n', results.accuracy*100);
                fprintf('💡 建议: 检查数据质量、网络架构或训练策略\n');
            end
            
            fprintf('✅ 快速测试完成！\n\n');
        else
            fprintf('❌ 快速测试失败\n');
        end
        
    catch ME
        fprintf('❌ 快速测试失败: %s\n', ME.message);
        rethrow(ME);
    end
end

%% 运行SNR分析
function runSNRAnalysis(modelPath, dataPath)
    fprintf('═══ 步骤 3: SNR鲁棒性分析 ═══\n');
    
    if ~exist(modelPath, 'file')
        error('模型文件不存在: %s\n请先运行训练！', modelPath);
    end
    
    try
        fprintf('执行不同信噪比条件下的性能测试...\n');
        
        % 运行SNR分析
        snr_analysis(modelPath, dataPath);
        
        fprintf('✅ SNR分析完成！\n\n');
        
    catch ME
        fprintf('❌ SNR分析失败: %s\n', ME.message);
        rethrow(ME);
    end
end

%% 运行完整工作流程
function runCompleteWorkflow(dataPath, modelPath)
    fprintf('执行完整工作流程...\n\n');
    
    totalStart = tic;
    
    try
        % 步骤1: 训练
        runTraining(dataPath, modelPath);
        
        % 步骤2: 评估
        runEvaluation(modelPath, dataPath);
        
        % 步骤3: SNR分析
        runSNRAnalysis(modelPath, dataPath);
        
        % 生成最终报告
        generateFinalReport(modelPath, dataPath);
        
        totalTime = toc(totalStart);
        
        fprintf('\n🎉 完整工作流程执行成功！\n');
        fprintf('总耗时: %.1f 分钟\n\n', totalTime/60);
        
    catch ME
        fprintf('❌ 工作流程执行失败: %s\n', ME.message);
        rethrow(ME);
    end
end

%% 生成最终报告
function generateFinalReport(modelPath, dataPath)
    fprintf('═══ 最终报告生成 ═══\n');
    
    try
        % 加载模型和结果
        modelData = load(modelPath);
        
        % 检查SNR分析结果
        snrResultsPath = fullfile(dataPath, 'snr_analysis_results.mat');
        if exist(snrResultsPath, 'file')
            snrData = load(snrResultsPath);
        else
            snrData = [];
        end
        
        % 创建最终报告
        reportFile = 'final_performance_report.txt';
        fid = fopen(reportFile, 'w');
        
        if fid == -1
            error('无法创建报告文件');
        end
        
        fprintf(fid, '说话人识别系统 - 最终性能报告\n');
        fprintf(fid, '生成时间: %s\n', datestr(now));
        fprintf(fid, '========================================\n\n');
        
        % 模型基本信息
        fprintf(fid, '模型基本信息:\n');
        fprintf(fid, '• 训练准确率: %.2f%%\n', modelData.modelData.trainAccuracy * 100);
        fprintf(fid, '• 测试准确率: %.2f%%\n', modelData.modelData.testAccuracy * 100);
        fprintf(fid, '• 说话人数量: %d\n', length(modelData.modelData.categories));
        fprintf(fid, '• 特征维度: %dx%d\n', modelData.modelData.numCoeffs, modelData.modelData.maxFrames);
        fprintf(fid, '\n');
        
        % 评估指标
        fprintf(fid, '评估指标:\n');
        if modelData.modelData.testAccuracy >= 0.95
            fprintf(fid, '• 系统达到95%%准确率目标: 是\n');
        else
            fprintf(fid, '• 系统达到95%%准确率目标: 否\n');
        end
        
        % SNR分析结果
        if ~isempty(snrData)
            fprintf(fid, '\nSNR鲁棒性分析:\n');
            noiseTypes = snrData.noise_types;
            snrValues = snrData.snr_values;
            
            for i = 1:length(noiseTypes)
                avgAcc = mean(snrData.results.(noiseTypes{i}).accuracy) * 100;
                fprintf(fid, '• %s噪声环境平均准确率: %.2f%%\n', upper(noiseTypes{i}), avgAcc);
            end
        end
        
        % 技术规格
        fprintf(fid, '\n技术规格:\n');
        fprintf(fid, '• 采样率: %d Hz\n', modelData.modelData.fs);
        fprintf(fid, '• 帧长: %.0f ms\n', modelData.modelData.frameSize * 1000);
        fprintf(fid, '• 帧移: %.0f ms\n', modelData.modelData.frameStep * 1000);
        fprintf(fid, '• MFCC系数: %d (包含Δ和ΔΔ)\n', modelData.modelData.numCoeffs);
        
        % 推荐使用场景
        fprintf(fid, '\n推荐使用场景:\n');
        if modelData.modelData.testAccuracy >= 0.95
            fprintf(fid, '• 高准确率说话人识别系统\n');
            fprintf(fid, '• 安全认证应用\n');
            fprintf(fid, '• 语音生物识别\n');
        else
            fprintf(fid, '• 一般说话人识别应用\n');
            fprintf(fid, '• 需要进一步优化以达到更高准确率\n');
        end
        
        fprintf(fid, '\n生成的文件:\n');
        fprintf(fid, '• 模型文件: %s\n', modelPath);
        fprintf(fid, '• 评估图表: speaker_recognition_evaluation.png\n');
        fprintf(fid, '• SNR分析图表: snr_analysis_results.png\n');
        fprintf(fid, '• 性能趋势图: snr_performance_trend.png\n');
        
        fclose(fid);
        
        fprintf('✓ 最终报告已生成: %s\n', reportFile);
        
    catch ME
        fprintf('报告生成失败: %s\n', ME.message);
    end
end

%% 显示使用指南
function displayUsageGuide()
    fprintf('╔══════════════════════════════════════════════════════════════╗\n');
    fprintf('║                         使用指南                             ║\n');
    fprintf('╠══════════════════════════════════════════════════════════════╣\n');
    fprintf('║ 运行方式:                                                    ║\n');
    fprintf('║                                                              ║\n');
    fprintf('║ 1. 完整流程 (推荐):                                          ║\n');
    fprintf('║    >> main_speaker_recognition(''all'')                      ║\n');
    fprintf('║    或直接运行: >> main_speaker_recognition                   ║\n');
    fprintf('║                                                              ║\n');
    fprintf('║ 2. 仅训练模型:                                               ║\n');
    fprintf('║    >> main_speaker_recognition(''train'')                    ║\n');
    fprintf('║                                                              ║\n');
    fprintf('║ 3. 仅评估模型:                                               ║\n');
    fprintf('║    >> main_speaker_recognition(''evaluate'')                 ║\n');
    fprintf('║                                                              ║\n');
    fprintf('║ 4. 快速性能测试 (推荐先运行):                                ║\n');
    fprintf('║    >> main_speaker_recognition(''quick_test'')               ║\n');
    fprintf('║    >> quick_evaluation()  % 或直接调用                      ║\n');
    fprintf('║                                                              ║\n');
    fprintf('║ 5. 仅SNR测试:                                                ║\n');
    fprintf('║    >> main_speaker_recognition(''snr_test'')                 ║\n');
    fprintf('║                                                              ║\n');
    fprintf('║ 生成的文件:                                                  ║\n');
    fprintf('║ • optimized_speaker_model.mat - 训练好的模型                ║\n');
    fprintf('║ • quick_evaluation_results.mat - 快速评估结果               ║\n');
    fprintf('║ • speaker_recognition_evaluation.png - 评估图表             ║\n');
    fprintf('║ • snr_analysis_results.png - SNR分析图                      ║\n');
    fprintf('║ • snr_performance_trend.png - 性能趋势图                    ║\n');
    fprintf('║ • final_performance_report.txt - 最终报告                   ║\n');
    fprintf('║                                                              ║\n');
    fprintf('║ 评估指标说明:                                                ║\n');
    fprintf('║ • 准确率 - 总体识别正确率                                    ║\n');
    fprintf('║ • EER - 等错误率 (越低越好)                                  ║\n');
    fprintf('║ • minDCF - 最小检测代价 (越低越好)                           ║\n');
    fprintf('║ • FAR - 误接受率                                            ║\n');
    fprintf('║ • FRR - 误拒绝率                                            ║\n');
    fprintf('║ • ROC/DET曲线 - 性能可视化                                   ║\n');
    fprintf('║                                                              ║\n');
    fprintf('║ 系统要求:                                                    ║\n');
    fprintf('║ • MATLAB R2020a 或更高版本                                   ║\n');
    fprintf('║ • Deep Learning Toolbox                                     ║\n');
    fprintf('║ • Signal Processing Toolbox                                 ║\n');
    fprintf('║ • Audio Toolbox (可选，用于高级数据增强)                    ║\n');
    fprintf('║ • 推荐使用GPU加速训练                                        ║\n');
    fprintf('╚══════════════════════════════════════════════════════════════╝\n');
end

%% 单独可调用的函数
function demo_single_prediction()
    % 演示单个音频文件的预测
    fprintf('演示单个音频文件预测...\n');
    
    modelPath = './car/optimized_speaker_model.mat';
    if ~exist(modelPath, 'file')
        error('模型不存在，请先运行训练');
    end
    
    % 加载模型
    modelData = load(modelPath);
    net = modelData.modelData.net;
    normParams = modelData.modelData.normParams;
    
    % 选择一个测试音频文件
    testFile = './car/a1/D4_750.wav';  % 示例文件
    
    if exist(testFile, 'file')
        try
            % 加载和预处理音频
            [audio, fs] = audioread(testFile);
            
            % 特征提取
            mfcc = extractAdvancedMFCC(audio, modelData.modelData.fs, ...
                                       modelData.modelData.frameSize, ...
                                       modelData.modelData.frameStep, ...
                                       modelData.modelData.numCoeffs, ...
                                       modelData.modelData.maxFrames);
            
            % 标准化
            features = reshape(mfcc, [modelData.modelData.numCoeffs, modelData.modelData.maxFrames, 1, 1]);
            featuresNorm = applyNormalization(features, normParams);
            
            % 预测
            [predLabel, score] = classify(net, featuresNorm);
            probs = predict(net, featuresNorm);
            
            fprintf('预测结果:\n');
            fprintf('• 音频文件: %s\n', testFile);
            fprintf('• 预测说话人: %s\n', string(predLabel));
            fprintf('• 置信度: %.2f%%\n', max(probs) * 100);
            
        catch ME
            fprintf('预测失败: %s\n', ME.message);
        end
    else
        fprintf('测试文件不存在: %s\n', testFile);
    end
end 