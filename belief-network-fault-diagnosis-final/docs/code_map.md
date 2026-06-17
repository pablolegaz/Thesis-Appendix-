# Code map

## Main MATLAB export scripts

| Script | Main purpose |
|---|---|
| `export_bfm_L0_results.m` | Loads the complete L0 model and exports validation results for scenarios 7, 8, 11, and 14. |
| `export_bfm_L1_local_prior_ignorance.m` | Creates scenario-specific L1 models by replacing locally relevant priors with vacuous ignorance. |
| `export_bfm_L2_fault_family_prior_ignorance.m` | Creates scenario-specific L2 models by replacing broader prior families with ignorance. |
| `export_bfm_L3_observation_uncertainty.m` | Discounts scenario evidence itself, representing uncertain observations. Included as intermediate work. |
| `export_bfm_L3b_observation_rule_uncertainty.m` | Weakens visual observation rules in the model while keeping measurements reliable. Included as intermediate work. |
| `export_bfm_L4_combined_incompleteness.m` | Creates derived L4 scenarios combining missing observations, missing priors, and weakened visual observation rules. |

## Common code pattern

Across the scripts, the important pattern is:

1. Define or modify a UIL model.
2. Convert UIL to BFM with `uil2bm` if needed.
3. Load the BFM model.
4. Convert conditional beliefs with `condiembed`.
5. Keep embedded beliefs with `keepbel`.
6. Create evidence for a scenario.
7. Solve each fault variable with `solve`.
8. Parse BFM output to extract belief and plausibility.
9. Export all results to a CSV file.

The thesis tables are generated from the exported CSV files, not from manually typed values.
