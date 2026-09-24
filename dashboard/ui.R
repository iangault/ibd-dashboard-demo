source(file.path("R", "individual_ui.R"), local = TRUE)
source(file.path("R", "population_ui.R"), local = TRUE)

ui <- navbarPage(
  title = tagList(
    tags$span(class = "brand-ibd", "IBD"),
    " ",
    tags$span(class = "brand-dashboard", "Dashboard")
  ),
  header = tagList(
    dashboard_head_tags(),
    tags$div(
      style = "display:none;",
      dashboard_theme_toggle()
    )
  ),
  individual_tab_ui(),
  population_tab_ui()
)
