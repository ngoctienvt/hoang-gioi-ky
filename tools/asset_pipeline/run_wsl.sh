#!/bin/bash
# Buoc 3 (WSL): Omni -> giam con 40k mat -> Paint. Dung lai script cua Tong Mon trong reports/exp3d. Chay lai duoc.
X=/mnt/c/Users/Admin/workspace/animation2d/reports/exp3d; H=/mnt/c/Users/Admin/workspace/animation2d/hoang-gioi-ky/tools/asset_pipeline; D=/mnt/d/hgk_models/m
cd ~/omni && . venv/bin/activate && python $X/omni_run.py $H/omni_jobs.json; deactivate
echo OMNI_ALL_DONE $(date)
export CUDA_HOME=/usr/local/cuda-12.8 PATH=/usr/local/cuda-12.8/bin:$PATH
cd ~/paint && . venv/bin/activate && python $X/quad/all/decim.py $D && for i in 1 2 3; do python $X/paint/paint_batch.py $D /mnt/d/hgk_models/rgba; echo PAINT_PASS $i; done
echo ALL_DONE $(date)
