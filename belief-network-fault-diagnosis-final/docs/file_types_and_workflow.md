# File types and workflow

This repository contains several file types. They play different roles in the workflow.

| File type | Example | Meaning | Role |
|---|---|---|---|
| `.m` | `export_bfm_L2_fault_family_prior_ignorance.m` | MATLAB script | Executable code that builds/runs a BFM experiment and exports CSV results. |
| UIL `.txt` | `ten_cube_L0_complete_s8.txt` | Human-readable BFM input model | Defines variables, relations, valuations, priors, ignorance, and deterministic constraints. |
| diary `.txt` | `export_bfm_L4_combined_incompleteness_diary.txt` | MATLAB run log | Shows the run trace: conversion, embedding, evidence, solving, and export. |
| `.mat` | `bm_ten_cube_L4_temp_scenario.mat` | Generated MATLAB/BFM model | Compiled/generated model object. Useful for MATLAB reruns, less useful for explanation. |
| `.csv` | `bfm_L4_combined_incompleteness_results.csv` | Exported result table | Contains belief, plausibility, width, conflict, and rankings used in the thesis. |
| `.ipynb` | `00_code_overview_for_tutor.ipynb` | Jupyter notebook | Explains the workflow and summarises results without reading every MATLAB line. |

## Workflow

```text
MATLAB export script (.m)
    reads/modifies
UIL source model (.txt)
    converts through BFM uil2bm
Generated BFM model (.mat)
    is solved with evidence
CSV results (.csv)
    are analysed in notebooks and summarised in thesis tables
```
