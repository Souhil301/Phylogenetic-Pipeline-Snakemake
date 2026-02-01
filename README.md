# Phylogenetic Analysis Pipeline with Snakemake

This repository contains a reproducible phylogenetic analysis pipeline
implemented using **Snakemake**.  
The pipeline processes biological sequences in FASTA format and produces
a phylogenetic tree using standard bioinformatics tools.

The project focuses on **workflow automation**, **reproducibility**,
and **parallel performance evaluation** (1 core vs 4 cores),
with an HPC-oriented mindset.

---

## Pipeline Overview

The pipeline includes the following steps:

1. Input FASTA sequence handling
2. Quality control of sequences
3. Multiple sequence alignment with MAFFT
4. Phylogenetic tree construction with IQ-TREE
5. Workflow DAG generation
6. Execution time and statistics collection

---

## Tools and Technologies

- Snakemake
- Python (Biopython)
- MAFFT
- IQ-TREE
- Linux
- Conda

---

## Repository Structure
```
├── Snakefile
├── data/ # Input data (small example FASTA)
├── results/ # Generated outputs (not tracked by git)
│ ├── qc/
│ ├── alignment/
│ └── trees/
├── logs/ # Execution logs (not tracked)
├── dag/
│ ├── workflow.png
│ └── workflow.pdf
├── split_fasta.py # Helper script for FASTA processing
├── execution_.log # Runtime logs (not tracked)
├── stats_.json # Execution statistics (not tracked)
└── README.md
```


---

## Results

### Dataset
- **Number of sequences**: 59 RNA sequences
- **Total length**: ~193,600 bp
- The sequences are conserved enough for global alignment
  while containing sufficient variation for phylogenetic inference.

### Quality Control
- A quality control report is generated before alignment.
- The report includes:
  - Number of sequences
  - Total sequence length
  - Average sequence length
  - Preview of sequence headers

This step ensures data consistency before downstream analysis.

### Multiple Sequence Alignment
- Alignment is performed using **MAFFT** with automatic algorithm selection.
- Parallel execution is enabled through multi-threading.
- All sequences are aligned together to allow global phylogenetic inference.

### Phylogenetic Tree Construction
- Trees are reconstructed using **IQ-TREE** with:
  - Automatic model selection (`-m MFP`)
  - Ultrafast bootstrap with 1000 replicates (`-bb 1000`)
- The output includes:
  - Final tree file (Newick format)
  - Model and likelihood statistics
  - Bootstrap support values

Bootstrap values greater than 70 indicate strong statistical support
for many branches in the final tree.

### Parallel Performance Analysis
The pipeline was executed with different CPU configurations:

- **1 core (sequential)**
- **4 cores (parallel)**

Observations:
- Computationally intensive steps (alignment and tree construction)
  benefit significantly from multi-threading.
- Lightweight steps (quality control, summary generation)
  remain mostly I/O-bound.
- The global speedup is limited by the sequential fraction of the workflow,
  in accordance with **Amdahl’s law**.

This confirms that the pipeline is ready for larger datasets
and HPC-scale execution.

---

## How to Run

### 1. Create the environment

```bash
git clone Phylogenetic-Pipeline-Snakemake
cd Phylogenetic-Pipeline-Snakemake
conda create -n phylo python=3.10
conda activate phylo
conda install -c bioconda snakemake mafft iqtree biopython
snakemake --cores 4
```

## Outputs

### The pipeline produces:

- Quality control report: `results/qc/`

- Aligned sequences: `results/alignment/`

- Phylogenetic trees and model files: `results/trees/`

- Workflow DAG visualization: `dag/workflow.png`

## Motivation

### This project demonstrates:

- Reproducible bioinformatics workflows

- Workflow automation using Snakemake

- Parallel execution and performance evaluation

- Foundations for deployment on HPC clusters (e.g. SLURM)

## Author :

**S.Mokkeddem**
