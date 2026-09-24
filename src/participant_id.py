"""Shared participant ID normalization for Python cleaning scripts."""

from __future__ import annotations

import math
import re


def normalize_participant_id_val(val):
    """
    Standardize SYN-style IDs to SYN_NN (two-digit suffix, underscore).

    Accepts SYN-7, SYN_7, SYN7, SYN_07, SYN_02_T0 (after stripping _T in caller).
    Non-matching values (e.g. CONTROL) are returned uppercased and trimmed.
    """
    if val is None:
        return val
    try:
        import pandas as pd

        if pd.isna(val):
            return val
    except ImportError:
        if isinstance(val, float) and math.isnan(val):
            return val
    except (TypeError, ValueError):
        pass
    s = re.sub(r"\s+", "", str(val).upper().strip())
    if not s:
        return val
    m = re.fullmatch(r"([A-Z]+)[_-]?([0-9]+)", s)
    if not m:
        return s
    prefix, num = m.group(1), m.group(2)
    if len(num) == 1:
        num = f"0{num}"
    return f"{prefix}_{num}"
