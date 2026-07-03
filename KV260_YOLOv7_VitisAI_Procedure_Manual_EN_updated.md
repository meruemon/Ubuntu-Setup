# Procedure Manual: Running a Pretrained YOLOv7 on the Kria KV260 with Real-Time USB Camera Inference (Vitis AI 3.5 / PyTorch Flow)

This manual walks through the complete flow for taking a **pretrained** YOLOv7 model (no fine-tuning), quantizing and compiling it on a host PC (Ubuntu 24.04), then running **real-time inference from a USB camera** on the DPU of a Kria KV260 (Ubuntu 22.04).

The goal is deliberately narrow: **get an off-the-shelf, COCO-pretrained YOLOv7 running live on the KV260's DPU.** There is no transfer learning and no custom dataset — only quantization, compilation, and deployment of an existing model.

---

## 0. Versions and the Big Picture

### 0.1 YOLO version choice: **YOLOv7**

For the requirement "latest but stable," this manual uses **YOLOv7**. The reasons:

- **YOLOv7 is included in AMD's Vitis AI Copyleft Model Zoo**, which provides quantization scripts and has an established track record on the DPUCZDX8G (the DPU the KV260 uses).
- It is a PyTorch implementation and works well with the Vitis AI PyTorch quantization flow (`vai_q_pytorch`).
- Full deployment workflows are widely shared.

**Comparison with other versions (for reference)**

| Model | Positioning | Stability on KV260 |
|---|---|---|
| YOLOv5 (Ultralytics) | An even more conservative option. KV260 quantization tutorials for Vitis AI 3.0 are well established | ◎ Most mature |
| **YOLOv7 (this manual)** | Recent yet Model-Zoo-backed with a solid track record | ◎ Best balance |
| YOLOX | Anchor-free. Working examples exist for Vitis AI 3.5 + KV260 | ○ |
| YOLOv8 / v11 | Newest, but introduces new operators (e.g. `C2f`) that the DPU does not natively support, requiring custom-operator handling | △ Not recommended at this time |

> **Note:** If you want the lowest possible risk, you can swap in YOLOv5 — the flow from Part C onward applies almost unchanged. Conversely, v8/v11 fall outside the "stable" requirement, so they are not covered here.

### 0.2 Target environment

Because this manual only quantizes and deploys a pretrained model (no training), the host needs a GPU only to accelerate calibration during quantization — and even that is optional; CPU calibration on ~50–200 images is entirely acceptable. **A recent NVIDIA GPU that is supported by the Vitis AI 3.5 container's bundled PyTorch (1.13, CUDA 11.x) is assumed. Avoid GPUs whose architecture is too new for that PyTorch build** (this is why we do not target the very newest consumer GPUs here); if your GPU is unsupported, fall back to CPU calibration.

| Category | Item | Value |
|---|---|---|
| Host PC | OS | Ubuntu 24.04 |
| | GPU | NVIDIA, supported by Vitis AI 3.5's bundled PyTorch (CUDA 11.x). Optional — CPU calibration works too |
| | Prerequisites | Docker / NVIDIA Container Toolkit already set up (only if using the GPU) |
| | Vitis AI | **3.5** (PyTorch container) |
| KV260 | OS | Ubuntu 22.04 (Certified Ubuntu for Xilinx Devices) |
| | DPU | DPUCZDX8G **B4096** (`benchmark-b4096` overlay) |
| | Runtime | **VART 2.5 inside a Docker container** (see D-7) |
| | Camera | USB UVC webcam (e.g. Logitech C270/C920), accessible as `/dev/video0` |

### 0.3 Overall flow

```
[Host PC / Ubuntu 24.04]
  A. Build the Vitis AI 3.5 environment (build the PyTorch Docker image)
  B. Obtain the pretrained YOLOv7 and adapt it for the DPU (no training)
  C. Quantization (calibration -> export xmodel -> compile with real-device fingerprint)
        │  Output: yolov7_kv260.xmodel
        ▼  transfer via scp
[KV260 / Ubuntu 22.04]
  D. Setup (write image -> load DPU -> bring up a Docker runtime with VART 2.5)
  E. Real-time inference from a USB camera (sanity check -> live capture -> decode + NMS -> display)
```

### 0.4 ⚠️ Most important: the version-compatibility rule

The majority of KV260 problems come from **version mismatches**. **Make sure you understand this before starting.**

1. **DPU fingerprint must match** — The `arch.json` you specify at compile time must produce an xmodel whose fingerprint matches the DPU overlay actually loaded on the KV260. The stock Vitis AI 3.5 `arch.json` targets a newer DPU and will **not** match the KV260's `DPUCZDX8G_ISA1_B4096`, causing a **fingerprint mismatch** at runtime. This manual solves it by specifying the **real device's fingerprint directly** (C-4).
2. **The runtime must be able to execute the xmodel** — The stock Ubuntu 22.04 apt `vitis-ai-runtime` is old (often **2.0**) and **segfaults** on a Vitis AI 3.5 xmodel; the apt `xdputil` is frequently missing entirely (`not found`). Rather than repairing the apt runtime, this manual **brings up a Docker container with VART 2.5** on the device (D-7). Once the DPU is the `DPUCZDX8G_ISA1_B4096` and the fingerprint matches, a 3.5-compiled xmodel runs correctly under VART 2.5, because the two are ISA-compatible for this DPU.

> **Note (official guidance):** AMD recommends **Vitis AI 3.0** for evaluating MPSoC/KV260, while 3.5 primarily targets the Versal family. The 3.5 toolchain (Quantizer / Compiler) can nonetheless be used with the KV260 (DPUCZDX8G). This manual standardizes on 3.5; **a setup where the host uses 3.0 works with this procedure too** (read the version numbers below as 3.0).

---

# Part A: Host PC — Building the Vitis AI 3.5 Environment

> All work here is done on the host PC (Ubuntu 24.04).

## A-1. Verify prerequisites

If you plan to use the GPU for calibration:

```bash
# NVIDIA driver
nvidia-smi

# Docker
docker --version
docker run --rm hello-world

# NVIDIA Container Toolkit (required to use the GPU from containers)
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

If the last command shows `nvidia-smi` output from inside the container, GPU passthrough is working. If not, install `nvidia-container-toolkit` and run `sudo systemctl restart docker`.

> **GPU compatibility note:** Vitis AI 3.5's container ships PyTorch 1.13 (CUDA 11.x). A GPU whose architecture is newer than what this PyTorch build supports will report a `sm_XXX is not compatible` error and fall back to CPU. Since this manual only calibrates on a small image set, **if in doubt, simply run calibration on CPU** — pass `--device cpu` in Part C and skip the `--gpus all` flag. There is no training here, so GPU acceleration is a convenience, not a requirement.

## A-2. Clone the Vitis AI repository (3.5)

```bash
mkdir -p ~/kv260_project/Vitis/vitis_r3.5
cd ~/kv260_project/Vitis/vitis_r3.5
git clone -b v3.5 https://github.com/Xilinx/Vitis-AI
cd Vitis-AI
```

## A-3. (If needed) Fix the conda install script

If the Docker image build fails at the conda-download step, the cause is an expired `Mambaforge` distribution URL. Replace it with the **Miniforge latest URL**.

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

## A-4. Build the PyTorch Docker image

For GPU-accelerated calibration:

```bash
cd ~/kv260_project/Vitis/vitis_r3.5/Vitis-AI/docker
./docker_build.sh -t gpu -f pytorch
```

If you will calibrate on CPU only, build the CPU image instead (smaller, no CUDA requirement):

```bash
./docker_build.sh -t cpu -f pytorch
```

- Time required: **roughly 30 minutes** (depends on network and machine).

Verify after completion:

```bash
docker images | grep vitis-ai
# e.g.:
# xilinx/vitis-ai-pytorch-gpu   3.5.0.001-xxxxxxxxx   ...
# xilinx/vitis-ai-pytorch-cpu   latest                ...
```

## A-5. Sanity check and launch

```bash
cd ~/kv260_project/Vitis/vitis_r3.5/Vitis-AI
./docker_run.sh xilinx/vitis-ai-pytorch-gpu:latest    # or the -cpu image
```

Inside the container:

```bash
conda activate vitis-ai-pytorch
python -c "import torch; print('CUDA available:', torch.cuda.is_available())"
# GPU image -> "True"; CPU image (or unsupported GPU) -> "False" is fine here
```

`docker_run.sh` mounts the `Vitis-AI` directory as `/workspace`, so files created there are visible on the host too.

---

# Part B: Obtaining the Pretrained YOLOv7 and Adapting It for the DPU

> Work is done inside the host Docker container (`vitis-ai-pytorch`). **There is no training in this manual** — we take the released COCO-pretrained weights as-is.

## B-1. Obtain YOLOv7 and the pretrained weights

```bash
cd /workspace
mkdir -p yolov7_kv260 && cd yolov7_kv260
git clone https://github.com/WongKinYiu/yolov7
cd yolov7

# COCO-pretrained weights — used directly, no fine-tuning
wget https://github.com/WongKinYiu/yolov7/releases/download/v0.1/yolov7.pt
```

The model detects the **80 COCO classes**. Keep the COCO class list handy for post-processing (E-4).

> **Using the Model Zoo version:** AMD's Copyleft Model Zoo (reachable from `Vitis-AI/model_zoo`) also provides YOLOv7 quantization scripts with DPU-oriented modifications already applied. Since we are not using a custom dataset, **the Model Zoo version is the fastest path** and can save you the work in B-3.

## B-2. Prepare calibration images

Quantization calibration needs a small set of representative images. Since the model is COCO-pretrained, use **~50–200 images from the COCO val set** (or any realistic images resembling what the USB camera will see). The preprocessing (resize to 640×640, normalization, channel order) must **exactly match** what you will use at inference time.

```bash
mkdir -p /workspace/yolov7_kv260/calib_images
# Copy ~50–200 representative images here.
```

> 50 images is enough to get a working model quickly (speed over accuracy). Use more (150–200) if you want to minimize the quantization accuracy drop.

## B-3. ⚠️ Adapt the model for the DPU (separate the detection head)

The YOLOv7 detection head (`IDetect` / `Detect`) performs grid/anchor decoding and `sigmoid`, which involve **operators the DPU does not natively support**. The standard approach:

> **Put the backbone + neck + detection conv layers (the three raw feature maps) on the DPU, and perform anchor decoding, coordinate decoding, and NMS as CPU-side post-processing.**

At export time, make the detection head return the "raw conv outputs for the three scales":

```python
# Set this right after loading the model in the quantization script
model.model[-1].export = True   # detection head returns raw conv outputs instead of decoding
model.eval()
```

The generated xmodel then terminates at **three output nodes** (the detection convs for each scale). **Record these three output names during the Netron check (C-5)** — you will use them in the KV260-side post-processing.

Additionally, YOLOv7 uses **SiLU** activations, which the DPU does not support natively. During quantization, convert them to a DPU-friendly form (see the calibration options in C-2).

## B-4. Verify the float model

Run inference on a single image with the float (pre-quantization) model, including CPU decode + NMS, and confirm it detects the COCO objects correctly. **Anything that does not work here will not work after quantization.**

---

# Part C: Quantization and Compilation

> Run this inside the host Docker container (`vitis-ai-pytorch`). Vitis AI's PyTorch quantization API is `pytorch_nndct` (`vai_q_pytorch`).

## C-1. Skeleton of the quantization script

Below is a minimal reference of the standard `vai_q_pytorch` flow (save as `quantize_yolov7.py`). Adapt the data loader and preprocessing to the YOLOv7 implementation. Note the `--device` option so you can run on CPU if your GPU is unsupported.

```python
import argparse, torch
from pytorch_nndct.apis import torch_quantizer

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--quant_mode', choices=['calib', 'test'], required=True)
    p.add_argument('--deploy', action='store_true')
    p.add_argument('--subset_len', type=int, default=200)
    p.add_argument('--batch_size', type=int, default=1)
    p.add_argument('--model_path', default='yolov7.pt')
    p.add_argument('--data_dir', default='calib_images')
    p.add_argument('--device', default='cuda')   # use 'cpu' if your GPU is unsupported
    args = p.parse_args()

    device = torch.device(args.device)

    # 1) Load the pretrained model, switch the detection head to export mode (see B-3)
    model = load_yolov7(args.model_path)          # provide per your implementation
    model.model[-1].export = True
    model = model.to(device).eval()

    # 2) Dummy input (match the inference input size, 640x640)
    dummy = torch.randn(1, 3, 640, 640, device=device)

    # 3) Create the quantizer
    quantizer = torch_quantizer(args.quant_mode, model, (dummy), device=device)
    quant_model = quantizer.quant_model

    # 4) Calibration / evaluation loop (preprocessing identical to inference time)
    loader = build_calib_loader(args.data_dir, args.subset_len, args.batch_size)
    with torch.no_grad():
        for imgs in loader:
            quant_model(imgs.to(device))

    # 5) Export quant config (calib) / export xmodel (deploy)
    if args.quant_mode == 'calib':
        quantizer.export_quant_config()
    if args.deploy:
        quantizer.export_xmodel(output_dir='quantize_result', deploy_check=True)

if __name__ == '__main__':
    main()
```

## C-2. Run order

```bash
# (1) Calibration (collect statistics). Convert SiLU -> DPU-friendly activation.
python quantize_yolov7.py --quant_mode calib \
    --data_dir calib_images --subset_len 50 --batch_size 1 \
    --model_path yolov7.pt --device cuda \
    --nndct_convert_silu_to_hswish \
    --nndct_convert_sigmoid_to_hsigmoid

# (2) Test + export xmodel (★ batch_size=1 and a single iteration are required)
python quantize_yolov7.py --quant_mode test \
    --subset_len 1 --batch_size 1 --deploy \
    --model_path yolov7.pt --device cuda
```

- `--nndct_convert_silu_to_hswish`: converts **SiLU (DPU-unsupported) → HSwish**. Essential for YOLOv7 on this DPU.
- `--deploy` **must** be paired with `--quant_mode test` and **`--batch_size 1`** (a constraint of xmodel export).
- If your GPU is unsupported, add `--device cpu` to both commands.
- On success, `quantize_result/` contains `Yolov7_int.xmodel` (deployment model) plus `Yolov7_int.py` / `quant_info.json` (keep these).

> **Accuracy check (recommended):** Compare detections against the float model on a few images. If the drop is large, increase calibration images, enable `fast_finetune` (PTQ fine-tuning), or (as a last resort) consider QAT. Since we are not training, prefer `fast_finetune` over QAT.

## C-3. Compile for the DPU with the real-device fingerprint

**This is the critical step.** The stock Vitis AI 3.5 `arch.json` (`/opt/vitis_ai/compiler/arch/DPUCZDX8G/KV260/arch.json`) targets a newer DPU and its fingerprint will **not** match the KV260's `DPUCZDX8G_ISA1_B4096`, producing a fingerprint mismatch at runtime. Compile against the **real device's fingerprint** instead.

First obtain the fingerprint from the board (after D-6 loads the DPU). The apt `xdputil` is typically **not installed** on the stock image, so read it from inside the Docker runtime — and note that `xdputil` needs the xclbin symlinked to `/usr/lib/dpu.xclbin` first (full procedure in **D-7-2**):

```bash
# On the KV260, from the Docker runtime (see D-7-2 for the required xclbin symlink):
xdputil query        # look for the fingerprint of DPUCZDX8G_ISA1_B4096
```

For the standard `kv260-benchmark-b4096` overlay the value is fixed (`0x101000016010407`), so you can compile with it directly and verify via the E-2 sanity check.

Then, on the host, compile with a hand-written arch.json containing that fingerprint:

```bash
echo '{"fingerprint":"0x101000016010407"}' > /tmp/kv260_arch.json

vai_c_xir \
  -x quantize_result/Yolov7_int.xmodel \
  -a /tmp/kv260_arch.json \
  -o ./compiled_kv260 \
  -n yolov7_kv260
```

Expected output:

```
Target: DPUCZDX8G_ISA1_B4096_0101000016010407
DPU subgraph: 1
```

- `0x101000016010407` is an **example**. **Always use your own device's fingerprint** from `xdputil query`; a single wrong digit causes a runtime mismatch.
- Output: `compiled_kv260/yolov7_kv260.xmodel`.

## C-4. Verify the output and prepare the prototxt

- Open `yolov7_kv260.xmodel` in **Netron** (https://netron.app/) and record the **three output node names** (one per scale). You will use these in post-processing.
- If you run it via the Vitis AI Library samples, prepare a `yolov7_kv260.prototxt` with the same base name, specifying input `mean` / `scale`, number of classes (80 for COCO), anchors, etc. **The channel order is B, G, R.**

You now have the host-side artifacts: `yolov7_kv260.xmodel` (and optionally `.prototxt`).

---

# Part D: KV260 — Ubuntu 22.04 Setup

> Work is done on the KV260 itself (and on the host used to write the SD card).

## D-1. Obtain the OS image

From the AMD/Ubuntu site (https://ubuntu.com/download/amd), get **Ubuntu Desktop 22.04 LTS** (Certified Ubuntu for Xilinx Devices), e.g.:

```
iot-limerick-kria-classic-desktop-2204-20240304-165.img
```

> **Note:** KV260 applications support **Ubuntu 22.04 only**; 24.04 is not supported (this is separate from the 24.04 on the host).

## D-2. Check the boot firmware (skip for units purchased in 2025)

A KV260 purchased in **2025** ships with factory boot FW newer than 2022.1, so **no FW update is required** — skip to D-3.

> **For older units only:** The 22.04 image will not boot on old 2021.1 FW. Boot a working image (e.g. PetaLinux), **update to 2022.1 boot FW**, then write 22.04. If it stops booting, recover with the standalone FW update & recovery utility via BOOT.BIN.

## D-3. Write to the SD card

On Ubuntu, use **`dd`** (Balena Etcher often errors out on Ubuntu).

```bash
unxz iot-limerick-kria-classic-desktop-2204-20240304-165.img.xz
lsblk                                    # identify the target device carefully
sudo dd if=iot-limerick-kria-classic-desktop-2204-20240304-165.img \
        of=/dev/sdX bs=4M status=progress    # replace /dev/sdX
sync
sudo eject /dev/sdX
```

## D-4. First boot and login

Connect **HDMI, keyboard, a LAN cable, and the USB camera**, insert the SD card, and power on.

- Default login: user `ubuntu` / password `ubuntu` (you will be prompted to change it).
- Confirm the camera is detected:

```bash
ls /dev/video*        # expect /dev/video0 (and possibly /dev/video1)
sudo apt install -y v4l-utils
v4l2-ctl --list-devices
v4l2-ctl -d /dev/video0 --list-formats-ext   # check supported resolutions/formats
```

## D-5. Update packages

```bash
sudo add-apt-repository ppa:xilinx-apps --yes
sudo add-apt-repository ppa:ubuntu-xilinx/default --yes
sudo add-apt-repository ppa:xilinx-apps/xilinx-drivers --yes
sudo apt update --yes
sudo apt upgrade --yes
```

- Takes **10–20 minutes**; reboot afterward.
- Install Docker on the KV260 (required for the runtime in D-7):

```bash
sudo apt install -y docker.io
sudo groupadd docker 2>/dev/null; sudo usermod -aG docker $USER
# Log out and back in for group membership to take effect
```

> **`upgrade` vs `full-upgrade`:** `apt upgrade` is sufficient per AMD's first-boot instructions. Use `sudo apt full-upgrade --yes` only if packages are "kept back" (often the kernel or `xlnx-firmware`) and you want them updated.

## D-6. Install and load the DPU overlay (B4096)

The host-side compilation targeted the B4096 fingerprint, so load the **B4096 DPU** on the KV260.

```bash
sudo apt install xlnx-firmware-kv260-benchmark-b4096

sudo xmutil listapps
sudo xmutil unloadapp
sudo xmutil loadapp kv260-benchmark-b4096
```

Confirm the DPU is `DPUCZDX8G_ISA1_B4096` and note its fingerprint (used in C-3). The apt `xdputil` is usually missing or broken on the stock image, so read the fingerprint from the Docker runtime — see **D-7-2** (it requires an xclbin symlink to work).

## D-7. ⚠️ VART / Vitis AI runtime (bring up a Docker runtime with VART 2.5)

The stock Ubuntu 22.04 apt `vitis-ai-runtime` is old (often **2.0**) and **segfaults** on a Vitis AI 3.5 xmodel; `xdputil query` itself may segfault. Rather than repairing the apt runtime, **bring up the official Xilinx Kria runtime Docker image (VART 2.5)** on the device. The host stays on Vitis AI 3.5.

### D-7-1. Prepare the runtime image

```bash
sudo docker pull xilinx/kria-runtime:2022.1

# Add the Python packages needed for camera inference, then persist the image
sudo docker run -d --name vai-builder xilinx/kria-runtime:2022.1 sleep 300
sudo docker exec vai-builder pip install opencv-python-headless numpy
sudo docker commit vai-builder vai-yolov7:v4
sudo docker rm -f vai-builder
```

`vai-yolov7:v4` now contains **VART 2.5 + numpy + OpenCV**, persisted for reuse.

> **Why a 3.5 xmodel runs under VART 2.5:** For `DPUCZDX8G_ISA1_B4096`, the xmodel is ISA-compatible across the 2.5/3.5 runtimes, and once the fingerprint (C-3) matches the loaded DPU, execution succeeds. What matters is **the xmodel's ISA and the device fingerprint matching** — not the VART version number.

### D-7-2. Read the fingerprint from the runtime

On the stock image the apt `xdputil` is often **not installed at all** (`xdputil: not found`), so read the fingerprint from the Docker runtime instead.

⚠️ **Important:** `xdputil` looks for the DPU xclbin at its hard-coded default path **`/usr/lib/dpu.xclbin`**, regardless of `XLNX_VART_FIRMWARE`. If that path is absent it aborts with `open(/usr/lib/dpu.xclbin) failed` (often shown as `xdputil: line 20: ... aborted`). **Symlink the real overlay xclbin to that path inside the container**, then query:

```bash
# First confirm the exact xclbin filename (overlay versions may differ)
ls -la /lib/firmware/xilinx/kv260-benchmark-b4096/

# Load the DPU (host side) if not already active
sudo xmutil unloadapp
sudo xmutil loadapp kv260-benchmark-b4096

# Query from inside the runtime, linking the xclbin to the path xdputil expects
sudo docker run --rm --privileged \
  -v /dev:/dev -v /run:/run -v /sys:/sys \
  -v /lib/firmware/xilinx:/lib/firmware/xilinx \
  vai-yolov7:v4 bash -c '
    ln -sf /lib/firmware/xilinx/kv260-benchmark-b4096/kv260-benchmark-b4096.xclbin /usr/lib/dpu.xclbin
    xdputil query
  '
```

The output reports `DPUCZDX8G_ISA1_B4096` and its fingerprint. **Feed that fingerprint back into the host compile step (C-3).** For the standard `kv260-benchmark-b4096` overlay this is a fixed value (`0x101000016010407`), so a `xdputil` failure never blocks compilation — you can compile with the known value and let the E-2 sanity check confirm it.

> **Persisting the link (optional):** the `--rm` container discards the symlink. If you want `xdputil` usable repeatedly, bake the link into the image:
> ```bash
> sudo docker run -d --name vai-fix vai-yolov7:v4 sleep 60
> sudo docker exec vai-fix bash -c \
>   'ln -sf /lib/firmware/xilinx/kv260-benchmark-b4096/kv260-benchmark-b4096.xclbin /usr/lib/dpu.xclbin'
> sudo docker commit vai-fix vai-yolov7:v5
> sudo docker rm -f vai-fix
> ```
> The inference path (E-5) passes `XLNX_VART_FIRMWARE` explicitly and does **not** depend on `/usr/lib/dpu.xclbin`, so this link is only needed for `xdputil` itself.

### (Alternatives) if the Docker runtime cannot be used

- **Alt A:** `dpkg -i` the Vitis AI 3.5 VART / Vitis AI Library `.deb` packages into the rootfs (dependency resolution is fiddly when apt is broken).
- **Alt B:** Standardize host **and** board on Vitis AI 3.0 (`vitis_ai_runtime_r3.0.x`), reading Parts A/C as 3.0.
- **Debug fallback:** `export XLNX_ENABLE_FINGERPRINT_CHECK=0` bypasses a fingerprint mismatch only; it does not fix a runtime execution problem. Isolation use only.

---

# Part E: Real-Time USB Camera Inference on the KV260

## E-1. Transfer the artifacts

```bash
# On the host (replace with the KV260's IP)
scp compiled_kv260/yolov7_kv260.xmodel \
    yolov7_camera.py \
    ubuntu@<KV260_IP>:~/yolov7_kv260/
```

## E-2. Sanity check first (strongly recommended)

Before the live pipeline, run a **pre-compiled Model Zoo YOLO** (or a single still image through your model) inside the runtime container to confirm "DPU loaded + VART healthy." Once a still image detects correctly, any remaining issues are isolated to the camera pipeline.

```bash
sudo xmutil unloadapp
sudo xmutil loadapp kv260-benchmark-b4096
```

## E-3. Real-time inference script (VART + OpenCV VideoCapture)

The live loop captures a frame, preprocesses it identically to calibration (resize 640×640, BGR, normalization), runs the DPU, decodes + NMS on the CPU, and displays the result. YOLOv7 has **3 output tensors** (3 scales).

```python
import sys, cv2, numpy as np, xir, vart

COCO = [ 'person','bicycle','car', ... ]  # 80 COCO class names

def load_runner(xmodel):
    g = xir.Graph.deserialize(xmodel)
    sub = [s for s in g.get_root_subgraph().toposort_child_subgraph()
           if s.has_attr("device") and s.get_attr("device").upper() == "DPU"]
    return vart.Runner.create_runner(sub[0], "run")

def preprocess(frame, size=640):
    img = cv2.resize(frame, (size, size))          # BGR, matches calibration
    img = img.astype(np.float32) / 255.0
    return np.expand_dims(img, 0).copy(order="C")

def main(xmodel, cam_index=0):
    runner = load_runner(xmodel)
    in_t  = runner.get_input_tensors()
    out_t = runner.get_output_tensors()            # 3 tensors

    cap = cv2.VideoCapture(cam_index)              # /dev/video0
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

    while True:
        ok, frame = cap.read()
        if not ok:
            break

        x = preprocess(frame)
        outs = [np.empty(tuple(t.dims), dtype=np.float32, order="C") for t in out_t]
        job = runner.execute_async([x], outs)
        runner.wait(job)

        # CPU post-processing: decode (anchors+grid) + NMS on the 3 raw feature maps
        dets = yolov7_decode_and_nms(outs, anchors, conf_th=0.25, iou_th=0.45)

        for (x1, y1, x2, y2, score, cls) in dets:
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
            cv2.putText(frame, f"{COCO[cls]} {score:.2f}", (x1, y1 - 5),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 1)

        cv2.imshow("YOLOv7 KV260", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main(sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else 0)
```

## E-4. Post-processing (decode + NMS on the CPU)

Because the detection head was separated in B-3, the DPU output is the **raw feature maps for each scale**. On the CPU:

1. Reshape each scale's output to `[grid_y, grid_x, anchor, (x, y, w, h, obj, 80 classes)]`.
2. **Reconstruct boxes** using the YOLOv7 anchors and grid (match the YOLOv7 decode equations exactly).
3. Threshold by `objectness × class` score.
4. **NMS** by IoU threshold.
5. Scale boxes back to the original frame coordinates and draw.

> The decode equations, anchor values, input size, and normalization must **exactly match** those used at quantization time. If they are off, you get a "runs but detections are wrong" state.

## E-5. Run the live pipeline

Launch the runtime container with the camera device, DPU, and firmware mounted, plus X11 for the display window.

```bash
#!/bin/bash
# run_camera.sh
XCLBIN=/lib/firmware/xilinx/kv260-benchmark-b4096/kv260-benchmark-b4096.xclbin
xhost +local:root >/dev/null 2>&1
sudo docker run --rm \
  -v /home/ubuntu/yolov7_kv260:/work \
  -v /dev:/dev \
  -v /run:/run \
  -v /lib/firmware/xilinx:/lib/firmware/xilinx \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -e DISPLAY=$DISPLAY \
  -e XLNX_VART_FIRMWARE=$XCLBIN \
  --privileged \
  --device /dev/video0 \
  -w /work \
  vai-yolov7:v4 \
  python3 /work/yolov7_camera.py /work/yolov7_kv260.xmodel 0
```

```bash
bash ~/run_camera.sh
```

- `--device /dev/video0` exposes the USB camera to the container.
- The X11 mounts let `cv2.imshow` open a window on the KV260's HDMI display. If running headless over SSH, drop the display and instead write annotated frames to disk or stream them (e.g. MJPEG), or use `cv2.imwrite` per frame.

## E-6. Verify and benchmark

- Confirm live detections on real objects match the float model's behavior.
- Measure end-to-end FPS (capture → preprocess → DPU → decode/NMS → draw). If the CPU post-processing dominates, move decode/NMS to vectorized NumPy or run multiple `vart.Runner` instances for the DPU stage.
- For higher throughput, decouple capture and inference with a small frame queue (producer/consumer threads) so the camera never blocks the DPU.

---

# Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| KV260 does not boot | Boot FW at 2021.1 | Update to 2022.1+ (D-2); recover via BOOT.BIN |
| `fingerprint mismatch` at runtime | Stock 3.5 `arch.json` targets a newer DPU | Compile with the real device fingerprint (C-3) |
| apt runtime / `xdputil query` segfaults | apt `vitis-ai-runtime` 2.0 vs 3.5 xmodel | Use the VART 2.5 Docker runtime (D-7) |
| `xdputil: not found` | apt runtime not installed on the stock image | Run `xdputil` from the VART 2.5 Docker runtime (D-7-2) |
| `xdputil` aborts with `open(/usr/lib/dpu.xclbin) failed` | `xdputil` reads its hard-coded default xclbin path, which is empty | Symlink the overlay xclbin to `/usr/lib/dpu.xclbin` inside the container (D-7-2). Or skip it: compile with the known fingerprint `0x101000016010407` and verify via E-2 |
| Model loads but detections are wrong | SiLU not converted, or decode/anchors/normalization mismatch | Add `--nndct_convert_silu_to_hswish` (C-2); match decode + preprocessing exactly (E-4) |
| GPU not usable in container | GPU architecture newer than Vitis AI 3.5's PyTorch 1.13 | Calibrate on CPU (`--device cpu`); GPU is optional here |
| `/dev/video0` not found | Camera not enumerated | Check `v4l2-ctl --list-devices`; try another USB port; confirm UVC support |
| No display window in container | X11 not forwarded | Mount `/tmp/.X11-unix`, set `DISPLAY`, run `xhost +local:root` (E-5) |
| Docker image build fails at conda | Expired Mambaforge URL | Fix `install_conda.sh` to Miniforge latest (A-3) |
| xmodel export fails | `--deploy` in calib mode, or batch > 1 | Use `--quant_mode test --batch_size 1 --deploy` (C-2) |
| Low camera FPS | CPU post-processing bottleneck | Vectorize decode/NMS; producer/consumer threading (E-6) |
| GUI interferes with the DPU app | Desktop consumes resources | `sudo xmutil desktop_disable` (work over SSH) |

---

# Appendix

## A. Rationale for the version choices (summary)

- **YOLOv7 (pretrained, no fine-tuning):** In AMD's Vitis AI Copyleft Model Zoo with proven DPUCZDX8G support and good PyTorch-flow affinity. We deploy the COCO-pretrained weights directly — the sweet spot of "recent × stable" with the least effort.
- **Vitis AI 3.5 on the host, VART 2.5 (Docker) on the board:** The 3.5 compiler is usable for the KV260, and a Docker runtime avoids repairing the broken apt runtime. Standardizing both sides on 3.0 is equally valid.
- **DPU B4096 with real-device fingerprint:** The standard KV260 configuration. Compiling against the device's actual fingerprint is what keeps compile-time and runtime aligned.
- **CPU-friendly calibration:** Because there is no training, GPU acceleration is optional; unsupported GPUs simply fall back to CPU without affecting the result.

## B. Official documentation

- Vitis AI (GitHub): https://github.com/Xilinx/Vitis-AI
- Vitis AI 3.5 docs: https://xilinx.github.io/Vitis-AI/3.5/html/index.html
- Kria KV260 apps / board setup: https://xilinx.github.io/kria-apps-docs/
- Certified Ubuntu for Xilinx Devices: https://ubuntu.com/download/amd

---

*Keep coming back to the single most decisive point: the xmodel's DPU fingerprint, the loaded DPU overlay, and the runtime that executes it must all be aligned. For this build that means — compile with the real B4096 fingerprint (C-3), load the B4096 overlay (D-6), and run under the VART 2.5 Docker runtime (D-7).*
