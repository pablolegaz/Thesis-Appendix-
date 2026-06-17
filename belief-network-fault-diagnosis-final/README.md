# Belief Networks for Fault Diagnosis under Incomplete Information

This repository is the technical companion to the thesis **Belief Networks for Fault Diagnosis under Incomplete Information**.

The thesis investigates when belief networks, represented using Dempster--Shafer belief functions, are useful for industrial fault diagnosis when the diagnostic structure is known but some probabilistic information is incomplete, unavailable, or weakly justified.

The repository is organised as a reproducibility package. It contains the MATLAB scripts used to run the Belief Function Machine (BFM) experiments, the UIL source models, generated BFM model files, raw CSV outputs, run diaries, and Jupyter notebooks that explain the workflow and summarise the results.

## Main file for reviewers

Start with:

```text
notebooks/00_code_overview_for_tutor.ipynb
```

This notebook explains, at a high level, what the code does and how the results are generated. It is intended to avoid requiring the reader to inspect every MATLAB line manually. It shows that the reported belief, plausibility, width, and conflict values are produced by BFM inference and CSV export scripts, not typed manually into the thesis.

## Repository structure

```text
belief-network-fault-diagnosis/
├── README.md
├── CITATION.cff
├── LICENSE_NOTICE.md
├── data/                         # Scenario evidence and helper Python data file
├── bfm_models/
│   ├── uil/                       # Human-readable UIL source models
│   ├── generated_bm/              # Generated MATLAB/BFM .mat files
│   └── bfm_external/              # Placeholder/instructions for external BFM package
├── matlab/
│   └── export_scripts/            # MATLAB scripts used to run/export results
├── notebooks/
│   ├── 00_code_overview_for_tutor.ipynb
│   ├── 01_results_analysis.ipynb
│   └── 02_generate_thesis_tables.ipynb
├── results/
│   ├── raw/                       # Raw BFM CSV outputs
│   ├── diaries/                   # MATLAB diary logs from runs
│   └── processed/                 # Processed thesis summary tables
├── thesis_tables/                 # LaTeX-ready tables
├── docs/                          # Documentation and code map
├── paper/                         # Thesis paper files
└── archive/                       # Review/context notes and original uploads
```

## Experiment levels

The main thesis reports four levels:

- **L0 complete model**: complete BFM model used to validate the BFM implementation against the complete Bayesian-network reference.
- **L1 local prior ignorance**: only the locally relevant fault priors are replaced by ignorance.
- **L2 fault-family prior ignorance**: broader prior families, such as switch/cable or power-subsystem priors, are replaced by ignorance.
- **L4 combined incompleteness**: missing observations, missing prior knowledge, and weakened visual observation rules are combined.

Additional scripts for **L3** and **L3b** are included as intermediate/robustness work. They are useful for understanding how observation uncertainty was implemented, even though they are not the central thesis result tables.

## Reproducing the MATLAB results

The BFM software itself is not redistributed here unless its licence allows it. To reproduce the results:

1. Install MATLAB.
2. Install the Belief Function Machine externally.
3. Add the BFM folder to the MATLAB path.
4. Place the repository root as the MATLAB working directory.
5. Run scripts from `matlab/export_scripts/`.
6. The scripts export CSV files to `runs/` in MATLAB. The final CSVs used in the thesis are stored in `results/raw/`.

## Python/Jupyter use

The notebooks do **not** require MATLAB to run. They inspect the source files, explain the MATLAB workflow, load the exported CSVs, and regenerate the summary tables.

Install dependencies with:

```bash
pip install -r requirements.txt
```

Then open:

```bash
jupyter notebook notebooks/00_code_overview_for_tutor.ipynb
```

## Important note on BFM

The BFM package is external third-party software. This repository includes thesis-specific UIL files, MATLAB scripts, generated model files, and outputs. It does not claim ownership of the original BFM package.
