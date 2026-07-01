# Procedure Manual: Running YOLOv7 on the Kria KV260 (Vitis AI 3.5 / PyTorch Flow)

This manual walks through the complete flow: quantizing and compiling YOLOv7 on a host PC (Ubuntu 24.04), then running inference on the DPU of a Kria KV260 (Ubuntu 22.04). It is based on an internal "Kria KV260 setup memo," with the content verified and reinforced against official documentation and current working examples.

---

## 0. Versions and the Big Picture

### 0.1 YOLO version choice: **YOLOv7**

For the requirement "latest but stable," this manual uses **YOLOv7**. The reasons:

- **YOLOv7 is included in AMD's Vitis AI Copyleft Model Zoo**, which provides training and quantization scripts. There is an established track record on the DPUCZDX8G (the DPU the KV260 uses).
- It is a PyTorch implementation and works well with the Vitis AI PyTorch quantization flow (`vai_q_pytorch`).
- Full workflows — from transfer learning on COCO/VOC to deployment — are widely shared.

**Comparison with other versions (for reference)**

| Model | Positioning | Stability on KV260 |
|---|---|---|
| YOLOv5 (Ultralytics) | An even more conservative option. KV260 quantization tutorials for Vitis AI 3.0 are well established | ◎ Most mature |
| **YOLOv7 (this manual)** | Recent yet Model-Zoo-backed with a solid track record | ◎ Best balance |
| YOLOX | Anchor-free. Working examples exist for Vitis AI 3.5 + KV260 | ○ |
| YOLOv8 / v11 | Newest, but introduces new operators (e.g. `C2f`) that the DPU does not natively support, requiring custom-operator handling | △ Not recommended at this time |

> **Note:** If you want the lowest possible risk, you can swap in YOLOv5 — the flow in this manual (especially Part C onward) applies almost unchanged. Conversely, v8/v11 fall outside the "stable" requirement, so they are not covered here.

### 0.2 Target environment

| Category | Item | Value |
|---|---|---|
| Host PC | OS | Ubuntu 24.04 |
| | GPU | NVIDIA (e.g. RTX A4000) with driver installed |
| | Prerequisites | Docker / NVIDIA Container Toolkit already set up |
| | Vitis AI | **3.5** (PyTorch GPU container) |
| KV260 | OS | Ubuntu 22.04 (Certified Ubuntu for Xilinx Devices) |
| | DPU | DPUCZDX8G **B4096** (`benchmark-b4096` overlay) |

### 0.3 Overall flow

```
[Host PC / Ubuntu 24.04]
  A. Build the Vitis AI 3.5 environment (build the PyTorch GPU Docker image)
  B. Set up YOLOv7 (obtain, prepare data, adapt the model for the DPU)
  C. Quantization (calibration -> export xmodel -> compile)
        │  Output: yolov7_kv260.xmodel
        ▼  transfer via scp
[KV260 / Ubuntu 22.04]
  D. Setup (write image -> update FW -> update packages -> load DPU -> runtime)
  E. Run inference (sanity check -> run custom YOLOv7 -> post-processing -> benchmark)
```

### 0.4 ⚠️ Most important: the version-compatibility rule

The majority of KV260 problems come from **version mismatches**. **Make sure you understand this before starting.**

1. **DPU architecture must match** — The `arch.json` you specify at compile time (B4096 in this manual) must match the DPU overlay actually loaded on the KV260. A mismatch causes a **fingerprint mismatch** failure at runtime.
2. **VART version must match** — The Vitis AI version used to compile the xmodel (3.5 here) must match the VART (Vitis AI Runtime) version on the KV260. The default VART on the stock Ubuntu 22.04 image is **2.5**, so a model compiled with 3.5 will not run as-is (addressed in D-7).

> **Note (official guidance):** AMD recommends **Vitis AI 3.0** for evaluating MPSoC/KV260, while 3.5 primarily targets the Versal family. That said, the 3.5 toolchain (Quantizer / Compiler / VART) can be used with the KV260 (DPUCZDX8G). This manual standardizes on 3.5 to match the source memo, but **a setup where both the host and the KV260 use 3.0 works with this procedure too** (just read the version numbers below as 3.0).

---

# Part A: Host PC — Building the Vitis AI 3.5 Environment

> All work here is done on the host PC (Ubuntu 24.04).

## A-1. Verify prerequisites

```bash
# NVIDIA driver
nvidia-smi

# Docker
docker --version
docker run --rm hello-world

# NVIDIA Container Toolkit (required to use the GPU from containers)
docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi
```

If the last command shows `nvidia-smi` output from inside the container, GPU passthrough is working. If not, install `nvidia-container-toolkit` and run `sudo systemctl restart docker`.

## A-2. Clone the Vitis AI repository (3.5)

```bash
mkdir -p ~/kv260_project/Vitis/vitis_r3.5
cd ~/kv260_project/Vitis/vitis_r3.5
git clone -b v3.5 https://github.com/Xilinx/Vitis-AI
cd Vitis-AI
```

## A-3. (If needed) Fix the conda install script

If the Docker image build fails at the conda-download step, the cause is an expired `Mambaforge` distribution URL. Replace it with the **Miniforge latest URL** as shown below.

Target file: `docker/common/install_conda.sh`

```bash
# Old (may be expired):
#   wget --progress=dot:mega \
#     https://github.com/conda-forge/miniforge/releases/download/4.10.3-5/Mambaforge-4.10.3-5-Linux-x86_64.sh \
#     -O miniconda.sh
#
# New:
    wget --progress=dot:mega \
      https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh \
      -O miniconda.sh
```

> If the build completes without issues, this fix is unnecessary. Try A-4 first; apply this fix and re-run only if it fails.

## A-4. Build the PyTorch GPU Docker image

```bash
cd ~/kv260_project/Vitis/vitis_r3.5/Vitis-AI/docker
./docker_build.sh -t gpu -f pytorch
```

- `-t gpu`: GPU-enabled image (accelerates calibration during quantization with CUDA)
- `-f pytorch`: PyTorch framework variant
- Time required: **roughly 30 minutes** (depends on network and machine)

Verify after completion:

```bash
docker images | grep vitis-ai
# e.g.:
# xilinx/vitis-ai-pytorch-gpu   3.5.0.001-xxxxxxxxx   ...
# xilinx/vitis-ai-pytorch-gpu   latest                ...
```

## A-5. Sanity check

```bash
docker run --rm --gpus all -it xilinx/vitis-ai-pytorch-gpu:latest bash
```

Inside the container:

```bash
conda activate vitis-ai-pytorch
python -c "import torch; print('CUDA available:', torch.cuda.is_available())"
# -> "CUDA available: True" means success
exit
```

For subsequent work sessions, `docker_run.sh` conveniently mounts the `Vitis-AI` directory as `/workspace`.

```bash
cd ~/kv260_project/Vitis/vitis_r3.5/Vitis-AI
./docker_run.sh xilinx/vitis-ai-pytorch-gpu:latest
# -> Confirm you land in /workspace inside the container
```

---

# Part B: Setting Up YOLOv7

> From here, work is done primarily inside the host Docker container (the `vitis-ai-pytorch` environment). You may also perform only the training step in a separate environment.

## B-1. Obtain YOLOv7 and the weights

Create a working directory under `/workspace` (this location is also visible on the host side).

```bash
cd /workspace
mkdir -p yolov7_kv260 && cd yolov7_kv260
git clone https://github.com/WongKinYiu/yolov7
cd yolov7

# Get pretrained weights (COCO). Use these as the starting weights for transfer learning on custom data.
wget https://github.com/WongKinYiu/yolov7/releases/download/v0.1/yolov7.pt
```

> **Using the Model Zoo version:** AMD's Copyleft Model Zoo (reachable from `Vitis-AI/model_zoo` as a separate repository) also provides a full set of YOLOv7 training/quantization scripts. Because DPU-oriented modifications are already included, it saves you the effort in B-3. If you are not using a custom dataset, the Model Zoo version is the fastest path.

## B-2. Prepare the dataset

Prepare the following depending on your use case:

- **Training data**: COCO or a custom dataset (YOLO-format labels). For transfer learning on custom data, create `data/custom.yaml` and train with `train.py`.
- **Calibration data**: about **200 representative images** for quantization. A subset of your train/validation set is fine. The preprocessing (resize, normalization) must exactly match what is used at inference time.

```bash
# Example: prepare just 200 images for calibration
mkdir -p /workspace/yolov7_kv260/calib_images
# (Copy ~200 representative images from your train/validation set)
```

## B-3. ⚠️ Adapt the model for the DPU (separate the detection head)

The YOLOv7 detection head (`IDetect` / `Detect`) includes grid/anchor decoding and `sigmoid`, which involve **operators the DPU does not natively support**. Therefore:

> **Put the backbone + neck + detection conv layers (the three raw feature maps) on the DPU, and perform the anchor decoding, coordinate decoding, and NMS as CPU-side post-processing.** This is the standard approach.

Concretely, at export time make the detection head return the "raw conv outputs (for the three scales)." In YOLOv7, use the **export mode** built into the detection module, or replace `forward` so it stops before decoding.

```python
# Example: set this right after loading the model in the quantization script
model.model[-1].export = True   # detection head returns raw conv outputs instead of decoding
model.eval()
```

With this, the generated xmodel terminates at three output nodes (the detection convs for each scale). **You will use these three output names later in the KV260-side post-processing and `.prototxt` configuration**, so record them during the Netron check (C-5).

## B-4. Verify the float model

After the modification, run inference on a single image with the float (pre-quantization) model and confirm it detects correctly, including post-processing (CPU decode + NMS). Anything that does not work correctly here will not work after quantization.

---

# Part C: Quantization and Compilation

> Run this inside the host Docker container (`vitis-ai-pytorch`). Vitis AI's PyTorch quantization API is `pytorch_nndct` (`vai_q_pytorch`).

## C-1 to C-3. Skeleton of the quantization script

Below is a minimal reference of the standard `vai_q_pytorch` flow (save it as `quantize_yolov7.py`). Adapt the actual data loader and preprocessing to the YOLOv7 implementation.

```python
import argparse, torch
from pytorch_nndct.apis import torch_quantizer
# from models.experimental import attempt_load  # YOLOv7 loader, etc.

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--quant_mode', choices=['calib', 'test'], required=True)
    p.add_argument('--deploy', action='store_true')
    p.add_argument('--subset_len', type=int, default=200)
    p.add_argument('--batch_size', type=int, default=1)
    p.add_argument('--model_path', default='yolov7.pt')
    p.add_argument('--data_dir', default='calib_images')
    p.add_argument('--device', default='cuda')
    args = p.parse_args()

    device = torch.device(args.device)

    # 1) Load the model and switch the detection head to export mode for the DPU (see B-3)
    model = load_yolov7(args.model_path)          # provide per your implementation
    model.model[-1].export = True
    model = model.to(device).eval()

    # 2) Dummy input (match the training input size, e.g. 640x640)
    dummy = torch.randn(1, 3, 640, 640, device=device)

    # 3) Create the quantizer
    quantizer = torch_quantizer(args.quant_mode, model, (dummy), device=device)
    quant_model = quantizer.quant_model

    # 4) Calibration or evaluation loop (keep preprocessing identical to inference time)
    loader = build_calib_loader(args.data_dir, args.subset_len, args.batch_size)
    with torch.no_grad():
        for imgs in loader:
            quant_model(imgs.to(device))

    # 5) Export the quantization config (calib) / export the xmodel (deploy)
    if args.quant_mode == 'calib':
        quantizer.export_quant_config()
    if args.deploy:
        quantizer.export_xmodel(output_dir='quantize_result', deploy_check=True)

if __name__ == '__main__':
    main()
```

**Run order**

```bash
# (1) Calibration (collect statistics)
python quantize_yolov7.py --quant_mode calib \
    --data_dir calib_images --subset_len 200 --batch_size 1 \
    --model_path yolov7.pt

# (2) Test + export xmodel (★ batch_size=1 and a single iteration are required)
python quantize_yolov7.py --quant_mode test \
    --subset_len 1 --batch_size 1 --deploy \
    --model_path yolov7.pt
```

- **`--deploy` must be used together with `--quant_mode test`**, and with **`--batch_size 1`** (a constraint of xmodel export).
- On success, the following are generated in `quantize_result/`:
  - `Yolov7_int.xmodel` (the quantized model for deployment)
  - `Yolov7_int.py` / `quant_info.json` (for evaluation/reproduction — keep these)

> **Accuracy check (recommended):** Measure the validation-set mAP with the quantized model and confirm the drop from the float version is acceptable. If the drop is large, increase the number of calibration images, enable `fast_finetune` (PTQ fine-tuning), or consider QAT (quantization-aware retraining).

## C-4. Compile for the DPU (xmodel -> KV260 executable xmodel)

```bash
vai_c_xir \
  -x quantize_result/Yolov7_int.xmodel \
  -a /opt/vitis_ai/compiler/arch/DPUCZDX8G/KV260/arch.json \
  -o ./compiled_kv260 \
  -n yolov7_kv260
```

- `-a`: the **architecture file for the KV260**. The path above is the standard one inside the Vitis AI container (corresponds to B4096). **It must match the DPU you load on the KV260 (Part D).**
- Output: `compiled_kv260/yolov7_kv260.xmodel`

## C-5. Verify the output and prepare the prototxt

- Open `yolov7_kv260.xmodel` in **Netron** (https://netron.app/) and record the **three output node names** (e.g. the nodes just before `fix2float` for each scale). You will use these names in post-processing and configuration.
- If you run it via the Vitis AI Library samples, prepare a `yolov7_kv260.prototxt` with the same name as the model, specifying the input `mean` / `scale`, number of classes, anchors, etc. (Using the prototxt of a pre-compiled YOLO as a template is the safest approach.) Note that the **channel order is B, G, R**.

You now have the host-side artifacts: `yolov7_kv260.xmodel` (and `.prototxt`).

---

# Part D: KV260 — Ubuntu 22.04 Setup

> From here, work is done on the KV260 itself (and on the host used to write the SD card).

## D-1. Obtain the OS image

From the AMD site (https://ubuntu.com/download/amd), get **Ubuntu Desktop 22.04 LTS** (Certified Ubuntu for Xilinx Devices).

```
iot-limerick-kria-classic-desktop-2204-20240304-165.img
```

> **Note:** KV260 applications support **Ubuntu 22.04 only**; 24.04 is not supported (this is separate from the 24.04 on the host).

## D-2. Check the boot firmware (not needed for units purchased in 2025)

The KV260 used in this procedure was **purchased in 2025**, so its factory boot FW is newer than 2022.1 and **no FW update is required**. You can skip D-2 and go straight to D-3.

> **For reference (only if using an older unit):** The Ubuntu 22.04 image will not boot unless the KV260 boot FW is 2022.1 or newer (it will not boot on the old 2021.1 FW). On an older or unknown unit, first boot a working image such as PetaLinux, **update to the 2022.1 boot FW**, then write 22.04. If it stops booting, recover with the standalone FW update & recovery utility (via BOOT.BIN).

## D-3. Write to the SD card

On Ubuntu, use **`dd`**. Balena Etcher often fails with an error when writing on Ubuntu, so `dd` is the reliable method here.

```bash
# Decompress
unxz iot-limerick-kria-classic-desktop-2204-20240304-165.img.xz

# Check the target device (never mistake the write target)
lsblk

# Write (replace /dev/sdX with your device)
sudo dd if=iot-limerick-kria-classic-desktop-2204-20240304-165.img \
        of=/dev/sdX bs=4M status=progress
sync
sudo eject /dev/sdX
```

> **Note:** On Ubuntu, Balena Etcher can error out when writing (even with `./balena-etcher --no-sandbox`). If you need a GUI tool, run it from a non-Ubuntu machine; on Ubuntu, use the `dd` method above.

## D-4. First boot and login

Connect **HDMI, keyboard, and a LAN cable** to the KV260, insert the SD card, and power on.

- Default login: user `ubuntu` / password `ubuntu`
- You will be prompted to **change the password** on first login.

## D-5. Update packages (add PPAs)

```bash
sudo add-apt-repository ppa:xilinx-apps --yes
sudo add-apt-repository ppa:ubuntu-xilinx/default --yes
sudo add-apt-repository ppa:xilinx-apps/xilinx-drivers --yes
sudo apt update --yes
sudo apt upgrade --yes
```

- This can take **10–20 minutes**. A reboot afterward is recommended.

> **Note (`upgrade` vs `full-upgrade`):** As in AMD's official first-boot instructions (and the source memo), `apt upgrade` is sufficient. `full-upgrade` (formerly `dist-upgrade`) differs in that it will add or remove packages to resolve dependencies, and because it can remove packages it is not the default choice for a board image. Use `sudo apt full-upgrade --yes` only if `apt upgrade` reports packages that are "kept back" (often the kernel or `xlnx-firmware`) and you want those updated as well.

(If you also want Docker on the KV260)

```bash
sudo apt install -y docker.io
sudo groupadd docker 2>/dev/null; sudo usermod -aG docker $USER
# Log out and back in for this to take effect
```

## D-6. Install and load the DPU overlay (B4096)

Since the host-side compilation used the **B4096 `arch.json`**, load the **B4096 DPU** on the KV260 as well.

```bash
# Install the firmware that contains the B4096 DPU
sudo apt install xlnx-firmware-kv260-benchmark-b4096

# Check the currently loaded app -> unload -> load B4096
sudo xmutil listapps
sudo xmutil unloadapp
sudo xmutil loadapp kv260-benchmark-b4096
```

Check the DPU and runtime status:

```bash
sudo xmutil listapps           # is kv260-benchmark-b4096 active?
xdputil query                  # shows the DPU architecture (B4096) and VART version
```

> In the `xdputil query` output, confirm the **DPU Arch is B4096** and note the **VAI Version (libvart, etc.)**. The VART version shown here must match the host side (3.5) in D-7.

## D-7. ⚠️ Align the VART / Vitis AI runtime (match 3.5)

The default VART on the stock Ubuntu 22.04 image is **2.5**. **An xmodel compiled with 3.5 will not run under VART 2.5 as-is.** Use one of the following to align the KV260-side runtime to 3.5.

**Approach A (recommended): install the Vitis AI 3.5 target runtime**
Following AMD's MPSoC board-setup procedure, install the **VART / Vitis AI Library runtime packages** from the Vitis AI 3.5 release onto the KV260 rootfs (`dpkg -i` the `.deb` files, or run a 3.5 aarch64 runtime container on the device). A typical launch command for running a container on the device (mounting the DPU, firmware, and vart.conf) is:

```bash
sudo docker run \
  --env="DISPLAY" -h "xlnx-docker" \
  --env="XDG_SESSION_TYPE" --net=host --privileged \
  --volume="$HOME/.Xauthority:/root/.Xauthority:rw" \
  -v /tmp:/tmp -v /dev:/dev -v /sys:/sys \
  -v /etc/vart.conf:/etc/vart.conf \
  -v /lib/firmware/xilinx:/lib/firmware/xilinx \
  -v /run:/run \
  -it <vitis-ai-3.5 runtime image:aarch64> bash
```

**Approach B (alternative): standardize the host and board on Vitis AI 3.0**
Aligning both sides to 3.0 — which AMD recommends for KV260/MPSoC evaluation — makes it easier to match the target runtime (the `vitis_ai_runtime_r3.0.x` family). Rebuild by reading the version numbers in Parts A and C as 3.0.

**Debug fallback: temporarily disable the fingerprint check**

```bash
export XLNX_ENABLE_FINGERPRINT_CHECK=0
```

This temporarily bypasses a DPU-configuration fingerprint mismatch, but **it does not resolve a VART version mismatch**. Use it only for isolating problems.

---

# Part E: Running Inference on the KV260

## E-1. Transfer the artifacts

Transfer `yolov7_kv260.xmodel` (and the `.prototxt`, post-processing script, and test images) from the host to the KV260.

```bash
# Run on the host (replace with the KV260's IP)
scp compiled_kv260/yolov7_kv260.xmodel \
    yolov7_kv260.prototxt \
    ubuntu@<KV260_IP>:~/yolov7_kv260/
```

## E-2. Sanity check first (strongly recommended)

Before running your custom model, run one of the **KV260 pre-compiled YOLO models from the Model Zoo** to first confirm that "DPU loaded + runtime" is in a healthy state. Once this passes, you can narrow any further problems down to your own xmodel.

```bash
# Example: a Vitis AI Library sample (place a pre-compiled model and run it)
# Example model destination:
#   /usr/share/vitis_ai_library/models/<model_name>/
# Run (a YOLO sample with image input):
#   ./test_jpeg_yolov3 <model_name> sample.jpg    etc.
```

If detection results appear correctly, the DPU and VART are healthy.

## E-3. Run inference with the custom YOLOv7 xmodel (VART / Python)

Run the model using VART's Python API (`vart` / `xir`). The skeleton is as follows.

```python
import xir, vart, numpy as np

# 1) Deserialize the xmodel and get the DPU subgraph
graph = xir.Graph.deserialize("yolov7_kv260.xmodel")
subgraphs = [s for s in graph.get_root_subgraph().toposort_child_subgraph()
             if s.has_attr("device") and s.get_attr("device").upper() == "DPU"]
runner = vart.Runner.create_runner(subgraphs[0], "run")

# 2) Input/output tensor info
in_tensors  = runner.get_input_tensors()
out_tensors = runner.get_output_tensors()   # YOLOv7 has 3 outputs (3 scales)

# 3) Preprocessing (★ must exactly match the host quantization: resize, BGR, normalization)
input_data = preprocess("sample.jpg")        # match the shape to in_tensors[0]

# 4) Asynchronous execution
out_buffers = [np.empty(tuple(t.dims), dtype=np.float32, order="C") for t in out_tensors]
job_id = runner.execute_async([input_data], out_buffers)
runner.wait(job_id)

# 5) Proceed to post-processing (E-4): decode + NMS on out_buffers (raw conv outputs of 3 scales)
detections = yolov7_decode_and_nms(out_buffers, anchors, conf_th=0.25, iou_th=0.45)
```

## E-4. Post-processing (decode + NMS on the CPU)

Because the detection head was separated in B-3, the DPU output is the **raw feature maps for each scale**. Implement the following on the CPU:

1. Reshape each scale's output into `[grid_y, grid_x, anchor, (x, y, w, h, obj, classes...)]`.
2. **Reconstruct the bounding boxes** using the anchors and grid (match the YOLOv7 decode equations).
3. Threshold by the `objectness × class` score.
4. **NMS** (remove duplicates by IoU threshold).
5. Scale back to the original image coordinates and draw.

> The decode equations, anchor values, and input size must **exactly match those used at training and quantization time.** If they are off, you end up in a "runs but detections are wrong" state.

## E-5. Verify results and benchmark

- Visually confirm on representative images that the detection results are consistent with the float version.
- Measure throughput (FPS) and latency. You can increase throughput with multi-threading (multiple Runners).

---

# Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| KV260 does not boot | Boot FW still at 2021.1 | Update FW to 2022.1 or newer (D-2). Recover via BOOT.BIN |
| fingerprint mismatch at runtime | `arch.json` (B4096) does not match the loaded DPU | Check the loaded DPU (`xdputil query`) and load B4096 (D-6), or recompile with a matching arch.json |
| Model loads but results are abnormal / segfault | VART version mismatch, or `.prototxt` misconfiguration (scale, output node names, BGR order) | Align VART to 3.5 (D-7). Re-check output node names in Netron and fix the prototxt (C-5) |
| Docker image build fails at conda | Expired Mambaforge URL | Fix `install_conda.sh` to Miniforge latest (A-3) |
| GPU not visible from the container | NVIDIA Container Toolkit not configured | Install the toolkit -> `sudo systemctl restart docker` (A-1) |
| xmodel export fails | Ran `--deploy` in calib mode, or batch > 1 | Run with `--quant_mode test --batch_size 1 --deploy` (C-3) |
| Detection works but accuracy is low | Quantization degradation | Increase calibration images, use `fast_finetune`, or consider QAT (C-3) |
| GUI interferes with the DPU app | Desktop consumes resources | `sudo xmutil desktop_disable` (work over SSH) |

---

# Appendix

## A. Rationale for the version choices (summary)

- **YOLOv7**: Included in AMD's Vitis AI Copyleft Model Zoo, with official training/quantization assets for the DPUCZDX8G. Good affinity with the PyTorch flow. -> The sweet spot of "recent × stable."
- **Vitis AI 3.5 (this manual)**: Matches the source memo's configuration. The toolchain is usable with the KV260. However, AMD recommends 3.0 for MPSoC evaluation, so **standardizing both sides on 3.0 is equally valid**.
- **DPU is B4096**: The standard KV260 configuration. Load it with the `benchmark-b4096` overlay and compile with the same `arch.json` to keep them aligned.
 
## B. Official documentation
 
- Vitis AI (GitHub main / releases): https://github.com/Xilinx/Vitis-AI
- Vitis AI 3.5 documentation: https://xilinx.github.io/Vitis-AI/3.5/html/index.html
- Kria KV260 apps / board setup: https://xilinx.github.io/kria-apps-docs/
- Certified Ubuntu for Xilinx Devices (images): https://ubuntu.com/download/amd

---

*Keep coming back — both before you start and while debugging — to the single most decisive point: the three versions (DPU architecture, VART, and `arch.json`) must all be aligned.*
