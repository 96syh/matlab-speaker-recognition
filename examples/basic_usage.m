%% Speaker Recognition System - Basic Usage Examples
% This file demonstrates basic usage of the Speaker Recognition System
% Author: Speaker Recognition System Contributors
% Date: 2024

%% Clear workspace
clear; clc; close all;

fprintf('🎙️ Speaker Recognition System - Basic Usage Examples\n');
fprintf('=====================================================\n\n');

%% Example 1: Quick System Test
fprintf('📋 Example 1: Quick System Test\n');
fprintf('--------------------------------\n');

% Check if system is ready
fprintf('Checking system status...\n');

% Verify data directory
if exist('./car', 'dir')
    fprintf('✅ Data directory found\n');
    
    % Count audio files in each speaker directory
    speakerDirs = dir('./car');
    speakerDirs = speakerDirs([speakerDirs.isdir] & ~startsWith({speakerDirs.name}, '.'));
    
    fprintf('📊 Found %d speaker directories:\n', length(speakerDirs));
    for i = 1:length(speakerDirs)
        audioFiles = dir(fullfile('./car', speakerDirs(i).name, '*.wav'));
        fprintf('   %s: %d audio files\n', speakerDirs(i).name, length(audioFiles));
    end
else
    fprintf('⚠️  Data directory not found. Please ensure ./car/ directory exists\n');
    fprintf('   You can still run the system with your own data\n');
end

fprintf('\n');

%% Example 2: Run Quick Evaluation
fprintf('📋 Example 2: Quick Performance Evaluation\n');
fprintf('-------------------------------------------\n');

try
    % Check if model exists
    modelPath = './car/optimized_speaker_model.mat';
    if exist(modelPath, 'file')
        fprintf('Model found. Running quick evaluation...\n');
        
        % Run quick evaluation
        main_speaker_recognition('quick_test');
        
        fprintf('✅ Quick evaluation completed successfully!\n');
    else
        fprintf('⚠️  No trained model found. Training a new model first...\n');
        fprintf('💡 This will take some time. Consider running the full training:\n');
        fprintf('   main_speaker_recognition(''train'')\n');
    end
catch ME
    fprintf('❌ Quick evaluation failed: %s\n', ME.message);
end

fprintf('\n');

%% Example 3: Step-by-Step Training Process
fprintf('📋 Example 3: Step-by-Step Training Process\n');
fprintf('--------------------------------------------\n');

fprintf('To train a new model from scratch, follow these steps:\n\n');

fprintf('Step 1: Train the model\n');
fprintf('   main_speaker_recognition(''train'')\n\n');

fprintf('Step 2: Quick performance test\n');
fprintf('   main_speaker_recognition(''quick_test'')\n\n');

fprintf('Step 3: Complete evaluation\n');
fprintf('   main_speaker_recognition(''evaluate'')\n\n');

fprintf('Step 4: SNR robustness testing\n');
fprintf('   main_speaker_recognition(''snr_test'')\n\n');

fprintf('Or run everything at once:\n');
fprintf('   main_speaker_recognition(''all'')\n\n');

%% Example 4: GUI Interface
fprintf('📋 Example 4: Launch Professional GUI\n');
fprintf('--------------------------------------\n');

fprintf('To launch the professional GUI interface:\n');
fprintf('   professional_speaker_gui()\n\n');

fprintf('The GUI provides 7 main modules:\n');
fprintf('   🏠 Model Management\n');
fprintf('   🎵 Single File Test\n');
fprintf('   📁 Batch Testing\n');
fprintf('   🎙️ Real-time Recording\n');
fprintf('   📊 Performance Analysis\n');
fprintf('   🔊 SNR Testing\n');
fprintf('   💾 Result Export\n\n');

%% Example 5: Custom Configuration
fprintf('📋 Example 5: Custom Configuration Example\n');
fprintf('-------------------------------------------\n');

fprintf('Example of modifying training parameters:\n\n');

fprintf('%% Custom training configuration\n');
fprintf('function customTraining()\n');
fprintf('    %% Edit train_optimized.m and modify these parameters:\n');
fprintf('    \n');
fprintf('    %% Training options\n');
fprintf('    options = trainingOptions(''adam'', ...\n');
fprintf('        ''MaxEpochs'', 50, ...           %% Reduce epochs for faster training\n');
fprintf('        ''MiniBatchSize'', 32, ...       %% Smaller batch for limited memory\n');
fprintf('        ''InitialLearnRate'', 0.001, ... %% Learning rate\n');
fprintf('        ''ValidationFrequency'', 30, ... %% Validation frequency\n');
fprintf('        ''Verbose'', true, ...           %% Show training progress\n');
fprintf('        ''Plots'', ''training-progress'' ... %% Show plots\n');
fprintf('    );\n');
fprintf('    \n');
fprintf('    %% Network architecture modifications\n');
fprintf('    %% You can modify the CNN layers in train_optimized.m\n');
fprintf('end\n\n');

%% Example 6: Working with Your Own Data
fprintf('📋 Example 6: Using Your Own Audio Data\n');
fprintf('----------------------------------------\n');

fprintf('To use your own audio data:\n\n');

fprintf('1. Create speaker directories:\n');
fprintf('   mkdir speaker1\n');
fprintf('   mkdir speaker2\n');
fprintf('   ...\n\n');

fprintf('2. Place WAV files in each directory:\n');
fprintf('   - Use 16kHz sampling rate (recommended)\n');
fprintf('   - Mono channel audio\n');
fprintf('   - At least 10-20 files per speaker\n\n');

fprintf('3. Update the data path in your scripts:\n');
fprintf('   dataPath = ''/path/to/your/data'';\n\n');

fprintf('4. Run training with your data:\n');
fprintf('   main_speaker_recognition(''train'')\n\n');

%% Example 7: Performance Monitoring
fprintf('📋 Example 7: Training Progress Monitoring\n');
fprintf('-------------------------------------------\n');

fprintf('To monitor training progress in real-time:\n\n');

fprintf('1. Start training in one MATLAB session:\n');
fprintf('   main_speaker_recognition(''train'')\n\n');

fprintf('2. In another session, run the monitor:\n');
fprintf('   training_monitor()\n\n');

fprintf('The monitor will show:\n');
fprintf('   - Real-time loss curves\n');
fprintf('   - Accuracy progression\n');
fprintf('   - Training status\n');
fprintf('   - System resource usage\n\n');

%% Example 8: Batch Processing Multiple Files
fprintf('📋 Example 8: Batch Processing Example\n');
fprintf('---------------------------------------\n');

fprintf('Example code for batch processing:\n\n');

fprintf('%% Batch processing example\n');
fprintf('function batchProcessing()\n');
fprintf('    %% Load trained model\n');
fprintf('    load(''./car/optimized_speaker_model.mat'', ''net'');\n');
fprintf('    \n');
fprintf('    %% Define test directory\n');
fprintf('    testDir = ''/path/to/test/files'';\n');
fprintf('    audioFiles = dir(fullfile(testDir, ''*.wav''));\n');
fprintf('    \n');
fprintf('    %% Process each file\n');
fprintf('    results = cell(length(audioFiles), 3);\n');
fprintf('    for i = 1:length(audioFiles)\n');
fprintf('        filename = audioFiles(i).name;\n');
fprintf('        filepath = fullfile(testDir, filename);\n');
fprintf('        \n');
fprintf('        %% Extract features and predict\n');
fprintf('        try\n');
fprintf('            [prediction, confidence] = recognizeSpeaker(filepath, net);\n');
fprintf('            results{i, 1} = filename;\n');
fprintf('            results{i, 2} = prediction;\n');
fprintf('            results{i, 3} = confidence;\n');
fprintf('            fprintf(''%%s: %%s (%.2f%%%%)\n'', filename, prediction, confidence*100);\n');
fprintf('        catch ME\n');
fprintf('            fprintf(''Error processing %%s: %%s\n'', filename, ME.message);\n');
fprintf('        end\n');
fprintf('    end\n');
fprintf('    \n');
fprintf('    %% Save results\n');
fprintf('    save(''batch_results.mat'', ''results'');\n');
fprintf('end\n\n');

%% Summary
fprintf('🎉 Summary\n');
fprintf('----------\n');
fprintf('These examples cover the basic usage patterns of the Speaker Recognition System.\n');
fprintf('For more advanced usage, please refer to:\n');
fprintf('   - README.md: Complete system overview\n');
fprintf('   - GUI_使用说明.md: Detailed GUI manual\n');
fprintf('   - docs/: Additional documentation\n\n');

fprintf('💡 Quick Tips:\n');
fprintf('   - Always ensure your audio files are 16kHz WAV format\n');
fprintf('   - Use GPU acceleration when available\n');
fprintf('   - Monitor memory usage during training\n');
fprintf('   - Save your work frequently\n\n');

fprintf('✅ Ready to start? Run one of these commands:\n');
fprintf('   professional_speaker_gui()           %% Launch GUI\n');
fprintf('   main_speaker_recognition(''help'')    %% Show help\n');
fprintf('   main_speaker_recognition(''all'')     %% Run complete workflow\n\n');

fprintf('Happy speaker recognition! 🎙️✨\n'); 