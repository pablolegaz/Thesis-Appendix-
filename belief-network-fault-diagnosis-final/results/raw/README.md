# Raw CSV results

These CSV files are the structured outputs exported by the MATLAB/BFM scripts. They contain the values used in the thesis tables.

Key columns:

- `scenario_id`: diagnostic scenario identifier.
- `level`: information-completeness level, e.g. L0, L1, L2, L4.
- `bn_fault_var`, `bn_fault_state`: original BN-style fault naming.
- `bfm_var`, `bfm_fault_state`: short BFM variable/state naming.
- `belief`: committed evidential support for the queried fault state.
- `plausibility`: support compatible with the queried fault state.
- `width`: `plausibility - belief`.
- `empty_set_mass`: conflict mass.
- `rank_by_belief`, `rank_by_plausibility`, or `bfm_rank`: diagnostic ranking columns.
