---
title: TensorRT + ONNX 学习路径：从 Python 推理到 C++ 部署
categories:
- 深度学习
tags:
- TensorRT
- ONNX
- C++部署
---

# TensorRT + ONNX 学习路径：从 Python 推理到 C++ 部署

> 一条系统性的学习路线，涵盖 ONNX 模型导出、TensorRT 优化加速、Python 推理与 C++ 生产部署全流程。

---

## 目录

1. [阶段 0：前置知识](#阶段-0前置知识)
2. [阶段 1：ONNX 基础 — 模型导出与调试](#阶段-1onnx-基础--模型导出与调试)
3. [阶段 2：TensorRT 基础 — Python API 推理](#阶段-2tensorrt-基础--python-api-推理)
4. [阶段 3：TensorRT 进阶 — 构建与优化](#阶段-3tensorrt-进阶--构建与优化)
5. [阶段 4：C++ 部署实战](#阶段-4c-部署实战)
6. [阶段 5：生产级实践与性能调优](#阶段-5生产级实践与性能调优)
7. [推荐资源汇总](#推荐资源汇总)
8. [学习路线图（总览）](#学习路线图总览)

---

## 阶段 0：前置知识

在开始之前，确保掌握以下基础：

### 必备技能

| 技能 | 要求程度 | 说明 |
|------|----------|------|
| Python | 熟练 | 模型训练、ONNX 导出、TensorRT Python API |
| C++ | 掌握 | 生产部署、TensorRT C++ API、内存管理 |
| PyTorch / TensorFlow | 熟练至少一个 | 模型构建与训练 |
| CUDA 基础 | 了解 | GPU 内存模型、kernel 概念 |
| CMake | 基本使用 | C++ 项目构建 |
| Linux 命令行 | 熟练 | 多数部署环境为 Linux |

### 预备阅读

- [NVIDIA CUDA Programming Guide](https://docs.nvidia.com/cuda/cuda-c-programming-guide/) — 精读第1-3章
- [PyTorch 官方教程](https://pytorch.org/tutorials/) — 完成图像分类示例
- C++ 智能指针、RAII、多线程基础知识

---

## 阶段 1：ONNX 基础 — 模型导出与调试

### 1.1 理解 ONNX

**目标**：理解 ONNX 的设计哲学与核心概念。

- ONNX (Open Neural Network Exchange) 是一种开放的模型表示格式
- 核心抽象：**计算图 (Computation Graph)**，节点 = 算子 (Operator)，边 = 张量 (Tensor)
- 算子集版本 (Opset Version) 决定可用算子的集合
- 支持动态形状 (Dynamic Shape) 与静态形状 (Static Shape)

**学习任务**：
- [ ] 阅读 [ONNX 官方文档 Overview](https://onnx.ai/onnx/intro/)
- [ ] 理解 Protobuf 序列化机制（ONNX 基于 protobuf）
- [ ] 安装 `onnx`、`onnxruntime`、`netron` 工具链

```bash
pip install onnx onnxruntime onnxruntime-gpu netron
```

### 1.2 PyTorch → ONNX 导出

**目标**：能将 PyTorch 模型正确导出为 ONNX。

- `torch.onnx.export()` 的核心参数：
  - `model`：PyTorch 模型
  - `args`：示例输入（用于 trace）
  - `input_names` / `output_names`：命名张量
  - `dynamic_axes`：声明动态维度（如 batch size）
  - `opset_version`：目标算子集版本

**学习任务**：
- [ ] 导出 ResNet/ResNeXt 分类模型
- [ ] 导出包含动态 batch size 的模型
- [ ] 导出包含条件分支（if-else）的模型（对比 trace vs script）
- [ ] 理解 `torch.onnx.export()` 的两种模式：
  - **TorchScript trace**（默认）：运行一次，记录操作序列 — 不支持控制流
  - **TorchScript script**：解析 Python 代码生成 IR — 支持控制流

**实践代码**：
```python
import torch
import torchvision.models as models

model = models.resnet50(pretrained=True).cuda().eval()
dummy_input = torch.randn(1, 3, 224, 224, device="cuda")

torch.onnx.export(
    model,
    dummy_input,
    "resnet50.onnx",
    input_names=["input"],
    output_names=["output"],
    dynamic_axes={"input": {0: "batch_size"}, "output": {0: "batch_size"}},
    opset_version=17,
    do_constant_folding=True,
)
```

### 1.3 ONNX 模型验证与调试

**目标**：能检查、验证、修复导出的 ONNX 模型。

- `onnx.checker.check_model()` — 验证模型合法性
- `onnx.helper.printable_graph()` — 打印计算图
- **Netron** — 可视化模型结构
- `onnxruntime.InferenceSession()` — 快速验证推理正确性

**学习任务**：
- [ ] 使用 Netron 可视化模型结构
- [ ] 对比 PyTorch 输出与 ONNX Runtime 输出（精度校验）
- [ ] 使用 `onnxsim` 简化模型图

```bash
# 安装工具
pip install onnx-simplifier netron

# 可视化
netron resnet50.onnx

# 简化模型
python -m onnxsim resnet50.onnx resnet50_simplified.onnx
```

### 1.4 常见导出问题与解决

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 算子不支持 | 使用了 ONNX 未定义的算子 | 自定义算子或用支持的算子重写 |
| Trace 丢失动态控制流 | 使用了 trace 模式导出带 if 的模型 | 改用 `torch.jit.script` |
| 精度下降 | FP16 转换 或 算子融合差异 | 逐层对比，设置 `do_constant_folding=False` 排查 |
| 动态形状出错 | `dynamic_axes` 配置不正确 | 检查输入/输出维度声明 |
| 导出时报错 | 模型包含非 Tensor 输出 | 确保输出都是 `torch.Tensor` |

---

## 阶段 2：TensorRT 基础 — Python API 推理

### 2.1 理解 TensorRT

**目标**：理解 TensorRT 是什么、为什么快。

TensorRT 是 NVIDIA 的高性能深度学习推理优化器和运行时，核心优化技术：

1. **层融合 (Layer Fusion)** — 合并 Conv+BN+ReLU 为一个 kernel
2. **精度校准 (Precision Calibration)** — FP32 → FP16 / INT8
3. **Kernel 自动调优 (Auto-Tuning)** — 为目标 GPU 选择最优 kernel
4. **显存优化** — 减少中间张量分配，复用显存
5. **动态形状支持** — 处理可变 batch size 的输入

**学习任务**：
- [ ] 阅读 [TensorRT 开发者指南 Overview](https://docs.nvidia.com/deeplearning/tensorrt/developer-guide/)
- [ ] 理解 build phase（构建引擎）vs inference phase（推理）

### 2.2 安装 TensorRT

```bash
# 方式一：pip 安装（推荐入门）
pip install tensorrt

# 方式二：NVIDIA 官方 tar/deb 包
# 下载地址：https://developer.nvidia.com/tensorrt/download

# 验证安装
python -c "import tensorrt; print(tensorrt.__version__)"
```

### 2.3 ONNX → TensorRT Engine（Python）

**目标**：掌握将 ONNX 模型构建为 TensorRT Engine 的流程。

关键步骤：
1. 创建 `Builder`、`Network`、`Config`
2. 解析 ONNX 模型
3. 配置优化参数（精度、显存、workspace）
4. 构建序列化 Engine

**学习任务**：
- [ ] 使用 TensorRT Python API 构建 Engine
- [ ] 理解 FP16 / INT8 模式的配置差异
- [ ] 理解 `workspace_size` 的作用
- [ ] 对比不同精度下的推理速度和精度损失

**实践代码 — 构建 Engine**：
```python
import tensorrt as trt

def build_engine(onnx_path: str, engine_path: str, fp16: bool = False):
    logger = trt.Logger(trt.Logger.WARNING)
    builder = trt.Builder(logger)
    network = builder.create_network(1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH))
    config = builder.create_builder_config()
    config.set_memory_pool_limit(trt.MemoryPoolType.WORKSPACE, 1 << 30)  # 1GB

    if fp16:
        config.set_flag(trt.BuilderFlag.FP16)

    parser = trt.OnnxParser(network, logger)
    with open(onnx_path, "rb") as f:
        if not parser.parse(f.read()):
            for i in range(parser.num_errors):
                print(f"Parse error: {parser.get_error(i)}")
            return None

    serialized_engine = builder.build_serialized_network(network, config)
    if serialized_engine is None:
        return None

    with open(engine_path, "wb") as f:
        f.write(serialized_engine)
    return serialized_engine
```

### 2.4 Python 推理 Runtime

**目标**：加载 Engine 执行推理。

**实践代码 — 推理**：
```python
import tensorrt as trt
import numpy as np
import pycuda.driver as cuda
import pycuda.autoinit

class TRTInference:
    def __init__(self, engine_path: str):
        self.logger = trt.Logger(trt.Logger.WARNING)
        self.runtime = trt.Runtime(self.logger)

        with open(engine_path, "rb") as f:
            self.engine = self.runtime.deserialize_cuda_engine(f.read())

        self.context = self.engine.create_execution_context()

        # 分配显存
        self.inputs, self.outputs, self.bindings = [], [], []
        for i in range(self.engine.num_io_tensors):
            name = self.engine.get_tensor_name(i)
            shape = self.engine.get_tensor_shape(name)
            dtype = trt.nptype(self.engine.get_tensor_dtype(name))
            size = trt.volume(shape)

            d_mem = cuda.mem_alloc(size * np.dtype(dtype).itemsize)
            self.bindings.append(int(d_mem))

            if self.engine.get_tensor_mode(name) == trt.TensorIOMode.INPUT:
                self.inputs.append({"name": name, "shape": shape, "dtype": dtype, "device_mem": d_mem})
            else:
                self.outputs.append({"name": name, "shape": shape, "dtype": dtype, "device_mem": d_mem})

        self.stream = cuda.Stream()

    def infer(self, input_data: np.ndarray) -> np.ndarray:
        # 拷贝输入到 GPU
        cuda.memcpy_htod_async(self.inputs[0]["device_mem"], input_data, self.stream)

        # 设置 tensor 地址
        for inp in self.inputs:
            self.context.set_tensor_address(inp["name"], int(inp["device_mem"]))
        for out in self.outputs:
            self.context.set_tensor_address(out["name"], int(out["device_mem"]))

        # 执行推理
        self.context.execute_async_v3(self.stream.handle)

        # 拷贝输出到 CPU
        output = np.empty(self.outputs[0]["shape"], dtype=self.outputs[0]["dtype"])
        cuda.memcpy_dtoh_async(output, self.outputs[0]["device_mem"], self.stream)
        self.stream.synchronize()

        return output
```

---

## 阶段 3：TensorRT 进阶 — 构建与优化

### 3.1 精度优化：FP16 / INT8

**目标**：理解并应用精度降级加速技术。

| 精度 | 速度提升 | 精度损失 | 适用场景 |
|------|----------|----------|----------|
| FP32 | 1× (基准) | 无 | 精度敏感任务 |
| FP16 | 1.5~2× | ~0.1% | 大多数推理场景 |
| INT8 | 2~4× | 0.5~2% | 吞吐优先、延迟敏感 |

**INT8 校准流程**：
1. 准备有代表性的校准数据集（500-2000 张图）
2. 使用 `Int8Calibrator` 收集激活值分布
3. TensorRT 基于分布自动选择量化参数

**学习任务**：
- [ ] 实现 `IInt8Calibrator` 校准器
- [ ] 对比 FP32 / FP16 / INT8 的速度与精度
- [ ] 理解 EntropyCalibrator vs MinMaxCalibrator 的区别

```python
import tensorrt as trt

class MyCalibrator(trt.IInt8Calibrator):
    def __init__(self, calibration_data: np.ndarray):
        super().__init__()
        self.data = calibration_data
        self.current_idx = 0
        # 分配设备内存
        self.device_input = cuda.mem_alloc(self.data[0].nbytes)

    def get_batch_size(self):
        return self.data[0].shape[0]

    def get_batch(self, names):
        if self.current_idx >= len(self.data):
            return None
        batch = self.data[self.current_idx]
        cuda.memcpy_htod(self.device_input, batch)
        self.current_idx += 1
        return [int(self.device_input)]

    def read_calibration_cache(self):
        return None  # 或返回缓存的 calibration table

    def write_calibration_cache(self, cache):
        pass  # 可保存 cache 供下次使用
```

### 3.2 动态形状 (Dynamic Shape)

**目标**：处理可变 batch size / 分辨率。

- `opt_profile`：定义输入的最小、最优、最大形状
- `context.set_input_shape()`：每次推理前动态设置形状

**学习任务**：
- [ ] 创建 Optimization Profile 处理多 batch size
- [ ] 理解 shape 变化时 TensorRT 的 kernel 选择策略

```python
profile = builder.create_optimization_profile()
profile.set_shape(
    "input",
    min=(1, 3, 224, 224),    # 最小
    opt=(8, 3, 224, 224),    # 最优（构建时调优目标）
    max=(64, 3, 224, 224),   # 最大
)
config.add_optimization_profile(profile)
```

### 3.3 多流并发

**目标**：提升 GPU 利用率，并发处理多路推理。

```python
# 创建多个 execution context 并发推理
# 每个 context 绑定到不同的 CUDA Stream
contexts = [engine.create_execution_context() for _ in range(4)]
streams = [cuda.Stream() for _ in range(4)]
```

### 3.4 自定义算子 (Custom Plugin)

**目标**：当 ONNX / TensorRT 不支持某个算子时，自行实现。

- 实现 `IPluginV2DynamicExt` 接口
- 使用 `REGISTER_TENSORRT_PLUGIN` 注册

**适用场景**：
- 模型中包含 TensorRT 不支持的新算子
- 需要手动融合多个操作为一个高效 kernel

---

## 阶段 4：C++ 部署实战

### 4.1 环境搭建

**目标**：在 Linux/WSL 上搭建 C++ TensorRT 开发环境。

**依赖项**：
- CUDA Toolkit (11.8+ 或 12.x)
- cuDNN
- TensorRT SDK (tar/deb 包)
- CMake 3.18+
- GCC 9+ / Clang 10+
- (可选) OpenCV — 图像预处理
- (可选) gflags / spdlog — 参数解析 / 日志

**CMake 项目模板**：
```cmake
cmake_minimum_required(VERSION 3.18)
project(trt_inference LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CUDA_STANDARD 17)

# TensorRT
find_library(NVINFER nvinfer HINTS ${TENSORRT_DIR}/lib)
find_library(NVINFER_PLUGIN nvinfer_plugin HINTS ${TENSORRT_DIR}/lib)
include_directories(${TENSORRT_DIR}/include)

# CUDA
find_package(CUDA REQUIRED)

add_executable(trt_infer main.cpp)
target_link_libraries(trt_infer
    ${NVINFER}
    ${NVINFER_PLUGIN}
    ${CUDA_LIBRARIES}
    cudart
)
```

### 4.2 Logger 与 Engine 管理

**目标**：将 TensorRT Logger 封装为 C++ 单例，管理 Engine 生命周期。

**核心类**：
- `nvinfer1::ILogger` — 日志接口
- `nvinfer1::IRuntime` — 反序列化 Engine
- `nvinfer1::ICudaEngine` — 推理引擎
- `nvinfer1::IExecutionContext` — 执行上下文

**学习任务**：
- [ ] 实现 Logger 类（继承 `nvinfer1::ILogger`）
- [ ] 封装 Engine 的加载/卸载
- [ ] 理解 Engine 序列化与反序列化

```cpp
class Logger : public nvinfer1::ILogger {
public:
    void log(Severity severity, const char* msg) noexcept override {
        if (severity <= Severity::kWARNING)
            std::cout << "[TensorRT] " << msg << std::endl;
    }
};
```

### 4.3 显存管理（RAII 模式）

**目标**：用 RAII 管理 GPU 显存，防止泄漏。

```cpp
template<typename T>
class DeviceBuffer {
    T* data_;
    size_t size_;
public:
    DeviceBuffer(size_t size) : size_(size) {
        cudaMalloc(&data_, size * sizeof(T));
    }
    ~DeviceBuffer() {
        if (data_) cudaFree(data_);
    }
    DeviceBuffer(const DeviceBuffer&) = delete;
    DeviceBuffer& operator=(const DeviceBuffer&) = delete;
    DeviceBuffer(DeviceBuffer&& other) noexcept
        : data_(other.data_), size_(other.size_) {
        other.data_ = nullptr;
    }
    T* get() { return data_; }
};
```

### 4.4 推理 Pipeline 实现

**目标**：实现从预处理到后处理的完整推理 Pipeline。

```cpp
class TRTInfer {
public:
    TRTInfer(const std::string& engine_path);
    ~TRTInfer();

    // 推理接口
    std::vector<float> infer(const std::vector<float>& input, 
                             const std::vector<int64_t>& shape);

private:
    void allocate_buffers();      // 分配 GPU 显存
    void preprocess(...);         // 数据预处理 (CPU)
    void copy_to_device(...);     // H2D 拷贝
    void run_inference();         // 执行推理
    void copy_to_host(...);       // D2H 拷贝
    void postprocess(...);        // 后处理

    Logger logger_;
    nvinfer1::IRuntime* runtime_ = nullptr;
    nvinfer1::ICudaEngine* engine_ = nullptr;
    nvinfer1::IExecutionContext* context_ = nullptr;
    cudaStream_t stream_ = nullptr;

    std::vector<void*> device_buffers_;
    std::vector<int64_t> input_shape_;
    std::vector<int64_t> output_shape_;
};
```

**完整推理流程**：
```
输入数据 → 预处理(CPU) → cudaMemcpy H2D → context->enqueueV3() → cudaMemcpy D2H → 后处理 → 输出
```

### 4.5 预处理与后处理加速

**目标**：将预处理放在 GPU 上，避免 CPU 瓶颈。

- 使用 CUDA kernel 或 NVIDIA DALI 做 GPU 预处理
- 常见操作：Resize、Normalize、BGR→RGB、HWC→CHW

```cpp
// 示例：GPU 上做 normalize
__global__ void normalize_kernel(
    float* input, int n, float scale,
    float mean_r, float mean_g, float mean_b) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < n) {
        input[idx] = (input[idx] * scale) - mean_r; // 简例
    }
}
```

---

## 阶段 5：生产级实践与性能调优

### 5.1 性能分析工具

| 工具 | 用途 |
|------|------|
| `trtexec` | TensorRT 命令行基准测试 |
| `nsys` (Nsight Systems) | 系统级 CPU/GPU 时序分析 |
| `ncu` (Nsight Compute) | Kernel 级性能分析 |
| `onnxruntime_perf_test` | ONNX Runtime 基准测试 |

```bash
# trtexec 基准测试
trtexec --onnx=model.onnx \
        --fp16 \
        --shapes=input:1x3x224x224 \
        --dumpProfile \
        --exportTimes=timing.json

# Nsight Systems 分析
nsys profile --stats=true ./trt_infer

# Nsight Compute 分析单个 kernel
ncu --kernel-name regex:.*conv.* ./trt_infer
```

### 5.2 常见性能瓶颈与优化策略

| 瓶颈 | 症状 | 优化方案 |
|------|------|----------|
| 数据拷贝 | H2D/D2H 耗时高 | 使用 pinned memory、CUDA Stream 重叠 |
| Kernel 启动开销 | 大量小 kernel | 算子融合、减少图节点 |
| 显存不足 | OOM | 使用 FP16/INT8、减小 batch size |
| 吞吐不足 | GPU 利用率低 | 多 Stream 并发、增大 batch size |
| 首帧延迟高 | 首次推理慢 | Engine 预热、persistent cache |
| 预处理瓶颈 | CPU 占用高 | GPU 预处理 (DALI/CUDA kernel) |

### 5.3 生产部署架构

```
                        ┌─────────────────┐
                        │   负载均衡 (LB)   │
                        └────────┬────────┘
                                 │
                 ┌───────────────┼───────────────┐
                 │               │               │
          ┌──────▼──────┐ ┌─────▼──────┐ ┌─────▼──────┐
          │  GPU Server │ │ GPU Server │ │ GPU Server │
          │  (Triton)   │ │ (Triton)   │ │ (Triton)   │
          └──────┬──────┘ └─────┬──────┘ └─────┬──────┘
                 │               │               │
          ┌──────▼──────┐       │               │
          │  Model Repo │◄──────┴───────────────┘
          │  (ONNX/TRT) │
          └─────────────┘
```

**推荐方案**：
- **小规模**：自建 C++ HTTP/gRPC 服务，内嵌 TensorRT
- **中大规模**：使用 NVIDIA Triton Inference Server
- **K8s 编排**：GPU Operator + Triton + HPA
- **边缘设备**：Jetson 系列 (Orin/Nano) + DeepStream

### 5.4 模型版本管理与 A/B 测试

```cpp
// 简单的版本化加载
class ModelRegistry {
    std::unordered_map<std::string, std::unique_ptr<TRTInfer>> engines_;
public:
    void load(const std::string& version, const std::string& path);
    TRTInfer* get(const std::string& version);
    void unload(const std::string& version);
};
```

---

## 推荐资源汇总

### 官方文档（必读）
- [TensorRT Developer Guide](https://docs.nvidia.com/deeplearning/tensorrt/developer-guide/)
- [TensorRT Python API](https://docs.nvidia.com/deeplearning/tensorrt/api/python_api/)
- [TensorRT C++ API](https://docs.nvidia.com/deeplearning/tensorrt/api/c_api/)
- [ONNX 官方文档](https://onnx.ai/onnx/)
- [ONNX Runtime](https://onnxruntime.ai/docs/)
- [NVIDIA Triton Inference Server](https://github.com/triton-inference-server/server)

### 示例代码
- [TensorRT Samples (官方)](https://github.com/NVIDIA/TensorRT/tree/main/samples)
- [ONNX Model Zoo](https://github.com/onnx/models)
- [TensorRT OSS](https://github.com/NVIDIA/TensorRT)

### 推荐书籍
- *Deep Learning Inference with TensorRT* (NVIDIA 官方电子书，自由下载)
- *Programming Massively Parallel Processors* — CUDA 深入理解

### 博客与文章
- [NVIDIA TensorRT 最佳实践](https://developer.nvidia.com/blog/speed-up-inference-tensorrt/)
- [ONNX 导出踩坑指南](https://pytorch.org/tutorials/advanced/super_resolution_with_onnxruntime.html)

### 视频课程
- [NVIDIA Deep Learning Institute — TensorRT](https://www.nvidia.com/en-us/deep-learning-ai/education/)
- [TensorRT 官方 Workshop](https://github.com/NVIDIA/trt-samples-for-hackathon-cn)

---

## 学习路线图（总览）

```
阶段 0: 前置知识              阶段 1: ONNX                   阶段 2: TensorRT Python
┌─────────────────┐      ┌─────────────────┐          ┌─────────────────────────┐
│ Python ✓        │      │ ONNX 概念        │          │ TensorRT 架构理解         │
│ C++ (基础)      │ ───► │ PyTorch→ONNX    │ ──────► │ Python API 构建 Engine    │
│ PyTorch ✓       │      │ 模型验证/调试    │          │ FP16/FP32 推理            │
│ CUDA 概念       │      │ Netron 可视化    │          │ CUDA Stream 管理          │
│ CMake 基础      │      │ onnx-simplifier │          │ 性能基准测试              │
└─────────────────┘      └─────────────────┘          └─────────────────────────┘
                                                                │
                                                                ▼
                               阶段 4: C++ 部署           阶段 3: TensorRT 进阶
                          ┌─────────────────────┐    ┌─────────────────────────┐
                          │ C++ Logger/Engine    │    │ INT8 校准                │
                          │ RAII 显存管理         │◄───│ 动态形状 (Dynamic Shape) │
                          │ 推理 Pipeline         │    │ 自定义 Plugin             │
                          │ 预处理 GPU 加速       │    │ 多 Stream 并发           │
                          │ Triton Server        │    │ trtexec 基准测试         │
                          └─────────────────────┘    └─────────────────────────┘
                                       │
                                       ▼
                              阶段 5: 生产级实践
                          ┌─────────────────────┐
                          │ Nsight 性能分析      │
                          │ 瓶颈定位与优化       │
                          │ 模型版本管理         │
                          │ Triton/K8s 部署     │
                          │ 边缘设备 (Jetson)   │
                          └─────────────────────┘
```

---

## 建议的 8 周学习计划

| 周次 | 内容 | 目标产出 |
|------|------|----------|
| W1 | 阶段 0 + 阶段 1.1-1.2 | 完成 ResNet → ONNX 导出 |
| W2 | 阶段 1.3-1.4 | 掌握 ONNX 调试与验证 |
| W3 | 阶段 2 | TensorRT Python API 完成 FP16 推理 |
| W4 | 阶段 3.1-3.2 | INT8 校准 + 动态形状 |
| W5 | 阶段 3.3-3.4 | 多流并发 / Custom Plugin |
| W6 | 阶段 4.1-4.3 | C++ 环境搭建 + Engine 加载 |
| W7 | 阶段 4.4-4.5 | 完整 C++ Pipeline + GPU 预处理 |
| W8 | 阶段 5 | 性能调优 + Triton 部署 |

---

> **提示**：这个学习路径假设每天投入 2-3 小时。重点在于动手实践 — 每个阶段都必须亲手写代码、跑模型、看 profile 结果。理论看懂 ≠ 会用，能用 C++ 从零部署一个优化过的模型才算真正掌握。
