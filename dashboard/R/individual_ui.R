individual_tab_ui <- function() {
  tabPanel(
    "Individual",
    sidebarLayout(
      sidebarPanel(
        width = 2,
        class = "control-sidebar",
        dashboard_card(
          "Search Participant",
          selectizeInput(
            "search_id",
            "Enter participant ID",
            choices = participant_choices,
            selected = NULL,
            options = list(placeholder = "e.g. SYN_18")
          ),
          radioButtons(
            "individual_taxa_level",
            "Taxonomic Level",
            choices = c("Phylum", "Family", "Genus", "Species"),
            selected = "Phylum"
          ),
          # Number of taxa to display
          sliderInput(
            "indiv_top_n",
            "Number of Taxa to Display",
            min = 5,
            max = 15,
            value = 10
          ),
          # Toggle for displaying all taxa
          checkboxInput(
            "indiv_display_all_taxa",
            "Display all taxa",
            value = FALSE
          )
        )
      ),
      mainPanel(
        width = 10,
        fluidRow(
          class = "dashboard-row dashboard-row-top",
          column(
            width = 4,
            dashboard_card(
              "Participant Information",
              uiOutput("participant_info")
            )
          ),
          column(
            width = 3,
            dashboard_card(
              "Disease Activity",
              uiOutput("disease_activity_card")
            )
          ),
          column(
            width = 5,
            dashboard_card(
              "Quality of Life (QOL)",
              uiOutput("symptom_burden_card")
            )
          )
        ),
        fluidRow(
          class = "dashboard-row",
          column(
            width = 6,
            dashboard_card(
              "Mycobiome Composition",
              plotlyOutput("microbiome_pie", height = "300px")
            )
          ),
          column(
            width = 6,
            dashboard_card(
              "Participant vs Canadian Food Guide",
              uiOutput("cfg_card")
            )
          )
        ),
        fluidRow(
          class = "dashboard-row",
          column(
            width = 12,
            dashboard_card(
              "Food Avoidance",
              uiOutput("food_avoidance_card")
            )
          )
        ),
        fluidRow(
          class = "dashboard-row",
          column(
            width = 12,
            dashboard_card(
              "Nutrients and Vitamins",
              uiOutput("nutrient_vitamin_card")
            )
          )
        ),
        fluidRow(
          class = "dashboard-row",
          column(
            width = 12,
            dashboard_footnote()
          )
        )
      )
    )
  )
}
