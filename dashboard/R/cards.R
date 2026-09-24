dashboard_head_tags <- function() {
  tags$head(
    tags$style(HTML("
      :root {
        --page-bg: #0D3B55;
        --page-text: #102235;
        --navbar-bg: #0D3B55;
        --navbar-text: #FFFFFF;
        --navbar-border: #F5901E;
        --card-bg: #FFFFFF;
        --card-border: #F5901E;
        --card-shadow: 0 8px 20px rgba(4, 25, 37, 0.18);
        --muted-text: #5d7280;
        --heading-text: #0D3B55;
        --panel-bg-start: #fffdf8;
        --panel-bg-end: #fff6e9;
        --panel-border: #f3c489;
        --row-border: #f1dfca;
        --label-text: #355164;
        --value-text: #0D3B55;
        --toggle-bg: #FFFFFF;
        --toggle-border: #F5901E;
        --toggle-text: #0D3B55;
        --toggle-hover-bg: #fff4e5;
        --toggle-hover-border: #dc7d10;
        --toggle-hover-text: #0D3B55;
        --accent-strong: #F5901E;
        --accent-soft: #fff1df;
        --accent-ink: #0D3B55;
        --qol-slider-track: #111111;
        --qol-slider-marker: #111111;
      }
      body.dark-mode {
        --page-bg: #111111;
        --page-text: #e6edf5;
        --navbar-bg: #111111;
        --navbar-text: #ffffff;
        --navbar-border: #F5901E;
        --card-bg: #2d2d2b;
        --card-border: #4b4b48;
        --card-shadow: 0 10px 28px rgba(0, 0, 0, 0.28);
        --muted-text: #d2c0a8;
        --heading-text: #fff4e6;
        --panel-bg-start: #343431;
        --panel-bg-end: #2d2d2b;
        --panel-border: #4f4f4c;
        --row-border: #4a4a47;
        --label-text: #f0ddc0;
        --value-text: #ffffff;
        --toggle-bg: #2d2d2b;
        --toggle-border: #F5901E;
        --toggle-text: #fff4e6;
        --toggle-hover-bg: #3a332a;
        --toggle-hover-border: #f7a94a;
        --toggle-hover-text: #ffffff;
        --accent-strong: #F5901E;
        --accent-soft: #4a3620;
        --accent-ink: #fff4e6;
        --qol-slider-track: #ffffff;
        --qol-slider-marker: #ffffff;
      }
      body {
        background: var(--page-bg);
        color: var(--page-text);
      }
      .navbar-default {
        background: var(--navbar-bg);
        border-color: var(--navbar-border);
      }
      .navbar-default .navbar-brand,
      .navbar-default .navbar-nav > li > a {
        color: var(--navbar-text) !important;
      }
      .navbar-default .navbar-brand {
        font-weight: 700;
      }
      .navbar-default .navbar-brand .brand-ibd {
        color: var(--accent-strong);
      }
      .navbar-default .navbar-brand .brand-dashboard {
        color: #ffffff;
      }
      .navbar-default .navbar-nav > li > a {
        padding: 10px 18px;
      }
      .navbar-default .navbar-nav > .active > a,
      .navbar-default .navbar-nav > .active > a:hover,
      .navbar-default .navbar-nav > .active > a:focus {
        color: #ffffff !important;
        background: var(--accent-strong);
        border-radius: 999px;
        box-shadow: none;
        padding: 8px 16px;
        margin-top: 3px;
        margin-bottom: 3px;
      }
      .navbar-default .navbar-toggle {
        border-color: var(--navbar-border);
      }
      .navbar-default .navbar-toggle .icon-bar {
        background-color: var(--navbar-text);
      }
      .navbar-default .navbar-collapse,
      .navbar-default .navbar-form {
        border-color: var(--navbar-border);
      }
      .dashboard-card {
        background: var(--card-bg);
        border: 1px solid var(--card-border);
        border-radius: 18px;
        padding: 18px 20px;
        margin-bottom: 20px;
        box-shadow: var(--card-shadow);
      }
      .dashboard-card h4 {
        margin-top: 0;
        margin-bottom: 14px;
        font-weight: 700;
        color: var(--heading-text);
        letter-spacing: 0.03em;
        text-transform: uppercase;
      }
      .control-sidebar {
        padding-right: 10px;
      }
      .control-sidebar.well {
        padding: 0;
        background: transparent;
        border: none;
        box-shadow: none;
      }
      .control-sidebar .dashboard-card {
        position: sticky;
        top: 20px;
        margin-bottom: 0;
      }
      .dashboard-row {
        margin-bottom: 8px;
      }
      .dashboard-row:last-child {
        margin-bottom: 0;
      }
      .dashboard-row-top {
        display: flex;
        flex-wrap: nowrap;
        margin-left: -15px;
        margin-right: -15px;
        margin-bottom: 25px;
      }
      .dashboard-row-top > [class*='col-'] {
        display: flex;
        padding-left: 15px;
        padding-right: 15px;
      }
      .dashboard-row-top > [class*='col-'] > .dashboard-card {
        width: 100%;
        height: 100%;
      }
      .intake-overview-note {
        margin-bottom: 16px;
        color: var(--muted-text);
        font-size: 13px;
      }
      .intake-grid {
        display: grid;
        grid-template-columns: repeat(4, minmax(0, 1fr));
        gap: 14px;
      }
      .intake-panel {
        height: 100%;
        border: 1px solid var(--panel-border);
        border-radius: 14px;
        padding: 14px 14px 12px;
        background: linear-gradient(180deg, var(--panel-bg-start) 0%, var(--panel-bg-end) 100%);
      }
      .intake-panel-header {
        margin-bottom: 10px;
      }
      .intake-panel-title {
        display: block;
        font-size: 14px;
        font-weight: 700;
        color: var(--heading-text);
      }
      .intake-panel-subtitle {
        display: block;
        margin-top: 2px;
        font-size: 12px;
        color: var(--muted-text);
      }
      .intake-table {
        width: 100%;
        font-size: 13px;
        border-collapse: collapse;
      }
      .intake-table td {
        padding: 7px 0;
        vertical-align: top;
        border-bottom: 1px solid var(--row-border);
      }
      .intake-table tr:last-child td {
        border-bottom: none;
      }
      .intake-label {
        padding-right: 10px;
        color: var(--label-text);
      }
      .intake-value {
        text-align: right;
        color: var(--value-text);
        font-weight: 600;
        font-variant-numeric: tabular-nums;
        white-space: nowrap;
      }
      .intake-toggle {
        margin-top: 10px;
        width: 100%;
        border: 1px solid var(--toggle-border);
        border-radius: 10px;
        background: var(--toggle-bg);
        color: var(--toggle-text);
        font-size: 12px;
        font-weight: 600;
      }
      .intake-toggle:hover,
      .intake-toggle:focus,
      .intake-toggle:active {
        background: var(--toggle-hover-bg);
        color: var(--toggle-hover-text);
        border-color: var(--toggle-hover-border);
      }
      @media (max-width: 1199px) {
        .intake-grid {
          grid-template-columns: repeat(2, minmax(0, 1fr));
        }
      }
      @media (max-width: 767px) {
        .intake-grid {
          grid-template-columns: minmax(0, 1fr);
        }
      }
      .dashboard-footnote {
        margin: 16px 0 6px;
        padding-top: 14px;
        border-top: 1px solid var(--card-border);
        color: var(--muted-text);
        font-size: 12px;
        line-height: 1.5;
      }
      .cfg-score-pill {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        margin: 0 0 16px;
        padding: 8px 14px;
        border-radius: 999px;
        border: 1px solid #f0c7cb;
        background: #fff2f3;
        color: #b23a48;
        font-size: 15px;
        font-weight: 700;
        line-height: 1;
      }
      .cfg-score-pill-icon {
        font-size: 15px;
      }
      .cfg-score-pill-ok {
        border-color: #b9dfc4;
        background: #edf8f0;
        color: #2f7d46;
      }
      .cfg-score-pill-mid {
        border-color: #f0ddaa;
        background: #fff8e7;
        color: #9a6a00;
      }
      .form-control,
      .selectize-input,
      .selectize-dropdown,
      .well .form-control {
        border-radius: 14px !important;
      }
      .selectize-input,
      .form-control {
        border: 1px solid var(--card-border) !important;
        box-shadow: none !important;
        background: var(--card-bg) !important;
        color: var(--value-text) !important;
      }
      .selectize-input.focus,
      .form-control:focus {
        border-color: var(--accent-strong) !important;
        box-shadow: 0 0 0 3px rgba(245, 144, 30, 0.16) !important;
      }
      .selectize-dropdown {
        background: var(--card-bg) !important;
        color: var(--value-text) !important;
        border: 1px solid var(--card-border) !important;
      }
      .selectize-dropdown .active {
        background: var(--accent-soft) !important;
        color: var(--accent-ink) !important;
      }
      .radio label,
      .checkbox label {
        color: var(--heading-text);
        font-weight: 600;
      }
      .radio input[type='radio'],
      .checkbox input[type='checkbox'] {
        accent-color: var(--accent-strong);
      }
      .irs--shiny .irs-bar,
      .irs--shiny .irs-single,
      .irs--shiny .irs-from,
      .irs--shiny .irs-to {
        background: var(--accent-strong);
        border-color: var(--accent-strong);
      }
      .irs--shiny .irs-handle {
        border: 3px solid var(--accent-strong);
        background: var(--card-bg);
        box-shadow: 0 0 0 3px rgba(245, 144, 30, 0.16);
      }
      .irs--shiny .irs-line {
        background: rgba(13, 59, 85, 0.14);
      }
      body.dark-mode .irs--shiny .irs-line {
        background: rgba(255, 244, 230, 0.12);
      }
      .btn-default,
      .btn-primary {
        border-radius: 999px;
        border-color: var(--accent-strong);
        background: var(--accent-strong);
        color: #ffffff;
      }
      .btn-default:hover,
      .btn-default:focus,
      .btn-primary:hover,
      .btn-primary:focus {
        background: #dc7d10;
        border-color: #dc7d10;
        color: #ffffff;
      }
      .qol-card {
        display: grid;
        grid-template-columns: minmax(190px, 0.95fr) minmax(0, 1.45fr);
        gap: 26px;
        align-items: stretch;
        min-height: 100%;
      }
      .qol-card > div:first-child {
        display: flex;
        flex-direction: column;
        justify-content: space-between;
        min-height: 100%;
      }
      .qol-summary-score {
        display: flex;
        align-items: baseline;
        gap: 10px;
        margin-bottom: 24px;
      }
      .qol-summary-value {
        color: var(--accent-strong);
        font-size: 56px;
        font-weight: 800;
        line-height: 0.95;
        letter-spacing: -0.03em;
      }
      .qol-summary-total {
        color: var(--muted-text);
        font-size: 20px;
        font-weight: 700;
      }
      .qol-summary-meta {
        margin-bottom: 14px;
        color: var(--muted-text);
        font-size: 14px;
        font-weight: 600;
      }
      .qol-summary-scale-wrap {
        position: relative;
        margin-top: 14px;
        padding-top: 16px;
      }
      .qol-summary-scale {
        position: relative;
        height: 14px;
        border-radius: 999px;
        background: linear-gradient(90deg, #79b51d 0%, #f7c45b 48%, #f16457 100%);
        box-shadow: inset 0 0 0 2px var(--qol-slider-track);
      }
      .qol-summary-marker {
        position: absolute;
        top: 4px;
        width: 3px;
        height: 24px;
        border-radius: 999px;
        transform: translateX(-50%);
        background: var(--qol-slider-marker);
        box-shadow: 0 0 0 1px rgba(13, 59, 85, 0.18);
      }
      .qol-summary-axis {
        display: flex;
        justify-content: space-between;
        margin-top: 10px;
        color: var(--muted-text);
        font-size: 12px;
        font-weight: 700;
      }
      .qol-bars {
        display: grid;
        gap: 12px;
        align-content: center;
      }
      .qol-bar-row {
        display: grid;
        grid-template-columns: minmax(150px, 1fr) minmax(0, 2fr) 44px;
        gap: 12px;
        align-items: center;
      }
      .qol-bar-label {
        color: var(--heading-text);
        font-size: 13px;
        font-weight: 700;
        line-height: 1.15;
      }
      .qol-bar-track {
        position: relative;
        height: 10px;
        border-radius: 999px;
        background: rgba(13, 59, 85, 0.12);
        overflow: hidden;
      }
      .qol-bar-fill {
        height: 100%;
        border-radius: 999px;
      }
      .qol-bar-pct {
        color: var(--muted-text);
        font-size: 12px;
        font-weight: 700;
        text-align: right;
      }
      .qol-caption {
        margin-top: 14px;
        color: var(--muted-text);
        font-size: 12px;
        font-weight: 600;
        line-height: 1.35;
      }
      @media (max-width: 1199px) {
        .dashboard-row-top {
          display: block;
        }
        .dashboard-row-top > [class*='col-'] {
          display: block;
        }
        .qol-card {
          grid-template-columns: minmax(0, 1fr);
          gap: 18px;
        }
      }
      @media (max-width: 767px) {
        .qol-bar-row {
          grid-template-columns: minmax(0, 1fr);
          gap: 6px;
        }
        .qol-bar-pct {
          text-align: left;
        }
      }
      .theme-toggle-nav {
        padding: 8px 10px 8px 14px;
      }
      .theme-toggle-button {
        display: inline-flex;
        align-items: center;
        gap: 10px;
        padding: 6px 12px;
        border: 1px solid var(--toggle-border);
        border-radius: 999px;
        background: var(--toggle-bg);
        color: var(--toggle-text);
        font-size: 12px;
        font-weight: 700;
        letter-spacing: 0.02em;
        cursor: pointer;
        user-select: none;
      }
      .theme-toggle-button:hover,
      .theme-toggle-button:focus {
        background: var(--toggle-hover-bg);
        color: var(--toggle-hover-text);
        border-color: var(--toggle-hover-border);
        text-decoration: none;
        outline: none;
      }
      .theme-toggle-track {
        position: relative;
        width: 38px;
        height: 20px;
        border-radius: 999px;
        background: #c6d5e3;
        transition: background 0.2s ease;
      }
      .theme-toggle-track::after {
        content: '';
        position: absolute;
        top: 2px;
        left: 2px;
        width: 16px;
        height: 16px;
        border-radius: 50%;
        background: #ffffff;
        box-shadow: 0 1px 3px rgba(15, 23, 42, 0.25);
        transition: transform 0.2s ease;
      }
      body.dark-mode .theme-toggle-track {
        background: #4c6a86;
      }
      body.dark-mode .theme-toggle-track::after {
        transform: translateX(18px);
      }
      @media (max-width: 767px) {
        .theme-toggle-nav {
          padding: 8px 15px 12px;
        }
      }
    ")),
    tags$script(HTML("
      (function() {
        function getTheme() {
          return localStorage.getItem('ibd-dashboard-theme') || 'light';
        }

        function applyTheme(mode) {
          document.body.classList.toggle('dark-mode', mode === 'dark');
          var label = document.querySelector('[data-theme-label]');
          if (label) {
            label.textContent = mode === 'dark' ? 'Dark mode' : 'Light mode';
          }
          var button = document.getElementById('theme-toggle-button');
          if (button) {
            button.setAttribute('aria-pressed', mode === 'dark' ? 'true' : 'false');
          }
        }

        function mountThemeToggle() {
          var nav = document.querySelector('.navbar .nav.navbar-nav');
          var toggleItem = document.getElementById('theme-toggle-nav-item');
          if (nav && toggleItem && toggleItem.parentNode !== nav) {
            nav.appendChild(toggleItem);
            toggleItem.style.display = '';
          }

          var button = document.getElementById('theme-toggle-button');
          if (button && !button.dataset.bound) {
            button.addEventListener('click', function() {
              var nextTheme = document.body.classList.contains('dark-mode') ? 'light' : 'dark';
              localStorage.setItem('ibd-dashboard-theme', nextTheme);
              applyTheme(nextTheme);
            });
            button.dataset.bound = 'true';
          }
          applyTheme(getTheme());
        }

        document.addEventListener('DOMContentLoaded', mountThemeToggle);
      })();
    "))
  )
}

dashboard_card <- function(title, ...) {
  div(
    class = "dashboard-card",
    h4(title),
    ...
  )
}

dashboard_footnote <- function() {
  tags$div(
    class = "dashboard-footnote",
    "2026 MDS Capstone project in partnership with a hospital research partner. Team: Tiffany Chu, Victoria Farkas, Ian Gault, Derrick Jaskiel. Mentor: Payman Nickchi. All data shown is synthetic."
  )
}

dashboard_theme_toggle <- function() {
  tags$li(
    id = "theme-toggle-nav-item",
    class = "theme-toggle-nav",
    style = "display:none;",
    tags$button(
      id = "theme-toggle-button",
      type = "button",
      class = "theme-toggle-button",
      `aria-pressed` = "false",
      tags$span(class = "theme-toggle-track", `aria-hidden` = "true"),
      tags$span(`data-theme-label` = NA, "Light mode")
    )
  )
}
