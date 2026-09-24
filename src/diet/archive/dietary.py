"""Python implementation of the dietary cleaning workflow.

This script mirrors the intent of `src/diet/dietary.R`: load the raw dietary
export, clean participant identifiers and summary rows, derive quartile-like
features for numeric columns, and write `data/processed/dietary_cleaned.xlsx`.

If this file is kept in active use, changes to cleaning rules should usually be
applied here and in the R version so both paths stay consistent.
"""

import re
import sys
from pathlib import Path

import pandas as pd

project_root = Path(__file__).resolve().parents[2]
_src_dir = project_root / "src"
if str(_src_dir) not in sys.path:
    sys.path.insert(0, str(_src_dir))
from participant_id import normalize_participant_id_val

data_candidates = [
    project_root / "data" / "raw" / "SYN_dietary data.xlsx",
    project_root / "data" / "raw" / "SYN_dietary data(ALL).csv",
    project_root / "data" / "raw" / "SYN_dietary data.csv",
]

PID_COL = "Participant ID (ESHA ID)"
REQUIRED_DATA_COLUMNS = [
    PID_COL,
    "Day",
    "Timepoint ",
    "TotFib (g)",
    "Sugar (g)",
    "SugAdd (g)",
    "MonSac (g)",
    "Gluc (g)",
    "Fruct (g)",
    "Disacc (g)",
    "Lact (g)",
    "Sucr (g)",
    "Trp (g)",
    "Vit A-IU (IU)",
    "Vit B1 (mg)",
    "Vit B2 (mg)",
    "Vit B3 (mg)",
    "Vit B6 (mg)",
    "Vit B12 (mcg)",
    "Vit C (mg)",
    "Vit D-mcg (mcg)",
    "Vit E-IU (IU)",
    "Folate (mcg)",
    "Vit K (mcg)",
    "TotSolFib (g)",
    "TotInsolFib (g)",
    "SolFib(16) (g)",
    "InsolFib(16) (g)",
    "Sol Non-Digest Carb (g)",
    "Insol Non-Digest Carb (g)",
    "Fat (g)",
    "SatFat (g)",
    "MonoFat (g)",
    "PolyFat (g)",
    "TransFat (g)",
    "Chol (mg)",
    "Omega3 (g)",
    "Omega6 (g)",
    "Phe (g)",
    "Tyr (g)",
    "Alc (g)",
    "Caff (mg)",
    "ArtSw (mg)",
    "Aspar (mg)",
    "Sacch (mg)",
    "SugAl (g)",
    "Eryth (g)",
    "Glyc (g)",
    "Inos (g)",
    "Lacti (g)",
    "Malti (g)",
    "Mann (g)",
    "Sorb (g)",
    "Xylit (g)",
    "MPGrain (oz-eq)",
    "MPVeg (c-eq)",
    "MPFruit (c-eq)",
    "MPDairy (c-eq)",
    "MPProt (oz-eq)",
]
# Valid participant anchor cells only (blocks note / junk text in the ID column)
_pid_cell = re.compile(
    r"^\s*SYN[_-]\d{1,2}(?:_T\d+)?\s*$",
    re.IGNORECASE,
)


def _pid_cell_valid(val) -> bool:
    """Return True when a cell contains a valid SYN participant anchor."""
    if pd.isna(val):
        return False
    return bool(_pid_cell.match(str(val)))


def validate_required_columns(df: pd.DataFrame) -> None:
    """Fail fast when the cleaned dataset is missing downstream-required fields."""
    missing = [col for col in REQUIRED_DATA_COLUMNS if col not in df.columns]
    if missing:
        raise ValueError(
            "Cleaned dietary output is missing required downstream columns: "
            + ", ".join(missing)
        )


def propagate_participant_ids(series: pd.Series) -> pd.Series:
    """Carry valid SYN participant anchors downward through blank rows.

    Non-matching non-empty cells, such as notes embedded in the source export,
    intentionally break the carry-forward chain so rows are not attached to the
    wrong participant.
    """
    out: list = []
    current = None
    for val in series:
        if pd.isna(val) or (isinstance(val, str) and not str(val).strip()):
            out.append(current)
            continue
        s = str(val).strip()
        if _pid_cell_valid(val):
            current = s
            out.append(s)
        else:
            current = None
            out.append(None)
    return pd.Series(out, index=series.index, dtype=object)


for data_path in data_candidates:
    if data_path.exists():
        break
else:
    raise FileNotFoundError(
        "Missing dietary raw input. Expected one of: "
        + ", ".join(str(path) for path in data_candidates)
    )

if data_path.suffix.lower() in {".xlsx", ".xls"}:
    df = pd.read_excel(data_path, sheet_name="ALL")
else:
    df = pd.read_csv(data_path, encoding="utf-8-sig")

# Remove rows with missing caloric intake
df = df[df["Cals (kcal)"].notna()]

# Remove summary rows (averages and % recommendation rows)
df = df[
    ~(
        (df["Day"] == "Average ")
        | (df["Day"].str.contains("% Recommendation", na=False))
    )
]

# Propagate only valid SYN-style anchors (excludes note rows from corrupting IDs)
df[PID_COL] = propagate_participant_ids(df[PID_COL])
df["Timepoint "] = df["Timepoint "].ffill()

# Drop visit suffix from participant IDs (e.g. SYN_02_T0 -> SYN_02); visit remains in Timepoint
df[PID_COL] = df[PID_COL].str.replace(r"_T\d+$", "", regex=True)

df[PID_COL] = df[PID_COL].map(normalize_participant_id_val)

# Keep only resolved SYN_NN codes (drops any remaining stray text)
df = df[
    df[PID_COL].astype(str).str.fullmatch(r"SYN_[0-9]{2}", case=False, na=False)
].copy()

# Select numerical columns starting from column index 3 onward
numerical_cols = df.iloc[:, 3:].select_dtypes(include=["number"]).columns

for col in numerical_cols:
    # Skip columns with no variation
    if df[col].nunique() <= 1:
        continue

    # Attempt quartile binning (q=4), fall back to median split (q=2) if needed
    for q in [4, 2]:
        try:
            df[f"{col}_quartile"] = pd.qcut(
                df[col], q=q, labels=False, duplicates="drop"
            )
            break
        except ValueError:
            continue


output_path = project_root / "data" / "processed" / "dietary_cleaned.xlsx"

quartile_cols = [col for col in df.columns if col.endswith("_quartile")]
main_cols = [col for col in df.columns if not col.endswith("_quartile")]

validate_required_columns(df)

with pd.ExcelWriter(output_path, engine="openpyxl") as writer:
    df[main_cols].to_excel(writer, sheet_name="Data", index=False)
    df[main_cols[:2] + quartile_cols].to_excel(
        writer, sheet_name="Quartiles", index=False
    )
