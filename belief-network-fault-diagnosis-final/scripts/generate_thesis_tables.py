"""Generate compact thesis-support tables from raw BFM CSV outputs."""
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "results" / "raw"
OUT = ROOT / "results" / "processed"
OUT.mkdir(parents=True, exist_ok=True)

FILES = [
    "bfm_L0_results.csv",
    "bfm_L1_local_prior_ignorance_results_ranked.csv",
    "bfm_L2_fault_family_prior_ignorance_results.csv",
    "bfm_L4_combined_incompleteness_results.csv",
]

frames = []
for filename in FILES:
    path = RAW / filename
    if path.exists():
        df = pd.read_csv(path)
        if "width" not in df.columns:
            df["width"] = df["plausibility"] - df["belief"]
        frames.append(df)

all_results = pd.concat(frames, ignore_index=True)
all_results.to_csv(OUT / "all_bfm_results_combined.csv", index=False)

conflict = (
    all_results.groupby(["scenario_id", "level"], as_index=False)["empty_set_mass"]
    .first()
    .sort_values(["scenario_id", "level"])
)
conflict.to_csv(OUT / "conflict_table_long.csv", index=False)

scenario8 = all_results[(all_results["scenario_id"] == 8) & (all_results["bfm_var"].isin(["SW3", "C3"]))]
scenario8.to_csv(OUT / "scenario8_progression.csv", index=False)

print("Generated processed result files in", OUT)
