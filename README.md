# TinyOS Data Aggregation Service (TAG)

This project implements a **Tiny Aggregation (TAG)** service for Wireless Sensor Networks (WSN) using **TinyOS**. It features a dynamic routing tree construction, epoch-based time synchronization, and in-network data aggregation (Min, Sum, Average) to reduce energy consumption and bandwidth usage.

## 📂 Project Structure

- **`src/`**: Contains the TinyOS source code (`.nc`, `.h`, `Makefile`).
- **`simulation/`**: Python scripts (`TOSSIM`) and topology files for simulating the network.
- **`docs/`**: Project documentation and reports.
- **`results/`**: Sample output logs from simulations.

## 🚀 Features

### 1. Simple Routing Tree
- **Dynamic Construction:** The network autonomously builds a routing tree rooted at Node 0.
- **Parent Selection:** Nodes select the first available parent that provides a path to the root (First-Hearing).

### 2. In-Network Aggregation
Instead of sending raw data to the root, nodes aggregate data from their children and themselves before forwarding.
- **Supported Operators:**
  - **MIN:** Propagates the minimum sensor value sensed in the subtree.
  - **SUM:** Calculates the total sum of values in the subtree.
  - **AVG:** Computes the average (maintains partial sum and count).

### 3. Epoch-Based Synchronization
- Implements a reverse-flow timing mechanism.
- Leaf nodes transmit first, followed by parents, ensuring data is available for aggregation at each hop up to the root.

### 4. Grouped Aggregation (Phase 2)
- Advanced logic to handle multiple groups of sensors simultaneously.
- Optimizes packet usage by packing data for multiple groups (e.g., Groups 1 & 2) into single messages.

## 🛠️ Prerequisites

- **TinyOS** (2.1.2 or compatible)
- **Python 2.7** (Required for TOSSIM simulations)
- **GCC** (avr-gcc for micaz/iris targets)
- **Make**

## 🏗️ How to Build

1. Navigate to the source directory:
   ```bash
   cd src
   ```

2. Compile for simulation (Micaz platform):
   ```bash
   make micaz sim
   ```

   *This will generate the necessary Python bindings (`TOSSIM.py` and `_TOSSIM.so/dll`) in the `build/micaz/` directory (or current directory depending on your environment).*

## 🔬 How to Run Simulation

1. After building, ensure the generated `TOSSIM.py` and `_TOSSIM` module are accessible to your Python script. You may need to copy them to the `simulation/` folder or set your `PYTHONPATH`.

   *Example setup:*
   ```bash
   # Assuming you are in the root of the repo
   cp src/build/micaz/TOSSIM.py simulation/
   cp src/build/micaz/_TOSSIM.so simulation/  # or .dll on Windows
   ```

2. Run the simulation script:
   ```bash
   cd simulation
   python mySimulation.py topology.txt 10
   ```
   *Usage:* `python mySimulation.py <topology-file> <number-of-nodes>`

## 📊 Output

The simulation generates logs in the console (or redirected to files) showing:
- **Routing:** Tree depth and parent selection updates.
- **Epochs:** Timing of aggregation rounds.
- **Results:** Final aggregated values received at the root (Node 0).

Example output for MIN aggregation:
```text
DEBUG (0): AGG RESULT epoch=1 MIN=15 
```

## 📜 License

This project is open-source.
