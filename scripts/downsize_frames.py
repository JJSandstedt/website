#!/usr/bin/env python3
"""
Build web-friendly ERP animation frames for the MInDReading page.

Two steps:

  1. Downsize every Nth source frame in
        images/Dynamic_waveforms/Waveforms/        (frame_NNNN.jpg)
        images/Dynamic_waveforms/Topo_plots/       (topo_frame_NNNN.jpg)
     into the intermediate folders
        images/Dynamic_waveforms/web_waveforms/    (frame_NNN.jpg)
        images/Dynamic_waveforms/web_topo/         (frame_NNN.jpg)

  2. Combine each pair (waveform left + topo right, same height) into
        images/Dynamic_waveforms/web_combined/     (frame_NNN.jpg)
     This is the folder the HTML player on the MInDReading page reads.

Run from the project root:
    python3 scripts/downsize_frames.py
Requires Pillow:
    pip install Pillow
"""
from PIL import Image
import os, glob

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE         = os.path.join(PROJECT_ROOT, "images", "Dynamic_waveforms")

# --- Step 1: downsize ----
STRIDE       = 3        # take every 3rd source frame
MAX_WIDTH    = 900      # pixels — cap for web
QUALITY      = 78       # JPEG quality (0–95) for individual panels

DOWNSIZE_JOBS = [
    # (source folder, source pattern, output folder)
    ("Waveforms",  "frame_*.jpg",      "web_waveforms"),
    ("Topo_plots", "topo_frame_*.jpg", "web_topo"),
]

# --- Step 2: combine ----
COMBINED_DIR     = "web_combined"
COMBINED_HEIGHT  = 600      # pixels — both panels scale to this height
COMBINED_GAP     = 16       # pixels — gap between the two panels
COMBINED_PAD     = 8        # pixels — outer padding around the canvas
COMBINED_BG      = (255, 255, 255)
COMBINED_QUALITY = 80


def downsize():
    for src_name, pattern, out_name in DOWNSIZE_JOBS:
        src_dir = os.path.join(BASE, src_name)
        out_dir = os.path.join(BASE, out_name)
        os.makedirs(out_dir, exist_ok=True)

        files = sorted(glob.glob(os.path.join(src_dir, pattern)))
        if not files:
            print(f"[skip] {src_dir}: no matches for {pattern}")
            continue

        selected = files[::STRIDE]
        print(f"\n{src_name}: {len(files)} source → {len(selected)} output "
              f"(stride={STRIDE})")
        total_in = total_out = 0
        for i, src in enumerate(selected, start=1):
            im = Image.open(src).convert("RGB")
            if im.width > MAX_WIDTH:
                ratio = MAX_WIDTH / im.width
                im = im.resize((MAX_WIDTH, int(im.height * ratio)),
                               Image.LANCZOS)
            out_path = os.path.join(out_dir, f"frame_{i:03d}.jpg")
            im.save(out_path, "JPEG",
                    quality=QUALITY, optimize=True, progressive=True)
            total_in  += os.path.getsize(src)
            total_out += os.path.getsize(out_path)
        print(f"  {total_in/1e6:6.1f} MB in  →  {total_out/1e6:6.1f} MB out")


def combine():
    wf_dir  = os.path.join(BASE, "web_waveforms")
    tp_dir  = os.path.join(BASE, "web_topo")
    out_dir = os.path.join(BASE, COMBINED_DIR)
    os.makedirs(out_dir, exist_ok=True)

    wf_files = sorted(glob.glob(os.path.join(wf_dir, "frame_*.jpg")))
    tp_files = sorted(glob.glob(os.path.join(tp_dir, "frame_*.jpg")))
    if not wf_files or not tp_files:
        print(f"\n[skip combine] need both web_waveforms/ and web_topo/ populated")
        return
    if len(wf_files) != len(tp_files):
        print(f"\n[error] mismatch: {len(wf_files)} waveform vs "
              f"{len(tp_files)} topo frames")
        return

    print(f"\nCombining {len(wf_files)} pairs → {COMBINED_DIR}/")

    def scale_to_h(im, h):
        return im.resize((max(1, round(im.width * h / im.height)), h),
                         Image.LANCZOS)

    total_out = 0
    for i, (wf, tp) in enumerate(zip(wf_files, tp_files), start=1):
        w_im = scale_to_h(Image.open(wf).convert("RGB"), COMBINED_HEIGHT)
        t_im = scale_to_h(Image.open(tp).convert("RGB"), COMBINED_HEIGHT)
        canvas_w = w_im.width + COMBINED_GAP + t_im.width + 2 * COMBINED_PAD
        canvas_h = COMBINED_HEIGHT + 2 * COMBINED_PAD
        canvas = Image.new("RGB", (canvas_w, canvas_h), COMBINED_BG)
        canvas.paste(w_im, (COMBINED_PAD, COMBINED_PAD))
        canvas.paste(t_im, (COMBINED_PAD + w_im.width + COMBINED_GAP,
                            COMBINED_PAD))
        out_path = os.path.join(out_dir, f"frame_{i:03d}.jpg")
        canvas.save(out_path, "JPEG",
                    quality=COMBINED_QUALITY,
                    optimize=True, progressive=True)
        total_out += os.path.getsize(out_path)
    print(f"  total output: {total_out/1e6:.1f} MB")


if __name__ == "__main__":
    downsize()
    combine()
