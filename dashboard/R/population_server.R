population_server <- function(input, output, session) {

  # Select taxa data based on user input
  selected_taxa <- reactive({
    if (input$taxa_level == "Phylum") {
      phylum
    } else if (input$taxa_level == "Family") {
      family
    } else if (input$taxa_level == "Genus") {
      genus
    } else {
      species
    }
  })
  
  # Filter selected data by study group
  taxa_filtered <- reactive({
    
    if (input$group_filter != "All"){
      selected_taxa() |>
        filter(Study_group_new == input$group_filter)
    } else {
      selected_taxa()
    }

  })

  # Filter by study group
  merged_filtered <- reactive({
    
    if (input$group_filter != "All"){
      merged |>
        filter(Study_group_new == input$group_filter)
    } else {
      merged
    }

  })

  participants_filtered <- reactive({
    
    if (input$group_filter != "All"){
      participants |>
        filter(Study_Group == input$group_filter)
    } else {
      participants
    }

  })

  # Identify top taxa for specific group
  group_taxa_ranked <- reactive({

    if (input$group_filter != "All"){
      group_taxa <- selected_taxa() |>
        filter(Study_group_new == input$group_filter)
    } else {
      group_taxa <- selected_taxa()
    }

    group_taxa |>
      select(-c(Sample_ID, Participant_ID, Sample_type, Study_group_new, Fiber_restriction)) |>
      summarise(
        across(
          everything(),
          function(x) mean(x, na.rm = TRUE)
        )
      ) |>
      pivot_longer(
        everything(),
        names_to = "Taxon",
        values_to = "MeanAbundance"
      ) |>
      arrange(
        desc(MeanAbundance)
      )
  })

  # Identify top taxa for all groups
  taxa_ranked <- reactive({
    selected_taxa() |>
      select(-c(Sample_ID, Participant_ID, Sample_type, Study_group_new, Fiber_restriction)) |>
      summarise(
        across(
          everything(),
          function(x) mean(x, na.rm = TRUE)
        )
      ) |>
      pivot_longer(
        everything(),
        names_to = "Taxon",
        values_to = "MeanAbundance"
      ) |>
      arrange(
        desc(MeanAbundance)
      )
  })
  
  # Data summary
  output$cohort_summary <- renderUI({
    
    taxa_data <- taxa_filtered()
    merged_data <- merged_filtered()
    participant_data <- participants_filtered()

    sex_summary <- merged_data |>
      summarise(
        FemalePct = round(
        mean(gender == "female", na.rm = TRUE) * 100,
        1
      ),
      MalePct = round(
        mean(gender == "male", na.rm = TRUE) * 100,
        1
      )
    )

    qol_cols <- c(
      "Fatigue_Frequency",
      "Anxiety_Frequency",
      "Sleep_Difficulty_Frequency",
      "Abdominal_Bloating_Frequency",
      "Rectal_Bleeding_Frequency",
      "Feeling_Unwell_Frequency"
    )

    cohort_qol <- participant_data |>
      rowwise() |>
      mutate(
        QOL_Burden = calculate_qol_burden(
          c_across(all_of(qol_cols))
        )
      ) |>
      ungroup() |>
      summarise(
        MeanQOL = mean(QOL_Burden, na.rm = TRUE)
      )
    
    tagList(
      tags$p(tags$b("Taxonomic Level: "), input$taxa_level),
      tags$p(tags$b("Group: "), input$group_filter),
      tags$p(tags$b("Number of Participants: "), n_distinct(merged_data$Participant_ID)),
      tags$p(tags$b("Number of Samples: "), nrow(taxa_data)),
      tags$p(tags$b("Age (years): "), round(mean(merged_data$age), 1)),
      tags$p(tags$b("Pct. Female: "), sex_summary$FemalePct),
      tags$p(tags$b("Pct. Male: "), sex_summary$MalePct),
      tags$p(tags$b(HTML("BMI (kg/m<sup>2</sup>): ")), round(mean(merged_data$bmi_1), 1)),
      tags$p(tags$b("C-reactive protein: "), round(mean(participant_data$CRP, na.rm = TRUE), 1)),
      tags$p(tags$b("Fecal Calprotectin: "), round(mean(participant_data$Fecal_Calprotectin, na.rm = TRUE), 1)),
      tags$p(tags$b("QOL Score (out of 36, lower is better): "), round(cohort_qol$MeanQOL, 1))
    )
  })
  
  # Dietary Summary
  output$diet_summary <- renderUI({
    
    data <- merged_filtered()
    
    mean_cals <- round(mean(data$Cals..kcal., na.rm = TRUE), 1)
    sd_cals <- round(sd(data$Cals..kcal., na.rm = TRUE), 1)

    mean_protein <- round(mean(data$Prot..g., na.rm = TRUE), 1)
    sd_protein <- round(sd(data$Prot..g., na.rm = TRUE), 1)

    mean_carbs <- round(mean(data$Carb..g., na.rm = TRUE), 1)
    sd_carbs <- round(sd(data$Carb..g., na.rm = TRUE), 1)

    mean_sugar <- round(mean(data$Sugar..g., na.rm = TRUE), 1)
    sd_sugar <- round(sd(data$Sugar..g., na.rm = TRUE), 1)

    mean_satfat <- round(mean(data$SatFat..g., na.rm = TRUE), 1)
    sd_satfat <- round(sd(data$SatFat..g., na.rm = TRUE), 1)

    mean_monofat <- round(mean(data$MonoFat..g., na.rm = TRUE), 1)
    sd_monofat <- round(sd(data$MonoFat..g., na.rm = TRUE), 1)

    mean_polyfat <- round(mean(data$PolyFat..g., na.rm = TRUE), 1)
    sd_polyfat <- round(sd(data$PolyFat..g., na.rm = TRUE), 1)

    mean_transfat <- round(mean(data$TransFat..g., na.rm = TRUE), 1)
    sd_transfat <- round(sd(data$TransFat..g., na.rm = TRUE), 1)

    mean_fiber <- round(mean(data$TotFib..g., na.rm = TRUE), 1)
    sd_fiber <- round(sd(data$TotFib..g., na.rm = TRUE), 1)
    
    tagList(
      tags$p(tags$b("Calories (kcal): "), mean_cals, "+/-", sd_cals),
      tags$p(tags$b("Protein (g): "), mean_protein, "+/-", sd_protein),
      tags$p(tags$b("Carbohydrates (g): "), mean_carbs, "+/-", sd_carbs),
      tags$p(tags$b("Sugar (g): "), mean_sugar, "+/-", sd_sugar),
      tags$p(tags$b("Saturated Fat (g): "), mean_satfat, "+/-", sd_satfat),
      tags$p(tags$b("Monounsaturated Fat (g): "), mean_monofat, "+/-", sd_monofat),
      tags$p(tags$b("Polyunsaturated Fat (g): "), mean_polyfat, "+/-", sd_polyfat),
      tags$p(tags$b("Trans Fat (g): "), mean_transfat, "+/-", sd_transfat),
      tags$p(tags$b("Fibre (g): "), mean_fiber, "+/-", sd_fiber)
    )
  })

  # Create abundance heatmap
  output$abundance_heatmap <- renderPlotly({

    taxa_data <- group_taxa_ranked()
    if (!input$display_all_taxa){
      taxa_data <- taxa_data |>
        slice_head(n = input$top_n)
    }
      
    top_taxa <- taxa_data |>
      pull(Taxon)

    taxa_trimmed <- selected_taxa() |>
      select(
        Sample_ID,
        Participant_ID,
        Study_group_new,
        all_of(top_taxa)
      )
    
    diet_variables = c(
      "Cals..kcal.",
      "Prot..g.",
      "Carb..g.",
      "Sugar..g.",
      "SugAdd..g.",
      "MonSac..g.",
      "Gluc..g.",
      "Fruct..g.",
      "Disacc..g.",
      "Lact..g.",
      "Sucr..g.",
      "SatFat..g.",
      "MonoFat..g.",
      "PolyFat..g.",
      "TransFat..g.",
      "Chol..mg.",
      "TotFib..g.",
      "Omega3..g.",
      "Omega6..g.",
      "Phe..g.",
      "Trp..g.",
      "Tyr..g.",
      "Alc..g.",
      "Caff..mg.",
      "MPGrain..oz.eq.",
      "MPVeg..c.eq.",
      "MPFruit..c.eq.",
      "MPDairy..c.eq.",
      "MPProt..oz.eq."
    )

    diet_trimmed <- merged |>
      select(
        Sample_ID,
        Participant_ID,
        Study_group_new,
        all_of(diet_variables)
      )

    if (input$group_filter != "All"){
      taxa_trimmed <- taxa_trimmed |>
        filter(Study_group_new == input$group_filter)
      diet_trimmed <- diet_trimmed |>
        filter(Study_group_new == input$group_filter)
      title_tag <- input$group_filter
    } else {
      title_tag <- "All Study Groups"
    }

    analysis_df <- taxa_trimmed |>
      inner_join(
        diet_trimmed,
        by = c(
          "Sample_ID",
          "Participant_ID"
        )
      )
    
    # Drop columns with no variation (e.g. alcohol is 0 for everyone);
    # cor() can't correlate them and warns on every pair
    has_variation <- function(col) {
      n_distinct(analysis_df[[col]], na.rm = TRUE) > 1
    }
    heatmap_diet_vars <- Filter(has_variation, diet_variables)
    heatmap_taxa <- Filter(has_variation, top_taxa)

    correlation_results <- data.frame()
    for (diet_var in heatmap_diet_vars) {

      for (taxon in heatmap_taxa) {

        corr_value <- cor(
          analysis_df[[diet_var]],
          analysis_df[[taxon]],
          use = "complete.obs",
          method = "spearman"
        )

        correlation_results <- rbind(
          correlation_results,

          data.frame(
            DietVariable = diet_var,
            Taxon = taxon,
            Correlation = corr_value
          )
        )
      }
    }

    correlation_results$DietVariable <-
      recode(
        correlation_results$DietVariable,

        Cals..kcal. = "Calories (kcal)",
        Prot..g. = "Protein (g)",
        Carb..g. = "Carbohydrates (g)",
        Sugar..g. = "Sugar (g)",
        SugAdd..g. = "Added Sugar (g)",
        MonSac..g. = "Monosaccharides (g)",
        Gluc..g. = "Glucose (g)",
        Fruct..g. = "Fructose (g)",
        Disacc..g. = "Disaccharides (g)",
        Lact..g. = "Lactose (g)",
        Sucr..g. = "Sucrose (g)",
        SatFat..g. = "Saturated Fat (g)",
        MonoFat..g. = "Monounsaturated Fat (g)",
        PolyFat..g. = "Polyunsaturated Fat (g)",
        TransFat..g. = "Trans Fat (g)",
        Chol..mg. = "Cholesterol (g)",
        TotFib..g. = "Fibre (g)",
        Omega3..g. = "Omega-3 Fatty Acids (g)",
        Omega6..g. = "Omega-6 Fatty Acids (g)",
        Phe..g. = "Phenylalanine (g)",
        Trp..g. = "Tryptophan (g)",
        Tyr..g. = "Tyrosine (g)",
        Alc..g. = "Alcohol (g)",
        Caff..mg. = "Caffeine (mg)",
        MPGrain..oz.eq. = "MyPlate Grains (oz-eq)",
        MPVeg..c.eq. = "MyPlate Vegetables (oz-eq)",
        MPFruit..c.eq. = "MyPlate Fruit (oz-eq)",
        MPDairy..c.eq. = "MyPlate Dairy (oz-eq)",
        MPProt..oz.eq. = "MyPlate Protein Foods (oz-eq)"
      )

    correlation_results <- correlation_results |>
      mutate(
        Tooltip = paste0(
          "Diet: ", DietVariable,
          "<br>Taxon: ", Taxon,
          "<br>Correlation: ",
          round(Correlation, 3)
        )
      )

    p <- ggplot(
      correlation_results,
      aes(
        x = Taxon,
        y = DietVariable,
        fill = Correlation,
        text = Tooltip
      )) +

      geom_tile() +

      scale_fill_gradient2(
        low = "blue",
        mid = "white",
        high = "red",
        midpoint = 0,
        limits = c(-1, 1),
        name = "Spearman\nCorrelation"
      ) +

      labs(
        title = paste0(title_tag),
        x = "Taxon",
        y = "Dietary Variable"
      ) +

      theme_minimal(base_size = 13) +

      theme(
        legend.title = element_text(
          size = 14
        ),

        legend.text = element_text(
          size = 12
        ),

        axis.title = element_text(
          size = 14
        ),

        axis.text = element_text(
          size = 12
        ),

        axis.text.x = element_text(
            angle = 45,
            hjust = 1
        ),

        panel.grid =
          element_blank()
    )

    ggplotly(
      p,
      tooltip = "text"
    )
  })

  # Create group diet comp plot
  output$diet_plot <- renderPlotly({
    
    # Calculate means and standard deviations
    summary_data <- participant_data |>
      group_by(Study_group_new) |>
      summarise(
        MeanValue = mean(
          .data[[input$diet_variable]],
          na.rm = TRUE
        ),
        SDValue = sd(
          .data[[input$diet_variable]],
          na.rm = TRUE
        )
      ) |>
      mutate(
        Tooltip = paste0(
          "Group: ", Study_group_new,
          "<br>Mean: ", round(MeanValue, 2),
          "<br>SD: ", round(SDValue, 2)
        ),
        Study_group_new = factor(
          Study_group_new,
          levels = c(
            "Active IBD",
            "Quiescent",
            "Non-IBD"
          )
        )
      )
    
    # Plot
    p <- ggplot(
      summary_data,
      aes(
        x = Study_group_new,
        y = MeanValue,
        fill = Study_group_new,
        text = Tooltip
      )
    ) +
      geom_col(
        width = 0.7
      ) +
      labs(
        x = "Study Group",
        y = "Mean Intake"
      ) +
      geom_errorbar(
        aes(
          ymin = MeanValue - SDValue,
          ymax = MeanValue + SDValue
        ),
        width = 0.2
      ) +
      theme_minimal() +
      theme(
        legend.position = "none",

        axis.title = element_text(
          size = 14
        ),

        axis.text = element_text(
          size = 12
        ),

        axis.text.x = element_text(angle = 20, hjust = 1)
      )

    ggplotly(
      p,
      tooltip = "text"
    )
  })
  
  # Create abundance plot
  output$population_plot <- renderPlotly({
    
    taxa_data <- taxa_ranked()
    if (!input$display_all_taxa){
      taxa_data <- taxa_data |>
        slice_head(n = input$top_n)
    }
      
    top_taxa <- taxa_data |>
      pull(Taxon)

    selected_taxa_df <- selected_taxa() |>

      select(
        Study_group_new,
        all_of(top_taxa)
      ) |>

      group_by(Study_group_new) |>

      summarise(
        across(
          everything(),
          function(x) mean(x, na.rm = TRUE)
        )
      ) |>

      pivot_longer(
        cols = -Study_group_new,
        names_to = "Taxon",
        values_to = "MeanAbundance"
      ) |>

      mutate(
        Tooltip = paste0(
          "Group: ", Study_group_new,
          "<br>Taxon: ", Taxon,
          "<br>Abundance: ", round(MeanAbundance, 2), "%"
        ),
        Study_group_new = factor(
          Study_group_new,
          levels = c(
            "Active IBD",
            "Quiescent",
            "Non-IBD"
          )
        )
      )

    p <- ggplot(
      selected_taxa_df,
      aes(
        x = Study_group_new,
        y = MeanAbundance,
        fill = Taxon,
        text = Tooltip
      )
    ) +

    geom_col() +

    labs(
      x = "Study Group",
      y = "Mean Relative Abundance"
    ) +

    theme_minimal(base_size = 13) +

    theme(
      legend.title = element_text(
        size = 14
      ),

      legend.text = element_text(
        size = 12
      ),

      axis.title = element_text(
        size = 14
      ),

      axis.text = element_text(
        size = 12
      ),

      axis.text.x = element_text(angle = 20, hjust = 1)
    )

    ggplotly(
      p,
      tooltip = "text"
    )
  })

  output$scatter_plot <- renderPlotly({
    x_col <- input$scatter_x
    y_col <- input$scatter_y

    # Per-participant columns — must use participant_df to avoid duplicate observations
    participant_cols <- c("CRP", "Fecal Calprotectin", "HBI", "QoL Score")
    df <- if (x_col %in% participant_cols | y_col %in% participant_cols) participant_df else sample_df

    plot_data <- df |>
      filter(!is.na(.data[[x_col]]), !is.na(.data[[y_col]]))

    validate(need(nrow(plot_data) >= 3, "Not enough data to plot."))

    rho <- cor(plot_data[[x_col]], plot_data[[y_col]],
               method = "spearman", use = "complete.obs")
    subtitle <- paste0("Spearman ρ = ", round(rho, 3),
                       ", n = ", nrow(plot_data))

    group_pal <- c(
      "Active IBD"  = "#E15759",
      "Quiescent"   = "#F28E2B",
      "Non-IBD"     = "#4E79A7"
    )

    p <- plot_data |>
      ggplot(aes(
        x      = .data[[x_col]],
        y      = .data[[y_col]],
        colour = Disease_status,
        text   = paste0(
          "ID: ", participant_id, "<br>",
          x_col, ": ", round(.data[[x_col]], 2), "<br>",
          y_col, ": ", round(.data[[y_col]], 4)
        )
      )) +
      geom_point(size = 2.5) +
      scale_colour_manual(values = group_pal, name = "Disease status") +
      labs(x = x_col, y = y_col) +
      theme_minimal()

    ggplotly(p, tooltip = "text", height = 500) |>
      layout(
        margin = list(t = 80, b = 80),
        title  = list(text = paste0(
          x_col, " × ", y_col,
          "<br><sup>", subtitle, "</sup>"
        ))
      )
  })
}
