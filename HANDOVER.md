# Project Handover Guide

This guide walks through taking ownership of the IBD dashboard demo repository: setting up your environment, pointing the project to your own GitHub account, and enabling automated deployment of the statistics site.

This is a one-time setup. After completing it, refer to `README.md` for day-to-day usage.

These instructions were based on the installation stack set up by the MDS program. See the [MDS setup guide](https://ubc-mds.github.io/resources_pages/install_ds_stack_windows/) for more detailed descriptions.

**Note:** GenAI was used to help generate the content on this page, based on the MDS stack website.

---

## Table of contents

1.  [Install prerequisites](#1-install-prerequisites)
2.  [Add raw data files](#2-add-raw-data-files)
3.  [GitHub account notes](#3-github-account-notes)
4.  [Take ownership of the repository](#4-take-ownership-of-the-repository)
5.  [Set up the R environment](#5-set-up-the-r-environment)
6.  [Enable GitHub Actions and Netlify deployment](#6-enable-github-actions-and-netlify-deployment)
7.  [Update hardcoded URLs](#7-update-hardcoded-urls)
8.  [Verify everything works](#8-verify-everything-works)
9.  [Host the Shiny dashboard on Posit Connect Cloud](#9-host-the-shiny-dashboard-on-posit-connect-cloud)

---

## 1. Install prerequisites

Install each tool below before running any project commands. All commands in this guide assume you are running **Git Bash** on Windows (or a standard Terminal on Mac).

### Definitions

- **Terminal** = the window. Just a display surface that shows text and captures keystrokes. Windows Terminal, the macOS Terminal app, iTerm2 — these are all just windows. They do no interpreting themselves.
- **Shell** = the interpreter running _inside_ that window. Bash, Zsh, etc. This is what actually understands `cd` and `git`.
- **Kernel** = the OS core the shell talks to.

::: {.panel-tabset}

### Windows

Windows has no Unix shell or git by default, so you install **Git for Windows**, which brings both. Terminal can run several shells; we want the default to run Git Bash.

### macOS

macOS provides git through Apple's **Command Line Tools**, which it will automatically prompt you to install on first use. Modern macOS installations utilize **Zsh** as the default shell interpreter inside the terminal application.
:::

### Visual Studio Code

**VS Code** is not the only option for the terminal/Git Bash setup, but the guide uses it in several steps as a code editor. VS Code is both a powerful text editor and a full-blown Python interactive development environment (IDE). We'll be using it in several nearby steps as a basic code editor.

1.  Download VS Code from [code.visualstudio.com/download](https://code.visualstudio.com/download) and run the installer.

2.  On the **Select Additional Tasks** page, ensure **"Add to PATH"** is checked (it is by default). This is what lets you type `code` in the terminal and what lets Git find VS Code as its editor.

3.  Confirm it works — open a terminal and run:

    **Run in Git Bash:**

    ```bash
    code --version
    ```

### Git and Git Bash (Windows only)

For a full description and screenshots, see the MDS stack installation instructions. Key points are below.

On Windows:

1.  Confirm if you are on a x64- or ARM64-based processor. Download the latest **64-bit** installer from [git-scm.com/download/win](https://git-scm.com/download/win).

2.  Run the installer. Make the following selections when prompted — accept all other defaults:
    - **"Add Git Bash profile to Windows Terminal"** — check this box
    - **"Use Visual Studio Code as Git's default editor"**
    - **"Override the default branch name for new repositories"** → type `main`
    - **"Git from the command line and also from 3rd-party software"** (PATH option)
    - **"Use MinTTY (the default terminal of MSYS2)"** (terminal emulator)

3.  After the install completes, configure your identity in Git Bash:

    **Run in Git Bash:**

    ```bash
    git config --global user.name "Your Name"
    git config --global user.email "your.email@example.com"
    ```

4.  Confirm git works:

    **Run in Git Bash:**

    ```bash
    git --version
    ```

### Windows Terminal (Windows only)

Windows Terminal gives you a cleaner experience than the standalone Git Bash window.

1.  Install it from the Microsoft Store: [aka.ms/terminal](https://aka.ms/terminal).
2.  Open Windows Terminal → **Settings** → **Startup** → **Default profile** → select **Git Bash**.

All commands in this guide should be run inside Git Bash (via Windows Terminal or standalone), not Windows Command Prompt or PowerShell.

### R 4.6.0

The project pins R package versions via `renv.lock`. Using **exactly R 4.6.0** avoids package incompatibilities.

1.  Download R 4.6.0 from [cran.r-project.org](https://cran.r-project.org/).

2.  Run the installer with default options.

3.  **(Windows only)** Add R to your Git Bash PATH. Open (or create) `~/.bash_profile` in VS Code:

    **Run in Git Bash:**

    ```bash
    code ~/.bash_profile
    ```

    **Add to `~/.bash_profile`:**

    ```bash
    R_DIR=(/c/Program\ Files/R/*/bin/x64)
    export PATH="${R_DIR}:$PATH"
    ```

4.  Save the file, close Git Bash, and reopen it. Confirm:

    **Run in Git Bash:**

    ```bash
    Rscript --version
    ```

    The output should say `4.6.0`.

### Windows Git Bash home-directory check

If R or `renv` fails in Git Bash with path, library, or profile errors, first confirm that Git Bash and R agree on the user's home directory.

**Run in Git Bash:**

```bash
echo $HOME
Rscript -e "Sys.getenv(c('HOME','R_USER','USERPROFILE','LOCALAPPDATA'))"
Rscript -e "sessionInfo()"
```

On Windows, `HOME` should usually point to the Windows user folder in Git Bash form, for example:

```text
/c/Users/YOUR_WINDOWS_USERNAME
```

If `HOME` is wrong, set it before running project commands:

```bash
export HOME=/c/Users/YOUR_WINDOWS_USERNAME
unset R_USER
```

Replace `YOUR_WINDOWS_USERNAME` with the actual Windows username, then close Git Bash and reopen it.

### Quarto CLI

Quarto renders the statistical analysis site.

1.  Download the latest Quarto CLI installer from [quarto.org/docs/get-started](https://quarto.org/docs/get-started/).

2.  Run the installer with default options.

3.  Confirm in Git Bash:

    ```bash
    quarto --version
    ```

> **Windows Git Bash gotcha:** If `quarto` is not found in Git Bash but the installer completed successfully, try `quarto.cmd` instead. You can add an alias to `~/.bash_profile` to fix this permanently:
>
> ```bash
> alias quarto=quarto.cmd
> ```

### GNU Make (Windows only)

Mac has `make` built in. On Windows:

1.  Download `make-4.4.1-without-guile-w32-bin.zip` from [sourceforge.net/projects/ezwinports](https://sourceforge.net/projects/ezwinports/files/make-4.4.1-without-guile-w32-bin.zip/download).

2.  Extract the zip. Move the extracted folder to:

    ```text
    C:\Users\YOUR_USERNAME\make-4.4.1
    ```

3.  Add Make to your Git Bash PATH and keep R on the PATH. Reopen `~/.bash_profile` in VS Code:

    **Run in Git Bash:**

    ```bash
    code ~/.bash_profile
    ```

    Earlier, the R section added R to this file so `Rscript` can be found from Git Bash. Do not remove that. This step expands the same PATH configuration so Git Bash can also find GNU Make.

    Update `~/.bash_profile` so the relevant lines look like this:

    ```bash
    # R for Git Bash
    R_DIR=(/c/Program\ Files/R/*/bin/x64)

    # GNU Make for Git Bash
    export PATH="/c/Users/${USERNAME}/make-4.4.1/bin:${R_DIR}:$PATH"

    # Use VS Code as the default shell editor
    EDITOR="code --wait"
    VISUAL=$EDITOR
    ```

    The Make path is placed before the R path so Git Bash finds `make` first, while still keeping `Rscript` available.

4.  Also create or open `~/.bashrc` and add the following so `.bash_profile` is always loaded:

    **Run in Git Bash:**

    ```bash
    code ~/.bashrc
    ```

    **Add to `~/.bashrc`:**

    ```bash
    # Do not put project-specific PATH settings here.
    # Keep them in ~/.bash_profile and load that file from here.

    if [ -f ~/.bash_profile ]; then
      . ~/.bash_profile
    fi
    ```

    In this guide, `~/.bash_profile` is where we keep the actual Git Bash configuration, including R, Make, and the default editor. `~/.bashrc` only ensures that configuration is loaded consistently.

    The key conceptual distinction:
    - `~/.bash_profile` = where you define the tools Git Bash should know about.

    - `~/.bashrc` = a small loader that makes sure `.bash_profile` gets read.

5.  Close Git Bash and reopen it. Confirm:

    ```bash
    make --version
    Rscript --version
    ```

### Recommended IDE

[Positron](https://positron.posit.co/) or [RStudio](https://posit.co/download/rstudio-desktop/) — either works. Open the project by opening the repository root folder.

---

## 2. Add raw data files

The synthetic raw data files are committed in `data/raw/`, so no extra files are needed. To regenerate them, run `python3 src/synth_data/generate_fake_raw_data.py`. The pipelines expect these filenames:

| File                                      | Description                   |
| ----------------------------------------- | ----------------------------- |
| `SYN_MBI sample IDs meta.xlsx`            | Mycobiome sample metadata     |
| `SYN_stool mycobiota relative abund.xlsx` | Mycobiome taxa abundances     |
| `SYN_Inflammatory biomarkers.xlsx`        | Inflammatory biomarker values |
| `SYN_dietary data.xlsx`                   | Dietary intake data           |
| `SYN_Participant Characteristics.xlsx`    | Participant characteristics   |

If `data/raw/` does not exist yet, create it:

```bash
mkdir -p data/raw
```

---

## 3. GitHub account notes

This project's **stats site is deployed to Netlify**, not GitHub Pages. That means you can keep the repository private on a standard GitHub account and still publish the rendered Quarto site publicly through Netlify.

GitHub Education is still a nice optional benefit if you qualify, but it is **not required** for the stats site deployment flow documented here.

The main thing that still matters is repository privacy:

- Keep the repository **Private** while it contains raw data, credentials, or sensitive participant-level outputs.
- Treat the published stats site as **public-facing** content, regardless of whether the GitHub repo itself is private.
- Do not commit raw data, secrets, or anything that should not appear in a public rendered site.

Useful references:

- [GitHub plans documentation](https://docs.github.com/en/get-started/learning-about-github/githubs-plans)
- [GitHub Education](https://github.com/education)
- [Netlify docs](https://docs.netlify.com/)

---

## 4. Take ownership of the repository

This section covers creating your own copy of the project on GitHub and pointing your local clone to it.

### Step 1 — Create a new GitHub repository

1.  Go to [github.com](https://github.com) and sign in.
2.  Click **+** → **New repository**.
3.  Give it a name (e.g. `ibd-dashboard-demo`).
4.  Set visibility to **Private** (recommended while raw data is present) or Public.
5.  **Do not** initialize with a README, `.gitignore`, or license — leave the repo completely empty.
6.  Click **Create repository**.

### Step 2 — Clone the original repository

If you do not already have the project locally:

```bash
git clone https://github.com/iangault/ibd-dashboard-demo.git
cd ibd-dashboard-demo
```

If you already have it locally, `cd` into the project folder.

### Step 3 — Point your local clone to your new repository

Replace `YOUR_USERNAME` and `YOUR_REPO_NAME` with your GitHub username and the repo name you created in Step 1.

**Using HTTPS:**

```bash
git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
```

**Using SSH** (if you have SSH keys set up with GitHub):

```bash
git remote set-url origin git@github.com:YOUR_USERNAME/YOUR_REPO_NAME.git
```

Confirm the change:

```bash
git remote -v
```

Both lines should now show your repo URL.

### Step 4 — Push to your repository

```bash
git push -u origin main
```

This pushes the `main` branch to your new repository, including the existing GitHub Actions workflow at `.github/workflows/deploy-netlify.yml`.

That workflow is already set up to render the Quarto site in `stats/` and publish the rendered HTML to Netlify.

Before that first deploy can work, finish the GitHub Actions and Netlify setup in Section 6.

---

## 5. Set up the R environment

### Compiler prerequisites (do this before `make setup`)

`renv.lock` pins a recent R version (4.6.0). Right after a new R release, CRAN/Bioconductor have not yet published **binary** packages for every platform/architecture, so `renv::restore()` may silently fall back to **building some packages from source**. A source build needs a compiler toolchain and system libraries that a fresh R install does not include by default. Installing these first avoids needing to manually install packages after `make setup` reports failures.

**Windows:** install [Rtools45](https://cran.r-project.org/bin/windows/Rtools/) **before** running `make setup` (Rtools45 covers R 4.5.x through R 4.6.x and R-devel — there is no separate "Rtools46"). Download and run the installer `.exe`, accepting the default install location (`C:\rtools45`); no `winget`/`choco` package is available, so the installer is the only supported install method. Without it, any package that needs compiling (e.g. `openssl`, `curl`) will fail with a "could not find tools" / compilation error.

**macOS:** packages like `openssl` link against system OpenSSL via Homebrew. If you're on Apple Silicon (M-series), the default `pkg-config` search path points at the Intel Homebrew location and won't find it, causing an `ANTICONF` / `opensslv.h not found` error.

If you don't already have [Homebrew](https://brew.sh/) installed, install it first:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then, before running `make setup`:

```bash
brew install openssl
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig"
```

(On Intel Macs, Homebrew installs to `/usr/local`, so the default search path already works and this step isn't usually needed.)

**Note:** both of these are machine-wide installs, not scoped to a conda environment or to this project. Rtools installs to a fixed system location (`C:\rtools45`) and any R on the machine finds it automatically; Homebrew packages are likewise installed system-wide, not into a conda env. If you created a conda environment just to isolate this project's R version, you still only need to install Rtools/Homebrew OpenSSL once per machine — they aren't, and can't be, installed _into_ the conda env itself.

From the repository root, restore the locked R package library:

```bash
make setup
```

This installs `renv` if needed and runs `renv::restore()` to install the exact package versions recorded in `renv.lock`. It may take several minutes on first run.

If `make` is not working yet, the equivalent command is:

```bash
Rscript -e "options(repos=c(CRAN='https://cran.rstudio.com/')); if (!requireNamespace('renv', quietly=TRUE)) install.packages('renv'); renv::restore(prompt = FALSE)"
```

---

## 6. Enable GitHub Actions and Netlify deployment

The repository already includes a GitHub Actions workflow (`.github/workflows/deploy-netlify.yml`). It renders the Quarto stats site and deploys the rendered output in `stats/_site/` to Netlify whenever you push to `main`.

You do not need to write a new workflow. You only need to confirm that your repository allows Actions to run and that the required Netlify secrets are configured.

### Step 1 — Enable workflow write permissions

1.  Go to your repository on GitHub.
2.  Click **Settings** → **Actions** → **General**.
3.  Confirm Actions are allowed for the repository.
4.  Scroll to **Workflow permissions**.
5.  Select **Read and write permissions**.
6.  Click **Save**.

This allows the workflow to run normally and use the default `GITHUB_TOKEN`.

### Step 2 — Create a Netlify site

1.  Sign in to [Netlify](https://app.netlify.com/).
2.  Create a new site. You can create an empty site first or import the GitHub repository.
3.  Note the site's:
    - **Site name** or public URL
    - **Site ID** (Site configuration → General)
4.  Create a Netlify personal access token:
    - Go to **User settings** → **Applications** → **Personal access tokens**
    - Create and copy the token value

### Step 3 — Add Netlify secrets to GitHub

1.  In your GitHub repository, go to **Settings** → **Secrets and variables** → **Actions**.
2.  Add these repository secrets:
    - `NETLIFY_AUTH_TOKEN`: your Netlify personal access token
    - `NETLIFY_SITE_ID`: the Netlify site ID from Step 2

The workflow reads both secrets from `.github/workflows/deploy-netlify.yml` during deployment.

### Step 4 — Trigger the first deploy

Push a commit to `main`. This workflow is currently configured to deploy on every push to `main`.

The workflow will take several minutes on first run because it restores the R environment and renders the Quarto site from scratch. Once it completes, your stats site will be live at your Netlify URL, for example:

```text
https://YOUR_NETLIFY_SITE.netlify.app/
```

---

## 7. Update hardcoded URLs

The stats site configuration contains URLs pointing to the original repository and the original Netlify deployment. Update them to point to your own.

Open `stats/_quarto.yml` and replace the three highlighted lines:

```yaml
website:
  title: "MDS Capstone Project"
  site-url: "https://YOUR_NETLIFY_SITE.netlify.app/"            # <-- update
  repo-url: "https://github.com/YOUR_USERNAME/YOUR_REPO_NAME"   # <-- update
  navbar:
    ...
    right:
      - icon: github
        href: "https://github.com/YOUR_USERNAME/YOUR_REPO_NAME" # <-- update
```

Also update the stats site link near the top of `README.md`:

```markdown
Stats site: [click here!](https://YOUR_NETLIFY_SITE.netlify.app/)
```

Commit and push after editing:

```bash
git add stats/_quarto.yml README.md
git commit -m "Update repo and site URLs to new owner"
git push
```

---

## 8. Verify everything works

Run these commands in order from the repository root. Each step depends on the previous one completing successfully.

```bash
make setup           # restore R packages

make mycobiome       # process mycobiome data
make dietary         # clean dietary data and generate figures
make characteristics # clean participant characteristics
make merge           # build merged analysis files

make stats           # render the full Quarto stats site
make app             # launch the Shiny dashboard in your browser
```

To view the rendered stats site locally after `make stats`:

```bash
# macOS
open stats/_site/index.html

# Windows (Git Bash)
start stats/_site/index.html
```

To verify the deployed version:

1.  Push a small change to `main`.
2.  Open **Actions** on GitHub and confirm `Render and Deploy Quarto to Netlify` succeeds.
3.  Open your Netlify site URL and confirm the updated content is live.

---

## 9. Host the Shiny dashboard on Posit Connect Cloud

The Netlify setup in Section 6 hosts the rendered Quarto stats site. It does **not** host the interactive Shiny dashboard.

This project deploys the dashboard **directly from your machine to Posit Connect Cloud**, via the `rsconnect` R package — it does not go through GitHub at all. This sidesteps the Connect Cloud free-tier restriction that blocks publishing from a _private_ GitHub repository (see [Connect Cloud's GitHub publishing docs](https://docs.posit.co/connect-cloud/user/publish/github.html)): that restriction only applies to the GitHub-linked deploy path, not a manual/CLI deploy.

> **GitHub account note:** Section 3 explains that the Quarto stats site is published through Netlify, not GitHub Pages. That means a standard private GitHub repository is fine for the stats site setup. This dashboard section is separate again: the manual `rsconnect` deploy goes straight to Posit Connect Cloud and does not depend on Netlify or GitHub publishing permissions.

In the original private project, the dashboard was also gated behind a login screen ([shinymanager](https://datastorm-open.github.io/shinymanager/)), since a Connect Cloud free-tier app is public by URL. This public demo runs on synthetic data only, so that login gate has been removed (see `dashboard/ui.R` / `dashboard/server.R`).

### Step 1 — Create a Posit Connect Cloud account and link it locally

This is a single-account setup, not one-account-per-person: there is exactly **one** canonical deployed dashboard, living under one Connect Cloud account. If the dashboard is already deployed to your account, and then a colleague goes through the same process, they'd be able to deploy on their own account but it would be a duplicate from the original. The best approach would be for there to be one account that does the deployment and maintenance. Another option is creating a shared Posit Connect Cloud account - but based on current needs, only **one** personal account is necessary.

1.  Go to [connect.posit.cloud](https://connect.posit.cloud/) and sign up or sign in.
2.  From a terminal in the project root, run (after `make setup`, so `rsconnect` is installed):

    ```bash
    Rscript -e "rsconnect::connectCloudUser(launch.browser = TRUE)"
    ```

3.  This opens your browser to log in and authorize the connection. `rsconnect` stores the resulting token locally — no further setup needed.
4.  Confirm the link worked:

    ```bash
    Rscript -e "rsconnect::accounts()"
    ```

    You should see a row with `server: connect.posit.cloud` and your account name.

> **Posit Publisher (RStudio/Positron GUI "Publish" button) note:** this is a _separate_ tool from `rsconnect`, with its own independent credential store. Linking `rsconnect` via Step 2 above does **not** make Posit Publisher aware of the account — it needs its own "Add Credential" step (Command Palette → "Posit Publisher: Add Credential") with an API key from your Connect Cloud account settings. The CLI steps below don't require Posit Publisher at all.

### Step 2 — Deploy

```bash
make deploy
```

This single command does two things, in order:

1.  Refreshes `dashboard/data/` from `data/processed/merged.csv`, `data/processed/participants_all.csv`, and `data/intermediate/inflammatory_markers.rds` (same `dashboard-data` prerequisite `make app` uses locally). `dashboard/global.R` reads from `dashboard/data/`, not `data/processed/` directly — this keeps `dashboard/` self-contained so it can be deployed as a single bundle without reaching outside its own folder (Connect Cloud's deploy bundle only includes files inside the directory you deploy; it cannot read `../data/`). If the source files don't exist yet, run the pipeline first: `make mycobiome`, `make dietary`, `make characteristics`, `make merge`.
2.  Runs `rsconnect::deployApp('dashboard', appName = 'ibd-dashboard-demo', ...)`, which bundles every file in `dashboard/`, captures package dependencies from `renv.lock`, and uploads it to Connect Cloud over HTTPS — no GitHub, no CI, no manifest file to maintain by hand (it's generated automatically per deploy).

The `appName` is hardcoded in the Makefile, so `make deploy` always targets the one canonical app — including the **very first deploy on a brand-new machine**. `rsconnect` looks up apps by name on the Connect Cloud server itself, not just in the local (gitignored) `dashboard/rsconnect/` deployment record, so as long as you're linked to the account that owns `ibd-dashboard-demo` (Step 1), `make deploy` finds and updates the existing app rather than creating a second one. There's no separate first-time command to run — `make deploy` is the one command, every time, for everyone who has access to that account.

On success, the command prints the deployed app's URL. Save it somewhere visible (e.g. `README.md`) once there's a stable deployed copy worth documenting.

### Step 3 — Test

1.  Open the printed deployment URL in a browser.
2.  Confirm the shinymanager login screen appears (it's the gate, not a bug — log in with the shared credentials from `dashboard/R/auth.R`).
3.  After logging in, click through the dashboard tabs and confirm plots, cards, and filters load.

### Redeploying after changes

Just run `make deploy` again.

### Troubleshooting

| Problem                                                                                  | Fix                                                                                                                                                                                                                                  |
| ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `make: command not found`                                                                | Re-check the Make install and PATH in `~/.bash_profile`; restart Git Bash                                                                                                                                                            |
| `Rscript: command not found`                                                             | R is not on PATH; reinstall R and confirm version with `Rscript --version`                                                                                                                                                           |
| `quarto: command not found`                                                              | Reinstall Quarto CLI from [quarto.org](https://quarto.org/docs/get-started/); on Windows Git Bash try `quarto.cmd` or add `alias quarto=quarto.cmd` to `~/.bash_profile`                                                             |
| `Missing data/intermediate/alpha_long.rds`                                               | Run `make mycobiome` before `make stats`                                                                                                                                                                                             |
| GitHub Actions workflow fails on first run                                               | Check that Actions are enabled and that `NETLIFY_AUTH_TOKEN` and `NETLIFY_SITE_ID` are set correctly (Section 6)                                                                                                                   |
| Netlify site does not update after a successful push                                     | Open the GitHub Actions run, confirm `Render and Deploy Quarto to Netlify` succeeded, then verify the Netlify site ID and auth token secrets                                                                                      |
| `renv` package errors                                                                    | Run `make setup`; confirm R version is exactly 4.6.0                                                                                                                                                                                 |
| `make setup` fails to compile a package on Windows (e.g. `openssl`, `curl`)              | Install [Rtools45](https://cran.r-project.org/bin/windows/Rtools/) (covers R 4.5.x–4.6.x), then re-run `make setup` (see Section 5)                                                                                                  |
| `make setup` fails on macOS with `ANTICONF`/`opensslv.h file not found`                  | On Apple Silicon, run `brew install openssl` and `export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig"` before re-running `make setup` (see Section 5)                                                                 |
| Dashboard cards cut off                                                                  | Press `Ctrl + -` (zoom out) in your browser                                                                                                                                                                                          |
| Deployed dashboard shows a missing-data error                                            | `make deploy` refreshes `dashboard/data/` automatically — if it still errors, check that `data/processed/` and `data/intermediate/` exist locally (run `make mycobiome`, `make dietary`, `make characteristics`, `make merge` first) |
| `make deploy` fails with "No accounts registered"                                        | Run `rsconnect::connectCloudUser()` first (Section 9, Step 1) to link your Connect Cloud account                                                                                                                                     |
| Posit Publisher shows no Connect Cloud account, even though `rsconnect::accounts()` does | Expected — they're separate credential stores (Section 9, Step 1). Either use `make deploy`/`rsconnect::deployApp()` directly, or add a Posit Publisher credential separately                                                        |
