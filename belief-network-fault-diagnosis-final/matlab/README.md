# MATLAB implementation

The MATLAB scripts in `export_scripts/` run the Belief Function Machine experiments and export the results to CSV.

The scripts share the same broad workflow:

1. Load or generate a UIL model.
2. Convert the UIL model to a BFM `.mat` model with `uil2bm` when needed.
3. Load the BFM model.
4. Convert conditional beliefs using `condiembed`.
5. Keep the embedded belief functions with `keepbel`.
6. Create scenario evidence as belief functions.
7. Combine model beliefs with evidence.
8. Solve each candidate fault variable.
9. Extract belief, plausibility, width, conflict, and rank.
10. Export a structured CSV result table.

The values in the thesis result tables are generated from these CSV outputs.
