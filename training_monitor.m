%% 训练过程监控脚本
% 监控训练进度、早停机制状态和性能指标
% 作者：AI Assistant
% 日期：2024

function training_monitor()
    clc;
    fprintf('📊 训练过程监控器\n');
    fprintf('监控早停机制和训练进度...\n\n');
    
    % 创建实时监控图表
    figure('Position', [100, 100, 1200, 800], 'Name', '训练实时监控');
    
    % 初始化数据存储
    maxEpochs = 150;  % 与训练脚本一致
    epochs = [];
    trainLoss = [];
    valLoss = [];
    trainAcc = [];
    valAcc = [];
    
    % 设置子图
    subplot(2, 2, 1);
    h1 = plot(NaN, NaN, 'b-', 'LineWidth', 2); hold on;
    h2 = plot(NaN, NaN, 'r-', 'LineWidth', 2);
    xlabel('Epoch');
    ylabel('Loss');
    title('训练和验证损失');
    legend({'训练损失', '验证损失'}, 'Location', 'best');
    grid on;
    
    subplot(2, 2, 2);
    h3 = plot(NaN, NaN, 'b-', 'LineWidth', 2); hold on;
    h4 = plot(NaN, NaN, 'r-', 'LineWidth', 2);
    xlabel('Epoch');
    ylabel('Accuracy (%)');
    title('训练和验证准确率');
    legend({'训练准确率', '验证准确率'}, 'Location', 'best');
    grid on;
    ylim([0, 100]);
    
    subplot(2, 2, 3);
    h5 = plot(NaN, NaN, 'g-', 'LineWidth', 2);
    xlabel('Epoch');
    ylabel('学习率');
    title('学习率变化');
    grid on;
    set(gca, 'YScale', 'log');
    
    subplot(2, 2, 4);
    % 早停状态显示
    axis off;
    text(0.1, 0.9, '早停机制监控', 'FontSize', 14, 'FontWeight', 'bold');
    h_status = text(0.1, 0.8, '状态: 等待开始...', 'FontSize', 12);
    h_patience = text(0.1, 0.7, '耐心计数: 0/20', 'FontSize', 12);
    h_best_loss = text(0.1, 0.6, '最佳验证损失: --', 'FontSize', 12);
    h_best_epoch = text(0.1, 0.5, '最佳轮次: --', 'FontSize', 12);
    h_elapsed = text(0.1, 0.4, '训练时间: --', 'FontSize', 12);
    h_eta = text(0.1, 0.3, '预计剩余: --', 'FontSize', 12);
    h_current_acc = text(0.1, 0.2, '当前验证准确率: --', 'FontSize', 12);
    h_target = text(0.1, 0.1, '目标准确率: 95%', 'FontSize', 12, 'Color', 'green');
    
    % 监控循环
    startTime = tic;
    patienceCount = 0;
    bestValLoss = inf;
    bestEpoch = 0;
    earlyStoppedFlag = false;
    
    fprintf('开始监控训练过程...\n');
    fprintf('按 Ctrl+C 停止监控\n\n');
    
    while true
        try
            % 模拟获取训练数据 (实际应用中应该从训练日志或变量中读取)
            if exist('trainedModel', 'var') % 检查是否有训练中的模型
                % 这里可以添加实际的数据读取逻辑
                currentEpoch = length(epochs) + 1;
                
                if currentEpoch <= maxEpochs
                    % 模拟训练数据 (实际应用中替换为真实数据)
                    epochs(end+1) = currentEpoch;
                    
                    % 模拟损失曲线 (下降趋势 + 噪声)
                    baseLoss = 2 * exp(-currentEpoch/30) + 0.1;
                    trainLoss(end+1) = baseLoss + 0.05*randn();
                    valLoss(end+1) = baseLoss + 0.1*randn() + 0.05;
                    
                    % 模拟准确率曲线 (上升趋势)
                    baseAcc = min(98, 50 + 40*(1 - exp(-currentEpoch/25)));
                    trainAcc(end+1) = baseAcc + 2*randn();
                    valAcc(end+1) = baseAcc + 3*randn() - 2;
                    
                    % 更新图表
                    updatePlots(h1, h2, h3, h4, h5, epochs, trainLoss, valLoss, trainAcc, valAcc);
                    
                    % 早停逻辑
                    if valLoss(end) < bestValLoss
                        bestValLoss = valLoss(end);
                        bestEpoch = currentEpoch;
                        patienceCount = 0;
                    else
                        patienceCount = patienceCount + 1;
                    end
                    
                    % 更新状态信息
                    updateStatus(h_status, h_patience, h_best_loss, h_best_epoch, ...
                               h_elapsed, h_eta, h_current_acc, ...
                               patienceCount, bestValLoss, bestEpoch, ...
                               startTime, currentEpoch, maxEpochs, valAcc);
                    
                    % 检查早停条件
                    if patienceCount >= 20
                        earlyStoppedFlag = true;
                        fprintf('\n🛑 早停机制触发！在第%d轮停止训练\n', currentEpoch);
                        set(h_status, 'String', '状态: 早停触发', 'Color', 'red');
                        break;
                    end
                    
                    % 检查是否达到目标
                    if valAcc(end) >= 95
                        fprintf('\n🎯 达到95%%准确率目标！当前: %.2f%%\n', valAcc(end));
                        set(h_current_acc, 'String', sprintf('当前验证准确率: %.2f%% ✅', valAcc(end)), 'Color', 'green');
                    end
                end
            end
            
            % 检查是否有真实的模型文件生成
            modelPath = './car/optimized_speaker_model.mat';
            if exist(modelPath, 'file')
                fprintf('\n✅ 检测到模型文件生成，开始快速验证...\n');
                
                try
                    % 运行快速评估
                    results = quick_evaluation(modelPath, './car');
                    
                    if ~isempty(results)
                        finalAccuracy = results.accuracy * 100;
                        fprintf('📊 最终测试准确率: %.2f%%\n', finalAccuracy);
                        
                        % 更新显示
                        set(h_current_acc, 'String', sprintf('最终测试准确率: %.2f%%', finalAccuracy));
                        
                        if finalAccuracy >= 95
                            set(h_current_acc, 'Color', 'green');
                            fprintf('🎉 成功达到95%%准确率目标！\n');
                        else
                            set(h_current_acc, 'Color', 'orange');
                            fprintf('⚠️  未达到95%%目标，但训练已完成\n');
                        end
                    end
                catch
                    fprintf('快速评估失败，请手动运行 quick_evaluation()\n');
                end
                
                break;  % 退出监控
            end
            
            pause(2);  % 等待2秒
            
        catch ME
            if contains(ME.message, 'interrupted')
                fprintf('\n⏹️  监控已停止\n');
                break;
            else
                fprintf('监控错误: %s\n', ME.message);
                pause(5);
            end
        end
    end
    
    fprintf('\n📋 监控结束\n');
    if ~earlyStoppedFlag && exist('./car/optimized_speaker_model.mat', 'file')
        fprintf('💡 建议运行以下命令进行完整评估:\n');
        fprintf('   >> main_speaker_recognition(''evaluate'')\n');
        fprintf('   >> main_speaker_recognition(''snr_test'')\n');
    end
end

%% 更新图表
function updatePlots(h1, h2, h3, h4, h5, epochs, trainLoss, valLoss, trainAcc, valAcc)
    % 更新损失图
    set(h1, 'XData', epochs, 'YData', trainLoss);
    set(h2, 'XData', epochs, 'YData', valLoss);
    
    % 更新准确率图
    set(h3, 'XData', epochs, 'YData', trainAcc);
    set(h4, 'XData', epochs, 'YData', valAcc);
    
    % 更新学习率图 (模拟学习率调度)
    learningRates = 1e-3 * (0.2 .^ floor(epochs / 30));
    set(h5, 'XData', epochs, 'YData', learningRates);
    
    % 自动调整坐标轴
    for i = 1:3
        subplot(2, 2, i);
        if ~isempty(epochs)
            xlim([0, max(150, max(epochs)+10)]);
        end
    end
    
    drawnow;
end

%% 更新状态信息
function updateStatus(h_status, h_patience, h_best_loss, h_best_epoch, ...
                     h_elapsed, h_eta, h_current_acc, ...
                     patienceCount, bestValLoss, bestEpoch, ...
                     startTime, currentEpoch, maxEpochs, valAcc)
    
    % 训练状态
    if patienceCount == 0
        set(h_status, 'String', '状态: 正常训练', 'Color', 'green');
    elseif patienceCount < 10
        set(h_status, 'String', '状态: 监控中', 'Color', 'orange');
    else
        set(h_status, 'String', '状态: 准备早停', 'Color', 'red');
    end
    
    % 耐心计数
    patienceStr = sprintf('耐心计数: %d/20', patienceCount);
    if patienceCount >= 15
        set(h_patience, 'String', patienceStr, 'Color', 'red');
    elseif patienceCount >= 10
        set(h_patience, 'String', patienceStr, 'Color', 'orange');
    else
        set(h_patience, 'String', patienceStr, 'Color', 'green');
    end
    
    % 最佳结果
    set(h_best_loss, 'String', sprintf('最佳验证损失: %.4f', bestValLoss));
    set(h_best_epoch, 'String', sprintf('最佳轮次: %d', bestEpoch));
    
    % 时间信息
    elapsedTime = toc(startTime);
    hours = floor(elapsedTime / 3600);
    minutes = floor(mod(elapsedTime, 3600) / 60);
    seconds = mod(elapsedTime, 60);
    
    elapsedStr = sprintf('训练时间: %02d:%02d:%02.0f', hours, minutes, seconds);
    set(h_elapsed, 'String', elapsedStr);
    
    % 预计剩余时间
    if currentEpoch > 0
        avgTimePerEpoch = elapsedTime / currentEpoch;
        remainingEpochs = maxEpochs - currentEpoch;
        etaSeconds = remainingEpochs * avgTimePerEpoch;
        etaHours = floor(etaSeconds / 3600);
        etaMinutes = floor(mod(etaSeconds, 3600) / 60);
        
        etaStr = sprintf('预计剩余: %02d:%02d', etaHours, etaMinutes);
        set(h_eta, 'String', etaStr);
    end
    
    % 当前准确率
    if ~isempty(valAcc)
        currentAccStr = sprintf('当前验证准确率: %.2f%%', valAcc(end));
        if valAcc(end) >= 95
            set(h_current_acc, 'String', [currentAccStr ' ✅'], 'Color', 'green');
        elseif valAcc(end) >= 90
            set(h_current_acc, 'String', currentAccStr, 'Color', 'orange');
        else
            set(h_current_acc, 'String', currentAccStr, 'Color', 'red');
        end
    end
end 