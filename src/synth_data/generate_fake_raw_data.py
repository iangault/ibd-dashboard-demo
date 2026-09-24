from __future__ import annotations

from pathlib import Path
import math
import re

import numpy as np
import pandas as pd


ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = ROOT / "data" / "raw"
RNG = np.random.default_rng(20260607)


PARTICIPANTS = [
    {"pid": "SYN_1", "group": "Active IBD", "fiber": "Low", "diagnosis": "Crohn's Disease", "activity": "Moderate active"},
    {"pid": "SYN_2", "group": "Active IBD", "fiber": "High", "diagnosis": "Crohn's Disease", "activity": "Mild active"},
    {"pid": "SYN_3", "group": "Active IBD", "fiber": "Mid", "diagnosis": "Ulcerative Colitis", "activity": "Moderate active"},
    {"pid": "SYN_4", "group": "Active IBD", "fiber": "None", "diagnosis": "Ulcerative Colitis", "activity": "Mild active"},
    {"pid": "SYN_5", "group": "Quiescent", "fiber": "None", "diagnosis": "Crohn's Disease", "activity": "Quiescent"},
    {"pid": "SYN_6", "group": "Quiescent", "fiber": "Low", "diagnosis": "Crohn's Disease", "activity": "Quiescent"},
    {"pid": "SYN_7", "group": "Quiescent", "fiber": "Mid", "diagnosis": "Ulcerative Colitis", "activity": "Quiescent"},
    {"pid": "SYN_8", "group": "Quiescent", "fiber": "High", "diagnosis": "Ulcerative Colitis", "activity": "Quiescent"},
    {"pid": "SYN_9", "group": "Non-IBD", "fiber": "None", "diagnosis": "Non-IBD control", "activity": "/"},
    {"pid": "SYN_10", "group": "Non-IBD", "fiber": "Low", "diagnosis": "Non-IBD control", "activity": "/"},
    {"pid": "SYN_11", "group": "Non-IBD", "fiber": "Mid", "diagnosis": "Non-IBD control", "activity": "/"},
    {"pid": "SYN_12", "group": "Non-IBD", "fiber": "High", "diagnosis": "Non-IBD control", "activity": "/"},
]

SAMPLES = [
    {"sample_id": "S001", "participant": "SYN_1", "ss_id": "A1"},
    {"sample_id": "S002", "participant": "SYN_1", "ss_id": "A2"},
    {"sample_id": "S003", "participant": "SYN_2", "ss_id": "B1"},
    {"sample_id": "S004", "participant": "SYN_2", "ss_id": "B2"},
    {"sample_id": "S005", "participant": "SYN_3", "ss_id": "C1"},
    {"sample_id": "S006", "participant": "SYN_4", "ss_id": "D1"},
    {"sample_id": "S007", "participant": "SYN_5", "ss_id": "E1"},
    {"sample_id": "S008", "participant": "SYN_5", "ss_id": "E2"},
    {"sample_id": "S009", "participant": "SYN_6", "ss_id": "F1"},
    {"sample_id": "S010", "participant": "SYN_7", "ss_id": "G1"},
    {"sample_id": "S011", "participant": "SYN_8", "ss_id": "H1"},
    {"sample_id": "S012", "participant": "SYN_9", "ss_id": "I1"},
    {"sample_id": "S013", "participant": "SYN_9", "ss_id": "I2"},
    {"sample_id": "S014", "participant": "SYN_10", "ss_id": "J1"},
    {"sample_id": "S015", "participant": "SYN_11", "ss_id": "K1"},
    {"sample_id": "S016", "participant": "SYN_12", "ss_id": "L1"},
]

PARTICIPANT_LOOKUP = {row["pid"]: row for row in PARTICIPANTS}


DEDUPE_SUFFIX_RE = re.compile(r"^(.*?)(\s+)(\.\d+)$")


def _drop_dedupe_suffix_whitespace(column: str) -> str:
    # pandas auto-dedupes repeated headers by appending ".N"; when the base
    # header already ends in whitespace (e.g. "Weight (lbs): "), the result
    # is "Weight (lbs): .1" with a stray space before the suffix. The R
    # pipeline's own name-cleaning expects no whitespace before ".N", so
    # normalize it away here to match.
    match = DEDUPE_SUFFIX_RE.match(column)
    if match:
        return f"{match.group(1)}{match.group(3)}"
    return column


def read_xlsx_headers(path: Path) -> dict[str, list[str]]:
    sheets = pd.read_excel(path, sheet_name=None, nrows=0)
    return {
        name: [_drop_dedupe_suffix_whitespace(col) for col in df.columns]
        for name, df in sheets.items()
    }


def normalized_pid(pid: str) -> str:
    prefix, number = pid.split("_")
    return f"{prefix}_{int(number):02d}"


def random_date(month: int, day: int) -> str:
    return f"{month:02d}/{day:02d}/2025"


def build_meta_frame(columns: list[str]) -> pd.DataFrame:
    rows = []
    for sample in SAMPLES:
        participant = PARTICIPANT_LOOKUP[sample["participant"]]
        row = {col: "" for col in columns}
        row["Sample_ID"] = sample["sample_id"]
        row["Participant ID"] = sample["participant"]
        row["SS_ID"] = sample["ss_id"]
        row["Sample_type"] = "Stool"
        row["Study_group_new"] = participant["group"]
        row["Study_group"] = participant["group"]
        row["Fiber_restriction"] = participant["fiber"]
        row["gDNA_yield(ng/ul)"] = round(float(RNG.uniform(0.4, 2.5)), 2)
        rows.append(row)
    return pd.DataFrame(rows, columns=columns)


def build_alpha_frame(columns: list[str]) -> pd.DataFrame:
    rows = []
    for sample in SAMPLES:
        row = {col: "" for col in columns}
        row["Sample_ID"] = sample["sample_id"]
        row["Participant ID"] = sample["participant"]
        row["SS_ID"] = sample["ss_id"]
        row["Chao1"] = int(RNG.integers(40, 95))
        row["Shannon"] = round(float(RNG.uniform(1.2, 3.4)), 6)
        row["Simpson"] = round(float(RNG.uniform(0.45, 0.95)), 6)
        rows.append(row)
    return pd.DataFrame(rows, columns=columns)


def build_beta_frame(columns: list[str]) -> pd.DataFrame:
    axis_cols = [col for col in columns if col != "Sample_ID"]
    rows = []
    for sample in SAMPLES:
        row = {"Sample_ID": sample["sample_id"]}
        for col in axis_cols:
            row[col] = round(float(RNG.normal(0, 0.12)), 6)
        rows.append(row)
    return pd.DataFrame(rows, columns=columns)


def build_taxa_frame(columns: list[str]) -> pd.DataFrame:
    sample_col = columns[0]
    taxa_cols = columns[1:]
    alpha = np.ones(len(taxa_cols), dtype=float)
    for idx, col in enumerate(taxa_cols):
        if col == "NA":
            alpha[idx] = 0.15
        elif "Other" in col or "Incertae" in col:
            alpha[idx] = 0.5
        else:
            alpha[idx] = 1.0

    rows = []
    for sample in SAMPLES:
        values = RNG.dirichlet(alpha) * 100
        row = {sample_col: sample["sample_id"]}
        for col, value in zip(taxa_cols, values):
            row[col] = round(float(value), 4)
        total = sum(float(row[col]) for col in taxa_cols)
        diff = round(100.0 - total, 4)
        row[taxa_cols[-1]] = round(float(row[taxa_cols[-1]]) + diff, 4)
        rows.append(row)
    return pd.DataFrame(rows, columns=columns)


def build_inflammation_frame(columns: list[str]) -> pd.DataFrame:
    rows = []
    for index, participant in enumerate(PARTICIPANTS, start=1):
        row = {col: "" for col in columns}
        row["Participant_ID"] = normalized_pid(participant["pid"])
        row["IBD/non-IBD"] = "IBD" if participant["group"] != "Non-IBD" else "non-IBD"
        row["Scope Date"] = random_date(1 + index, 5 + index)
        row["Fecal Calprotectin"] = int(RNG.integers(40, 380)) if participant["group"] != "Non-IBD" else int(RNG.integers(10, 80))
        row["Fecal Calprotectin Date"] = random_date(1 + index, 3 + index)
        crp_value = round(float(RNG.uniform(0.6, 12.5)), 1)
        row["CRP"] = f"<{crp_value}" if index % 4 == 0 else crp_value
        row["CRP Date"] = random_date(1 + index, 1 + index)
        rows.append(row)
    return pd.DataFrame(rows, columns=columns)


def build_dietary_frame(columns: list[str]) -> pd.DataFrame:
    rows = []
    for participant in PARTICIPANTS:
        base_calories = int(RNG.integers(1600, 2600))
        for day_index, day_name in enumerate(["Day 1", "Day 2", "Day 3"], start=0):
            row = {col: "" for col in columns}
            row["Participant ID (ESHA ID)"] = f"{participant['pid']}_T0"
            if "Timepoint " in row:
                row["Timepoint "] = "T0"
            if "Day" in row:
                row["Day"] = day_name
            numeric_defaults = {
                "Wgt (g)": RNG.uniform(1450, 2900),
                "Cals (kcal)": base_calories + day_index * 90,
                "Prot (g)": RNG.uniform(55, 115),
                "Carb (g)": RNG.uniform(160, 320),
                "Carb (Avail) (g)": RNG.uniform(145, 290),
                "TotFib (g)": RNG.uniform(14, 38),
                "TotSolFib (g)": RNG.uniform(3, 12),
                "TotInsolFib (g)": RNG.uniform(6, 19),
                "Fib(16) (g)": RNG.uniform(10, 25),
                "SolFib(16) (g)": RNG.uniform(2, 8),
                "InsolFib(16) (g)": RNG.uniform(4, 14),
                "Sol Non-Digest Carb (g)": RNG.uniform(1, 8),
                "Insol Non-Digest Carb (g)": RNG.uniform(2, 12),
                "Sugar (g)": RNG.uniform(30, 95),
                "SugAdd (g)": RNG.uniform(8, 42),
                "MonSac (g)": RNG.uniform(10, 35),
                "Gluc (g)": RNG.uniform(5, 22),
                "Fruct (g)": RNG.uniform(5, 18),
                "Disacc (g)": RNG.uniform(4, 30),
                "Lact (g)": RNG.uniform(0, 14),
                "Sucr (g)": RNG.uniform(0, 16),
                "NetCarb (g)": RNG.uniform(150, 290),
                "Fat (g)": RNG.uniform(45, 110),
                "SatFat (g)": RNG.uniform(12, 34),
                "MonoFat (g)": RNG.uniform(15, 36),
                "PolyFat (g)": RNG.uniform(8, 28),
                "TransFat (g)": RNG.uniform(0, 2),
                "Chol (mg)": RNG.uniform(90, 360),
                "Water (g)": RNG.uniform(200, 900),
                "kJ (kJ)": RNG.uniform(6500, 10500),
                "Vit A-IU (IU)": RNG.uniform(1200, 4200),
                "Retinol (mcg)": RNG.uniform(120, 620),
                "Vit B1 (mg)": RNG.uniform(0.8, 2.4),
                "Vit B2 (mg)": RNG.uniform(0.8, 2.4),
                "Vit B3 (mg)": RNG.uniform(10, 35),
                "Vit B3-NE (mg)": RNG.uniform(14, 40),
                "Vit B6 (mg)": RNG.uniform(0.8, 3.2),
                "Vit B12 (mcg)": RNG.uniform(1.5, 9),
                "Biot (mcg)": RNG.uniform(10, 55),
                "Vit C (mg)": RNG.uniform(35, 210),
                "Vit D-IU (IU)": RNG.uniform(80, 900),
                "Vit D-mcg (mcg)": RNG.uniform(2, 22),
                "Vit E-IU (IU)": RNG.uniform(2, 18),
                "Folate (mcg)": RNG.uniform(180, 650),
                "Vit K (mcg)": RNG.uniform(30, 220),
                "Panto (mg)": RNG.uniform(2, 8),
                "Calc (mg)": RNG.uniform(300, 1300),
                "Copp (mg)": RNG.uniform(0.3, 2.1),
                "Iodine (mcg)": RNG.uniform(20, 180),
                "Iron (mg)": RNG.uniform(6, 22),
                "Magn (mg)": RNG.uniform(130, 430),
                "Phos (mg)": RNG.uniform(650, 1900),
                "Pot (mg)": RNG.uniform(1400, 4200),
                "Sel (mcg)": RNG.uniform(25, 180),
                "Sod (mg)": RNG.uniform(1200, 3200),
                "Zinc (mg)": RNG.uniform(5, 18),
                "4:0 (g)": RNG.uniform(0, 1.4),
                "18:2 (g)": RNG.uniform(4, 22),
                "20:5 (g)": RNG.uniform(0, 1.5),
                "22:6 (g)": RNG.uniform(0, 1.5),
                "Omega3 (g)": RNG.uniform(0.6, 4.5),
                "Omega6 (g)": RNG.uniform(4, 20),
                "His (g)": RNG.uniform(0.8, 2.5),
                "Iso (g)": RNG.uniform(0.8, 2.7),
                "Leu (g)": RNG.uniform(1.2, 4.0),
                "Phe (g)": RNG.uniform(0.8, 2.8),
                "Trp (g)": RNG.uniform(0.25, 1.2),
                "Tyr (g)": RNG.uniform(0.6, 2.2),
                "Val (g)": RNG.uniform(0.8, 3.0),
                "Alc (g)": 0,
                "Caff (mg)": RNG.uniform(0, 220),
                "ArtSw (mg)": RNG.uniform(0, 60),
                "Aspar (mg)": RNG.uniform(0, 40),
                "Sacch (mg)": RNG.uniform(0, 25),
                "SugAl (g)": RNG.uniform(0, 10),
                "Eryth (g)": RNG.uniform(0, 5),
                "Glyc (g)": RNG.uniform(0, 3),
                "Inos (g)": RNG.uniform(0, 2),
                "Lacti (g)": RNG.uniform(0, 2),
                "Malti (g)": RNG.uniform(0, 2),
                "Mann (g)": RNG.uniform(0, 2),
                "Sorb (g)": RNG.uniform(0, 2),
                "Xylit (g)": RNG.uniform(0, 2),
                "Acet (g)": RNG.uniform(0, 1),
                "Lact (g).1": RNG.uniform(0, 12),
                "Chln (mg)": RNG.uniform(120, 420),
                "Tau (g)": RNG.uniform(0, 0.5),
                "Lycopene (mcg)": RNG.uniform(0, 7000),
                "Sulfites-mg (mg)": RNG.uniform(0, 25),
                "GlyIndx": RNG.uniform(0, 80),
                "GlyLoad": RNG.uniform(0, 45),
                "XxFat": RNG.uniform(0, 6),
                "XxFruit": RNG.uniform(0, 5),
                "XxOCarb": RNG.uniform(0, 8),
                "XxVeg": RNG.uniform(0, 6),
                "XxLeanMeat": RNG.uniform(0, 5),
                "MPGrain (oz-eq)": RNG.uniform(1, 7),
                "MPVeg (c-eq)": RNG.uniform(0.5, 4),
                "MPFruit (c-eq)": RNG.uniform(0.5, 4),
                "MPDairy (c-eq)": RNG.uniform(0, 4),
                "MPProt (oz-eq)": RNG.uniform(2, 10),
            }
            for key, value in numeric_defaults.items():
                if key in row:
                    row[key] = round(float(value), 2)
            rows.append(row)
    return pd.DataFrame(rows, columns=columns)


def find_column(columns: list[str], include: list[str], exclude: list[str] | None = None) -> str:
    exclude = exclude or []
    lowered = {col: col.lower() for col in columns}
    for col, low in lowered.items():
        if all(token in low for token in include) and not any(token in low for token in exclude):
            return col
    raise KeyError(f"Could not find column with include={include} exclude={exclude}")


def build_characteristics_frame(columns: list[str]) -> pd.DataFrame:
    rows = []

    def checkbox(value: bool) -> str:
        return "Checked" if value else "Unchecked"

    exercise_levels = [
        "Regular exercise - (At least 150 minutes of moderate to vigorous-intensity aerobic physical activity per week)",
        "Irregular exercise - (Engages in physical activity on a sporadic or inconsistent basis)",
        "Sedentary Lifestyle  - (Little to no regular physical activity, spending a significant amount of inactive throughout the day)",
    ]
    frequency_values = [
        "7\tNONE OF THE TIME",
        "6\tHARDLY ANY OF THE TIME",
        "5\tA LITTLE OF THE TIME",
        "4\tSOME OF THE TIME",
        "3\tA GOOD BIT OF THE TIME",
    ]

    col = lambda *tokens, exclude=None: find_column(columns, [token.lower() for token in tokens], [token.lower() for token in (exclude or [])])

    first_pid_col = columns[0]
    event_col = col("event name")
    age_col = col("age")
    gender_col = col("gender", exclude=["gender identity"])
    ethnicity_col = col("ethnicity")
    country_col = col("country of origin")
    years_col = col("years living in canada")
    weight1_col = col("weight (lbs)")
    height1_col = col("height (cm)")
    exercise_col = col("exercise history")
    comorb_col = col("comorbidities")
    family_ibd_col = col("family history of ibd")
    smoking_col = col("smoklng status")
    alcohol_col = col("alcohol intake")
    drug_col = col("recreational drug use")
    abx_col = col("taken antibiotics")
    prebiotic_col = col("prebiotics")
    probiotic_col = col("probiotics")
    postbiotic_col = col("postbiotics")
    prebiotic_name_col = col("specify pre-biotics")
    probiotic_name_col = col("specify pro-biotics")
    postbiotic_name_col = col("specify post-biotic")
    second_pid_col = col("participant id", ".1")
    wellbeing_col = col("general well-being")
    pain_col = col("abdominal pain", exclude=["past 2 weeks have you been troubled by pain"])
    stools_col = col("liquid or soft stools per day")
    none_manifest_col = col("additional manifestations", "choice=none")
    arthalgia_col = col("choice=arthalgia")
    uveitis_col = col("choice=uveitis")
    erythema_col = col("choice=erythema nodosum")
    ulcer_col = col("choice=aphthous ulcer")
    pyoderma_col = col("choice=pyoderma")
    fissure_col = col("choice=anal fissure")
    fistula_col = col("choice=new fistula")
    abscess_col = col("choice=abscess")
    hbi_col = col("harvey bradshaw")
    advanced_therapy_col = col("changes in advanced therapy")
    travel_col = col("gastroenteritis")
    pregnant_col = col("pregnant or breastfeeding")
    contraception_col = col("currently using contraception")
    condom_col = col("choice=condoms")
    oral_contra_col = col("choice=oral contraceptives")
    implant_col = col("choice=implants")
    iud_col = col("choice=intrauterine")
    inclusion_col = col("meeting the inclusion and exclusion criteria")
    weight2_col = col("weight (lbs)", ".1")
    height2_col = col("height (cm)", ".1")
    gender_identity_col = col("gender identity")
    change_direction_col = col("increase or decrease in weight")
    change_amount_col = col("specify the amount (lbs)")
    oral_intake_col = col("reduced oral intake")
    cycle_col = col("last menstrual cycle")
    cycle_symptom_col = col("worsen around the time of your menstrual cycle")
    texture_col = col("modifying the texture")
    texture_help_col = col("find this strategy helpful")
    active_fruit_col = col("fruits (e.g., apples, oranges)")
    active_fruit_excl_col = col("excluded fruits (separate each with a comma)", exclude=[".1"])
    active_veg_col = col("vegetables", exclude=[".1"])
    active_veg_excl_col = col("excluded vegetables", exclude=[".1"])
    active_grain_col = col("whole grains", exclude=[".1"])
    active_grain_excl_col = col("excluded whole grains", exclude=[".1"])
    active_nuts_col = col("nuts and seeds", exclude=[".1"])
    active_nuts_excl_col = col("excluded nuts and seeds", exclude=[".1"])
    active_lactose_col = col("lactose-containing foods", exclude=[".1"])
    active_lactose_excl_col = col("excluded lactose-containing foods", exclude=[".1"])
    active_gluten_col = col("gluten-containing foods", exclude=[".1"])
    active_gluten_excl_col = col("excluded gluten-containing foods", exclude=[".1"])
    active_spicy_col = col("spicy foods", exclude=[".1"])
    active_spicy_excl_col = col("excluded spicy foods", exclude=[".1"])
    active_fat_col = col("high fat foods", exclude=[".1"])
    active_fat_excl_col = col("excluded high-fat foods", exclude=[".1"])
    rem_fruit_col = col("fruits (e.g., apples, citrus fruits)")
    rem_fruit_excl_col = col("excluded fruits", ".1")
    # The active-phase header uses a non-breaking space, so a plain-space match
    # finds only the remission column (".1" alone would match its "Specify" column)
    rem_veg_col = col("vegetables (e.g., cabbage, cauliflower):")
    rem_veg_excl_col = col("excluded vegetables", ".1")
    rem_grain_col = col("whole grains", ".1")
    rem_grain_excl_col = col("excluded whole grains", ".1")
    rem_nuts_col = col("nuts and seeds", ".1")
    rem_nuts_excl_col = col("excluded nuts and seeds", ".1")
    rem_lactose_col = col("lactose-containing foods", ".1")
    rem_lactose_excl_col = col("excluded lactose-containing foods", ".1")
    rem_gluten_col = col("gluten-containing foods", ".1")
    rem_gluten_excl_col = col("excluded gluten-containing foods", ".1")
    rem_spicy_col = col("spicy foods", ".1")
    rem_spicy_excl_col = col("excluded spicy foods", ".1")
    rem_fat_col = col("high fat foods", ".1")
    rem_fat_excl_col = col("excluded high-fat foods", ".1")
    fatigue_col = col("fatigue", "last 2 weeks")
    sleep_col = col("good night's sleep")
    anxiety_col = col("worried or anxious")
    bloating_col = col("abdominal bloating")
    bleeding_col = col("rectal bleeding")
    unwell_col = col("felt generally unwell")
    bmi_col = col("bmi (kg/m2)")
    endoscopy_col = col("month post-endoscopy")
    menstruation_col = col("mentruation")
    complete_cols = [c for c in columns if c.lower().startswith("complete?")]
    age_band_cols = [col("before the age of 5"), col("between 5-18"), col("19 years and older")]
    eating_cols = [
        col("picky eater"),
        col("dislike most of the foods"),
        col("list of foods that i like"),
        col("not very interested in eating"),
        col("push myself to eat regular meals"),
        col("hard for me to eat a large enough volume"),
        col("avoid or put off eating"),
        col("restrict myself to certain foods"),
        col("eat small portions"),
    ]
    # Remaining quality-of-life items not set individually below. The "EXAMPLE"
    # item is included because characteristics.R keeps it as bowel_ailment_frequency
    qol_cols = [
        c for c in columns
        if any(t in c.lower() for t in ("last 2 weeks", "past 2 weeks", "last two weeks"))
    ]
    agreement_values = [
        "Strongly disagree",
        "Disagree",
        "Somewhat disagree",
        "Somewhat agree",
        "Agree",
    ]

    for idx, participant in enumerate(PARTICIPANTS, start=1):
        row = {header: "" for header in columns}
        is_non_ibd = participant["group"] == "Non-IBD"
        row[first_pid_col] = participant["pid"]
        row[event_col] = "Phase 1 - T0"
        row[age_col] = 18 + idx * 4
        row[gender_col] = "Female" if idx % 2 == 0 else "Male"
        row[ethnicity_col] = [
            "Caucasian",
            "South Asian",
            "Latina",
            "First Nations",
            "African American",
            "Irish",
        ][(idx - 1) % 6]
        row[country_col] = [
            "Canada",
            "India",
            "Mexico",
            "Canada",
            "United States",
            "Ireland",
        ][(idx - 1) % 6]
        row[years_col] = [18, 9, 7, 22, 14, 10][(idx - 1) % 6]
        row[weight1_col] = 118 + idx * 11
        row[height1_col] = 156 + idx * 3
        row[exercise_col] = exercise_levels[(idx - 1) % len(exercise_levels)]
        row[comorb_col] = "" if idx % 2 else "seasonal allergies"
        row[family_ibd_col] = "No" if is_non_ibd else ("Yes" if idx % 3 == 1 else "No")
        row[smoking_col] = "Non-Smoker" if idx != 2 else "Former Smoker"
        row[alcohol_col] = "Social Drinker (Occasional or moderate alcohol consumption in social settings)" if idx % 3 != 0 else "Non-drinker"
        row[drug_col] = "No"
        row[abx_col] = "Yes" if idx % 4 == 2 else "No"
        row[prebiotic_col] = "Yes" if idx % 4 in (1, 0) else "No"
        row[probiotic_col] = "Yes" if idx % 3 == 0 else "No"
        row[postbiotic_col] = "No"
        row[prebiotic_name_col] = "benefiber" if row[prebiotic_col] == "Yes" else ""
        row[probiotic_name_col] = "visbiome" if row[probiotic_col] == "Yes" else ""
        row[postbiotic_name_col] = ""
        row[second_pid_col] = participant["pid"]
        row[wellbeing_col] = ["Very well = 0", "Slightly below Par = 1", "Poor = 2"][idx % 3]
        row[pain_col] = ["None = 0", "Mild = 1", "Moderate = 2"][idx % 3]
        row[stools_col] = idx % 4
        row[none_manifest_col] = checkbox(idx % 4 in (0, 3))
        row[arthalgia_col] = checkbox(idx % 4 in (1, 2))
        row[uveitis_col] = checkbox(False)
        row[erythema_col] = checkbox(False)
        row[ulcer_col] = checkbox(idx % 5 == 2)
        row[pyoderma_col] = checkbox(False)
        row[fissure_col] = checkbox(False)
        row[fistula_col] = checkbox(False)
        row[abscess_col] = checkbox(False)
        if participant["group"] == "Active IBD":
            row[hbi_col] = 4 + (idx % 3)
        elif participant["group"] == "Quiescent":
            row[hbi_col] = 1 + (idx % 2)
        else:
            row[hbi_col] = 0
        row[advanced_therapy_col] = "No change"
        row[travel_col] = "No"
        row[pregnant_col] = "No"
        row[contraception_col] = "No"
        row[condom_col] = checkbox(False)
        row[oral_contra_col] = checkbox(False)
        row[implant_col] = checkbox(False)
        row[iud_col] = checkbox(False)
        row[inclusion_col] = "Yes"
        row[weight2_col] = row[weight1_col]
        row[height2_col] = row[height1_col]
        row[gender_identity_col] = row[gender_col]
        row[change_direction_col] = ["Increase", "Decrease", "No change"][idx % 3]
        row[change_amount_col] = [3, 4, 0, 2, 0, 5][(idx - 1) % 6]
        row[oral_intake_col] = "No"
        row[cycle_col] = random_date(2 + idx, 8 + idx)
        row[cycle_symptom_col] = "No"
        row[texture_col] = "Yes" if idx % 4 == 1 else "No"
        row[texture_help_col] = "Yes" if row[texture_col] == "Yes" and idx % 2 == 1 else "No"
        row[active_fruit_col] = "No avoidance"
        row[active_fruit_excl_col] = ""
        row[active_veg_col] = "Some vegetables (Selective avoidance of certain vegetables)"
        row[active_veg_excl_col] = "broccoli, cabbage" if idx % 4 in (1, 2) else ""
        row[active_grain_col] = "No avoidance"
        row[active_grain_excl_col] = ""
        row[active_nuts_col] = "No avoidance"
        row[active_nuts_excl_col] = ""
        row[active_lactose_col] = "Some lactose-containing foods (Selective avoidance of certain lactose-containing foods)"
        row[active_lactose_excl_col] = "milk, ice cream" if idx % 4 in (1, 0) else ""
        row[active_gluten_col] = "No avoidance"
        row[active_gluten_excl_col] = ""
        row[active_spicy_col] = "Some spicy foods (Selective avoidance of certain spicy foods)"
        row[active_spicy_excl_col] = "hot sauce" if idx % 5 == 2 else ""
        row[active_fat_col] = "Some high-fat foods (Selective avoidance of certain high-fat foods)"
        row[active_fat_excl_col] = "deep fried foods" if idx % 3 != 0 else ""
        row[rem_fruit_col] = "No avoidance"
        row[rem_fruit_excl_col] = ""
        row[rem_veg_col] = "No avoidance"
        row[rem_veg_excl_col] = ""
        row[rem_grain_col] = "No avoidance"
        row[rem_grain_excl_col] = ""
        row[rem_nuts_col] = "No avoidance"
        row[rem_nuts_excl_col] = ""
        row[rem_lactose_col] = "Some lactose-containing foods (Selective avoidance of certain lactose-containing foods during remission)"
        row[rem_lactose_excl_col] = "cream" if idx % 4 in (1, 0) else ""
        row[rem_gluten_col] = "No avoidance"
        row[rem_gluten_excl_col] = ""
        row[rem_spicy_col] = "No avoidance"
        row[rem_spicy_excl_col] = ""
        row[rem_fat_col] = "Some high-fat foods (Selective avoidance of certain high-fat foods during remission)"
        row[rem_fat_excl_col] = "fried foods" if idx % 4 in (1, 2) else ""
        row[fatigue_col] = frequency_values[idx % len(frequency_values)]
        row[sleep_col] = frequency_values[(idx + 1) % len(frequency_values)]
        row[anxiety_col] = frequency_values[(idx + 2) % len(frequency_values)]
        row[bloating_col] = frequency_values[(idx + 3) % len(frequency_values)]
        row[bleeding_col] = frequency_values[(idx + 1) % len(frequency_values)]
        row[unwell_col] = frequency_values[(idx + 4) % len(frequency_values)]
        for offset, qol_col in enumerate(qol_cols):
            if row[qol_col] == "":
                row[qol_col] = frequency_values[(idx + offset) % len(frequency_values)]
        row[bmi_col] = round((row[weight1_col] * 0.453592) / (row[height1_col] / 100) ** 2, 1)
        row[endoscopy_col] = "" if is_non_ibd else 1 + idx % 6
        row[menstruation_col] = "Applicable" if row[gender_col] == "Female" else "Not Applicable"
        for complete_col in complete_cols:
            row[complete_col] = "Complete"
        for offset, band_col in enumerate(age_band_cols):
            row[band_col] = "Yes" if (idx + offset) % 3 == 0 else "No"
        for offset, eating_col in enumerate(eating_cols):
            row[eating_col] = agreement_values[(idx + offset) % len(agreement_values)]
        rows.append(row)

    return pd.DataFrame(rows, columns=columns)


def build_study_groups_frame(columns: list[str]) -> pd.DataFrame:
    labels = ["Participant ID", "Diagnosis", "Disease Activity"]
    values_per_participant = [
        lambda p: p["pid"],
        lambda p: p["diagnosis"],
        lambda p: p["activity"],
    ]
    n = min(len(columns), len(labels))

    rows = [{columns[i]: labels[i] for i in range(n)}]
    for participant in PARTICIPANTS:
        rows.append({columns[i]: values_per_participant[i](participant) for i in range(n)})
    return pd.DataFrame(rows, columns=columns)


def write_xlsx(path: Path, sheets: dict[str, pd.DataFrame]) -> None:
    with pd.ExcelWriter(path, engine="openpyxl") as writer:
        for sheet_name, df in sheets.items():
            df.to_excel(writer, sheet_name=sheet_name, index=False)


def main() -> None:
    dietary_xlsx_headers = read_xlsx_headers(RAW_DIR / "SYN_dietary data.xlsx")
    meta_headers = read_xlsx_headers(RAW_DIR / "SYN_MBI sample IDs meta.xlsx")
    myco_headers = read_xlsx_headers(RAW_DIR / "SYN_stool mycobiota relative abund.xlsx")
    biomarker_headers = read_xlsx_headers(RAW_DIR / "SYN_Inflammatory biomarkers.xlsx")
    characteristics_sheets = read_xlsx_headers(
        RAW_DIR / "SYN_Participant Characteristics.xlsx"
    )
    characteristics_headers = characteristics_sheets["Sheet1"]
    study_group_headers = characteristics_sheets.get(
        "Study groups",
        ["Participant info", "Unnamed: 1", "Unnamed: 2"],
    )

    dietary_xlsx_all = build_dietary_frame(dietary_xlsx_headers["ALL"])
    summary_header = dietary_xlsx_headers["Summary Sheet"][0]
    dietary_summary = pd.DataFrame([{summary_header: "Synthetic summary tab for demo use only."}])

    meta_df = build_meta_frame(meta_headers["Sheet1"])
    alpha_df = build_alpha_frame(myco_headers["Alpha div"])
    beta_df = (
        build_beta_frame(myco_headers["Beta div_bray curtis vectors"])
        if "Beta div_bray curtis vectors" in myco_headers
        else None
    )
    phylum_df = build_taxa_frame(myco_headers["Phylum"])
    family_df = build_taxa_frame(myco_headers["Family"])
    genus_df = build_taxa_frame(myco_headers["Genus"])
    species_df = build_taxa_frame(myco_headers["Species"])
    biomarker_df = build_inflammation_frame(biomarker_headers["Sheet1"])
    characteristics_df = build_characteristics_frame(characteristics_headers)
    study_groups_df = build_study_groups_frame(study_group_headers)

    write_xlsx(
        RAW_DIR / "SYN_dietary data.xlsx",
        {
            "ALL": dietary_xlsx_all,
            "Summary Sheet": dietary_summary,
        },
    )
    write_xlsx(RAW_DIR / "SYN_MBI sample IDs meta.xlsx", {"Sheet1": meta_df})
    write_xlsx(RAW_DIR / "SYN_Inflammatory biomarkers.xlsx", {"Sheet1": biomarker_df})
    write_xlsx(
        RAW_DIR / "SYN_Participant Characteristics.xlsx",
        {
            "Sheet1": characteristics_df,
            "Study groups": study_groups_df,
        },
    )
    myco_sheets = {
        "Alpha div": alpha_df,
        "Phylum": phylum_df,
        "Family": family_df,
        "Genus": genus_df,
        "Species": species_df,
    }
    if beta_df is not None:
        myco_sheets["Beta div_bray curtis vectors"] = beta_df

    write_xlsx(RAW_DIR / "SYN_stool mycobiota relative abund.xlsx", myco_sheets)

    print("Synthetic raw data files written to data/raw.")


if __name__ == "__main__":
    main()
