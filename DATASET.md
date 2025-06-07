# 数据集说明 / Dataset Information

## 📁 数据集结构 / Dataset Structure

本项目需要音频数据集来训练和测试说话人识别模型。请按以下结构组织您的数据集：

```
car/
├── speaker1/
│   ├── sample1.wav
│   ├── sample2.wav
│   └── ...
├── speaker2/
│   ├── sample1.wav
│   ├── sample2.wav
│   └── ...
└── ...
```

## 🎯 数据集要求 / Dataset Requirements

### 音频格式 / Audio Format
- **格式**: WAV 文件
- **采样率**: 16kHz (推荐)
- **位深**: 16-bit
- **通道**: 单声道 (Mono)

### 数据组织 / Data Organization
- 每个说话人一个文件夹
- 文件夹名即为说话人ID
- 每个说话人至少需要 **100+ 音频样本**
- 每个音频样本长度建议 **2-10秒**

### 推荐数据集大小 / Recommended Dataset Size
- **训练集**: 每人 200+ 样本
- **测试集**: 每人 50+ 样本
- **说话人数量**: 10+ 人（更多说话人 = 更好性能）

## 📊 示例数据集 / Example Datasets

您可以使用以下公开数据集：

### 1. VoxCeleb Dataset
- **来源**: http://www.robots.ox.ac.uk/~vgg/data/voxceleb/
- **描述**: 大规模说话人识别数据集
- **包含**: 1000+ 说话人

### 2. LibriSpeech Dataset  
- **来源**: http://www.openslr.org/12/
- **描述**: 英语语音识别数据集，可用于说话人识别
- **包含**: 2000+ 说话人

### 3. TIMIT Dataset
- **来源**: https://catalog.ldc.upenn.edu/LDC93S1
- **描述**: 经典语音数据集
- **包含**: 630 说话人

## 🔧 数据预处理 / Data Preprocessing

### 自动预处理
运行训练程序时，系统会自动进行：
- 音频归一化
- MFCC特征提取 (39维)
- 数据增强 (可选)

### 手动预处理建议
1. **去除静音**: 删除音频开头和结尾的静音段
2. **音量标准化**: 确保音频音量一致
3. **噪声过滤**: 去除背景噪声
4. **文件命名**: 使用有意义的文件名

## 📝 数据集准备步骤 / Dataset Preparation Steps

### 步骤1: 创建目录结构
```bash
mkdir car
cd car
mkdir speaker1 speaker2 speaker3 ...
```

### 步骤2: 复制音频文件
将每个说话人的音频文件复制到对应文件夹中

### 步骤3: 验证数据集
运行以下MATLAB命令验证数据集：
```matlab
% 检查数据集结构
dataPath = 'car';
speakers = dir(dataPath);
speakers = speakers([speakers.isdir] & ~ismember({speakers.name}, {'.', '..'}));

fprintf('发现 %d 个说话人:\n', length(speakers));
for i = 1:length(speakers)
    audioFiles = dir(fullfile(dataPath, speakers(i).name, '*.wav'));
    fprintf('说话人 %s: %d 个音频文件\n', speakers(i).name, length(audioFiles));
end
```

### 步骤4: 开始训练
数据集准备完成后，运行：
```matlab
professional_speaker_gui  % 启动GUI
% 或
main_speaker_recognition  % 命令行模式
```

## ⚠️ 注意事项 / Important Notes

1. **版权**: 确保您有权使用所选择的数据集
2. **隐私**: 不要使用未经授权的个人录音
3. **质量**: 高质量的音频数据会显著提升识别准确率
4. **平衡**: 保持各说话人的样本数量相对平衡

## 🔗 相关资源 / Related Resources

- [MATLAB音频处理工具箱文档](https://www.mathworks.com/help/audio/)
- [说话人识别技术综述](https://ieeexplore.ieee.org/document/8706504)
- [MFCC特征提取原理](https://www.mathworks.com/help/audio/ref/mfcc.html)

---

**需要帮助?** 如果您在数据集准备过程中遇到问题，请在Issues中提出，我们会及时回复。 