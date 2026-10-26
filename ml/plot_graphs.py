from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

df = pd.read_csv(Path(__file__).resolve().parent / "results.csv")
df.columns = df.columns.str.strip()
epochs = df["epoch"]

fig, axs = plt.subplots(3, 2, figsize=(14, 12))
axs[0, 0].plot(epochs, df["metrics/precision(B)"])
axs[0, 0].set_title("Precision vs Epoch")
axs[0, 0].set_xlabel("Epoch")
axs[0, 0].set_ylabel("Precision")
axs[0, 0].grid(True)

axs[0, 1].plot(epochs, df["metrics/recall(B)"])
axs[0, 1].set_title("Recall vs Epoch")
axs[0, 1].set_xlabel("Epoch")
axs[0, 1].set_ylabel("Recall")
axs[0, 1].grid(True)

axs[1, 0].plot(epochs, df["metrics/mAP50(B)"])
axs[1, 0].set_title("mAP50 vs Epoch")
axs[1, 0].set_xlabel("Epoch")
axs[1, 0].set_ylabel("mAP50")
axs[1, 0].grid(True)

axs[1, 1].plot(epochs, df["train/box_loss"], label="Box Loss")
axs[1, 1].plot(epochs, df["train/cls_loss"], label="Class Loss")
axs[1, 1].plot(epochs, df["train/dfl_loss"], label="DFL Loss")
axs[1, 1].set_title("Training Loss vs Epoch")
axs[1, 1].set_xlabel("Epoch")
axs[1, 1].set_ylabel("Loss")
axs[1, 1].legend()
axs[1, 1].grid(True)

axs[2, 0].plot(epochs, df["val/box_loss"], label="Val Box Loss")
axs[2, 0].plot(epochs, df["val/cls_loss"], label="Val Class Loss")
axs[2, 0].plot(epochs, df["val/dfl_loss"], label="Val DFL Loss")
axs[2, 0].set_title("Validation Loss vs Epoch")
axs[2, 0].set_xlabel("Epoch")
axs[2, 0].set_ylabel("Loss")
axs[2, 0].legend()
axs[2, 0].grid(True)

fig.delaxes(axs[2, 1])
plt.tight_layout()
out = Path(__file__).resolve().parent / "training_log.png"
fig.savefig(out)
print(out)
