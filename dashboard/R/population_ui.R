population_tab_ui <- function() {
  tabPanel("Cohort",
           fluidPage(
             
              fluidRow(
                class = "dashboard-row dashboard-row-top",

                # Population control panel
                column(
                  width = 4,
                  div(
                    class = "dashboard-card",
                    h4("Cohort Controls"),
               
                    # Toggle between IBD/Non-IBD groups
                    selectInput(
                    "group_filter",
                    "Study Group",
                    choices = c("All", "Active IBD", "Quiescent", "Non-IBD")
                    ),
                 
                    # Toggle between taxa data
                    radioButtons(
                      "taxa_level",
                      "Taxonomic Level",
                      choices = c("Phylum", "Family", "Genus", "Species"),
                      selected = "Phylum"
                    ),
               
                    # Number of taxa to display
                    sliderInput(
                      "top_n",
                      "Number of Taxa to Display",
                      min = 5,
                      max = 15,
                      value = 10
                    ),

                    # Toggle for displaying all taxa
                    checkboxInput(
                      "display_all_taxa",
                      "Display all taxa",
                      value = FALSE
                    )
                  )
                ),

                # Cohort summary
                column(
                  width = 4,
                  div(
                     class = "dashboard-card",
                     h4("Cohort Summary"),
                     uiOutput("cohort_summary")
                  )
                ),

                # Dietary summary
                column(
                  width = 4,
                  div(
                     class = "dashboard-card",
                     h4("Dietary Summary (Cohort Mean +/- SD)"),
                     uiOutput("diet_summary")
                   )
                )
              ),
              fluidRow(
                class = "dashboard-row",

                # Mycobiome composition plot
                column(
                  width = 6,
                  div(
                     class = "dashboard-card",
                     h4("Mycobiome Composition"),
                     plotlyOutput("population_plot", height = "700px")
                   )
                ),

                # Diet comparison plot
                column(
                  width = 6,
                  div(
                     class = "dashboard-card",
                     h4("Diet Comparison"),
                     selectInput(
                       "diet_variable",
                       "Select Dietary Category",
                       choices = c(
                         "Calories (kcal)" = "Cals..kcal.",
                         "Protein (g)" = "Prot..g.",
                         "Carbohydrates (g)" = "Carb..g.",
                         "Sugar (g)" = "Sugar..g.",
                         "Added Sugar (g)" = "SugAdd..g.",
                         "Monosaccharides (g)" = "MonSac..g.",
                         "Glucose (g)" = "Gluc..g.",
                         "Fructose (g)" = "Fruct..g.",
                         "Disaccharides (g)" = "Disacc..g.",
                         "Lactose (g)" = "Lact..g.",
                         "Sucrose (g)" = "Sucr..g.",
                         "Saturated Fat (g)" = "SatFat..g.",
                         "Monounsaturated Fat (g)" = "MonoFat..g.",
                         "Polyunsaturated Fat (g)" = "PolyFat..g.",
                         "Trans Fat (g)" = "TransFat..g.",
                         "Cholesterol (g)" = "Chol..mg.",
                         "Fibre (g)" = "TotFib..g.",
                         "Omega-3 Fatty Acids (g)" = "Omega3..g.",
                         "Omega-6 Fatty Acids (g)" = "Omega6..g.",
                         "Phenylalanine (g)" = "Phe..g.",
                         "Tryptophan (g)" = "Trp..g.",
                         "Tyrosine (g)" = "Tyr..g.",
                         "Alcohol (g)" = "Alc..g.",
                         "Caffeine (mg)" = "Caff..mg.",
                         "MyPlate Grains (oz-eq)" = "MPGrain..oz.eq.",
                         "MyPlate Vegetables (oz-eq)" = "MPVeg..c.eq.",
                         "MyPlate Fruit (oz-eq)" = "MPFruit..c.eq.",
                         "MyPlate Dairy (oz-eq)" = "MPDairy..c.eq.",
                         "MyPlate Protein Foods (oz-eq)" = "MPProt..oz.eq."
                       ),
                       selected = "cals_kcal"
                     ),
                     plotlyOutput("diet_plot", height = "625px")
                   )
                )
              ),

              fluidRow(
                class = "dashboard-row",

                # Abundance heatmap
                column(
                  width = 8,
                  div(
                    class = "dashboard-card",
                    h4("Mycobiome-Diet Correlation"),
                    plotlyOutput("abundance_heatmap", height = "700px")
                  )
                ),

                # Scatter plot
                column(
                  width = 4,
                  div(
                    class = "dashboard-card",
                    h4("Domain Relationships"),
                    fluidRow(
                      column(6, selectInput("scatter_x", "X Axis", choices = scatter_x_choices, selected = "Fiber (g)")),
                      column(6, selectInput("scatter_y", "Y Axis", choices = scatter_y_choices, selected = "Shannon"))
                    ),
                    plotlyOutput("scatter_plot", height = "625px")
                  )
                ),
              ),

              fluidRow(

                column(
                   width = 12,
                   dashboard_footnote()
                 )
              )
           )
  )
}
