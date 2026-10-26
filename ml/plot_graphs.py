import pandas as pd
import matplotlib.pyplot as plt

# Read CSV
df = pd.read_csv("results.csv")

# Remove spaces
df.columns = df.columns.str.strip()

epochs = df['epoch']

# Create 5 subplots
fig, axs = plt.subplots(3, 2, figsize=(14, 12))

# ---------------- GRAPH 1 ----------------
axs[0,0].plot(epochs, df['metrics/precision(B)'])
axs[0,0].set_title("Precision vs Epoch")
axs[0,0].set_xlabel("Epoch")
axs[0,0].set_ylabel("Precision")
axs[0,0].grid(True)

# ---------------- GRAPH 2 ----------------
axs[0,1].plot(epochs, df['metrics/recall(B)'])
axs[0,1].set_title("Recall vs Epoch")
axs[0,1].set_xlabel("Epoch")
axs[0,1].set_ylabel("Recall")
axs[0,1].grid(True)

# ---------------- GRAPH 3 ----------------
axs[1,0].plot(epochs, df['metrics/mAP50(B)'])
axs[1,0].set_title("Accuracy (mAP50) vs Epoch")
axs[1,0].set_xlabel("Epoch")
axs[1,0].set_ylabel("mAP50")
axs[1,0].grid(True)

# ---------------- GRAPH 4 ----------------
axs[1,1].plot(epochs, df['train/box_loss'], label='Box Loss')
axs[1,1].plot(epochs, df['train/cls_loss'], label='Class Loss')
axs[1,1].plot(epochs, df['train/dfl_loss'], label='DFL Loss')

axs[1,1].set_title("Training Loss vs Epoch")
axs[1,1].set_xlabel("Epoch")
axs[1,1].set_ylabel("Loss")
axs[1,1].legend()
axs[1,1].grid(True)

# ---------------- GRAPH 5 ----------------
axs[2,0].plot(epochs, df['val/box_loss'], label='Val Box Loss')
axs[2,0].plot(epochs, df['val/cls_loss'], label='Val Class Loss')
axs[2,0].plot(epochs, df['val/dfl_loss'], label='Val DFL Loss')

axs[2,0].set_title("Validation Loss vs Epoch")
axs[2,0].set_xlabel("Epoch")
axs[2,0].set_ylabel("Loss")
axs[2,0].legend()
axs[2,0].grid(True)

# Remove empty subplot
fig.delaxes(axs[2,1])

# Adjust spacing
plt.tight_layout()

# Show all graphs together
plt.show()