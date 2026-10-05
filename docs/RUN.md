# 运行命令

- 项目：index-tts（IndexTTS / IndexTTS-2.5）
$12026-09-09
- 运行方式：直接运行（`uv` + WebUI / CLI）
- 硬件评估：**满足**（空卡 RTX 4080 16GB）
  - 依据：IndexTTS-2.5 约 **0.8B**；HF 模型卡写明推理约 **6GB** 显存。官方推荐 2.5 用 **BF16**、2.0 用 **FP16**；RTX 4080 支持 BF16，空卡常规精度可跑，无需量化。

## 环境准备

（以下命令供复制，本次未执行）

```powershell
$env:Path = "E:\Programs\ffmpeg-master-latest-win64-gpl\bin;" + $env:Path
cd E:\AI\local-voice\index-tts

$env:HF_ENDPOINT = "https://hf-mirror.com"
# Windows 勿用 --all-extras（DeepSpeed 易失败）
uv sync --extra webui --default-index "https://mirrors.aliyun.com/pypi/simple"

uv run tools/gpu_check.py

# 权重：2.5 → checkpoints/ ；2.0 → checkpoints_2/（见 docs/README_zh.md）
# hf download IndexTeam/IndexTTS-2.5 --local-dir .\checkpoints
```

## 启动

- 推荐：`pwsh -NoProfile -File .\start.ps1`（交互菜单选服务；默认 [1] IndexTTS-2 FP16）
- 服务 Id：`v2`（IndexTTS-2 + FP16）、`v25`（IndexTTS-2.5）
- 自动化跳过菜单：`pwsh -NoProfile -File .\start.ps1 -Service v2`
- 等价手动命令：

```powershell
$env:Path = "E:\Programs\ffmpeg-master-latest-win64-gpl\bin;" + $env:Path
$env:HF_ENDPOINT = "https://hf-mirror.com"
# IndexTTS-2 + FP16
uv run webui.py --version 2 --model_dir ./checkpoints --fp16 --port 7860
# IndexTTS-2.5
# uv run webui.py --version 2.5 --model_dir ./checkpoints_2.5 --port 7860
```

默认端口起点 **7860**（占用则 `start.ps1` 顺延）。

## 验证

1. `uv run tools/gpu_check.py` 识别到 CUDA GPU。
2. 打开 `http://127.0.0.1:7860`，用 `examples/voice_01.wav` 等参考音合成短句，得到 wav。
3. `nvidia-smi` 无 OOM；BF16/FP16 下显存应明显低于 16GB。

## 备注

- 本机基准：空卡 16GB；与既有 `docs/本地运行.md` 结论一致。
- CUDA Toolkit：官方提示遇 CUDA 报错需 **12.8+**（本机若缺 `nvcc`，按需全局补，不装进项目）。
- TensorRT 后端另见 `backends/trt`（非默认路径）。
- 本次未安装依赖、未下载模型、未启动服务。
