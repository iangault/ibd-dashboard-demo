individual_server <- function(input, output, session) {
  intake_sections <- c(
    fats_lipids = "Fats",
    compounds = "Other Components",
    sugars = "Sugars",
    vitamins = "Vitamins"
  )
  intake_expanded <- reactiveValues(
    fats_lipids = FALSE,
    compounds = FALSE,
    sugars = FALSE,
    vitamins = FALSE
  )

  participant_match <- reactive({
    req(input$search_id)
    participants %>%
      filter(toupper(ID) == toupper(trimws(input$search_id)))
  })

  # Differentiator for participants with mycobiome data
  selected_has_mycobiome <- reactive({
    result <- participant_match()
    nrow(result) > 0 && isTRUE(result$Has_Mycobiome[1])
  })

  # Differentiator for participants with diet data
  selected_has_diet <- reactive({
    result <- participant_match()
    nrow(result) > 0 && isTRUE(result$Has_Diet[1])
  })

  observeEvent(input$search_id, {
    intake_expanded$fats_lipids <- FALSE
    intake_expanded$compounds <- FALSE
    intake_expanded$sugars <- FALSE
    intake_expanded$vitamins <- FALSE
  })

  observeEvent(input$show_more_fats_lipids, {
    intake_expanded$fats_lipids <- !isTRUE(intake_expanded$fats_lipids)
  })

  observeEvent(input$show_more_compounds, {
    intake_expanded$compounds <- !isTRUE(intake_expanded$compounds)
  })

  observeEvent(input$show_more_sugars, {
    intake_expanded$sugars <- !isTRUE(intake_expanded$sugars)
  })

  observeEvent(input$show_more_vitamins, {
    intake_expanded$vitamins <- !isTRUE(intake_expanded$vitamins)
  })

  output$participant_info <- renderUI({
    result <- participant_match()
    if (nrow(result) == 0) {
      return(tags$p("No participant found."))
    }

    tagList(
      fluidRow(
        column(
          width = 6,
          tags$p(tags$b("ID: "), result$ID[1]),
          tags$p(tags$b("Age (years): "), result$Age[1]),
          tags$p(tags$b("Sex: "), to_display_case(result$Sex[1])),
          tags$p(tags$b(HTML("BMI (kg/m<sup>2</sup>): ")), format_numeric(result$BMI[1], digits = 1)),
          tags$p(tags$b("Disease Group: "), to_display_case(result$Study_Group[1])),
          tags$p(tags$b("Ethnicity: "), to_display_case(result$Ethnicity[1])),
          tags$p(tags$b("Country of Origin: "), to_display_case(result$Country_of_Origin[1])),
          tags$p(tags$b("Years Living in Canada: "), result$Years_Living_in_Canada[1])
        ),
        column(
          width = 6,
          tags$p(tags$b("Exercise History: "), to_display_case(result$Exercise_History[1])),
          tags$p(tags$b("Comorbidities: "), format_missing(result$Comorbidities[1])),
          tags$p(tags$b("Family History of IBD: "), to_display_case(result$Family_History_of_IBD[1])),
          tags$p(tags$b("Smoking Status: "), to_display_case(result$Smoking_Status[1])),
          tags$p(tags$b("Alcohol Intake: "), to_display_case(result$Alcohol_Intake[1])),
          tags$p(tags$b("Prebiotics: "), format_prevalence(result$Prebiotics[1])),
          tags$p(tags$b("Probiotics: "), format_prevalence(result$Probiotics[1]))
        )
      )
    )
  })

  selected_taxa <- reactive({
    if (input$individual_taxa_level == "Phylum") {
      phylum
    } else if (input$individual_taxa_level == "Family") {
      family
    } else if (input$individual_taxa_level == "Genus") {
      genus
    } else {
      species
    }
  })

  output$microbiome_pie <- renderPlotly({
    req(input$search_id)
    validate(need(selected_has_mycobiome(), "Mycobiome data not yet available for this participant."))
    selected_id <- toupper(trimws(input$search_id))

    microbiome_data <- selected_taxa()
    taxon_cols <- setdiff(
      names(microbiome_data),
      c("Sample_ID", "Participant_ID", "Sample_type", "Study_group_new", "Fiber_restriction")
    )

    selected_rows <- microbiome_data %>%
      filter(toupper(Participant_ID) == selected_id)

    validate(need(nrow(selected_rows) > 0, "No microbiome data found for this participant."))
    validate(need(length(taxon_cols) > 0, "No taxonomic columns found."))

    pie_df <- selected_rows %>%
      summarise(across(all_of(taxon_cols), ~ mean(.x, na.rm = TRUE))) %>%
      pivot_longer(
        cols = everything(),
        names_to = "Taxon",
        values_to = "Abundance"
      ) %>%
      filter(!is.na(Abundance), Abundance > 0) %>%
      arrange(desc(Abundance)) %>%
      mutate(Taxon = ifelse(Taxon == "NA", "Unclassified", Taxon))
    
    if (!input$indiv_display_all_taxa){
      pie_df <- pie_df |>
        slice_head(n = input$indiv_top_n)
    }

    validate(need(nrow(pie_df) > 0, "No microbiome composition available."))

    # if (nrow(pie_df) > 5) {
    #   pie_df <- bind_rows(
    #     pie_df[1:5, ],
    #     data.frame(
    #       Taxon = "Other",
    #       Abundance = sum(pie_df$Abundance[-(1:5)])
    #     )
    #   )
    # }

    build_microbiome_pie(pie_df)
  })

  output$disease_activity_card <- renderUI({
    result <- participant_match()
    if (nrow(result) == 0) {
      return(tags$p("No participant found."))
    }

    tagList(
      tags$p(tags$b("Harvey Bradshaw Index: "), format_missing(result$Harvey_Bradshaw_Index[1])),
      tags$p(tags$b("C-reactive protein: "), format_missing(result$CRP[1])),
      tags$p(tags$b("Fecal Calprotectin: "), format_missing(result$Fecal_Calprotectin[1])),
      tags$p(tags$b("General Well-Being: "), format_missing(result$General_Well_Being[1])),
      tags$p(tags$b("Stool Frequency: "), format_missing(result$Daily_Soft_Stools[1])),
      tags$p(tags$b("Abdominal Pain: "), format_missing(result$Abdominal_Pain[1])),
      tags$p(tags$b("Weight Change: "), format_weight_change(result$Weight_Change[1])),
      tags$p(tags$b("Advanced Therapy/Medication Use: "), format_missing(result$Advanced_Therapy_Changes[1]))
    )
  })

  output$symptom_burden_card <- renderUI({
    result <- participant_match()
    if (nrow(result) == 0) {
      return(tags$p("No participant found."))
    }

    if (!has_qol_data_access(result$Study_Group[1])) {
      return(tags$p("No QOL data for Non-IBD participants."))
    }

    qol_values <- c(
      result$Fatigue_Frequency[1],
      result$Anxiety_Frequency[1],
      result$Sleep_Difficulty_Frequency[1],
      result$Abdominal_Bloating_Frequency[1],
      result$Rectal_Bleeding_Frequency[1],
      result$Feeling_Unwell_Frequency[1]
    )
    qol_score <- calculate_qol_burden(qol_values)
    qol_total <- qol_burden_total(length(qol_values))
    qol_score_text <- if (is.na(qol_score)) {
      "NA"
    } else {
      paste0(format_numeric(qol_score, digits = 0), " / ", qol_total)
    }
    participant_position <- qol_position_pct(qol_score, qol_total)
    symptom_labels <- c(
      "Fatigue",
      "Anxiety",
      "Sleep difficulty",
      "Abdominal bloating",
      "Rectal bleeding",
      "Feeling unwell"
    )
    symptom_burden <- pmax(0, 7 - vapply(qol_values, extract_scale_score, numeric(1)))
    symptom_pct <- round((symptom_burden / 6) * 100, 0)
    symptom_pct[is.na(symptom_pct)] <- 0
    symptom_fill <- vapply(
      symptom_pct,
      function(pct) {
        if (pct <= 0) {
          return("transparent")
        }
        if (pct <= 20) {
          return("#79b51d")
        }
        if (pct <= 55) {
          return("#f7c45b")
        }
        return("#f16457")
      },
      character(1)
    )

    tagList(
      if (!is.na(qol_score)) {
        tags$div(
          class = "qol-card",
          tags$div(
            tags$div(
              class = "qol-summary-score",
              tags$span(class = "qol-summary-value", format_numeric(qol_score, digits = 0)),
              tags$span(class = "qol-summary-total", paste0("/ ", qol_total))
            ),
            tags$div(
              class = "qol-summary-meta",
              "Lower is better"
            ),
            tags$div(
              class = "qol-summary-scale-wrap",
              tags$div(class = "qol-summary-scale"),
              if (!is.na(participant_position)) {
                tags$div(
                  class = "qol-summary-marker",
                  style = sprintf("left: %.1f%%;", participant_position)
                )
              }
            ),
            tags$div(
              class = "qol-summary-axis",
              tags$span("0 best"),
              tags$span(paste0(qol_total, " worst"))
            ),
            tags$div(
              class = "qol-caption",
              "Green indicates higher QOL. Red indicates lower QOL."
            )
          ),
          tags$div(
            class = "qol-bars",
            lapply(seq_along(symptom_labels), function(i) {
              tags$div(
                class = "qol-bar-row",
                tags$div(class = "qol-bar-label", symptom_labels[[i]]),
                tags$div(
                  class = "qol-bar-track",
                  tags$div(
                    class = "qol-bar-fill",
                    style = sprintf("width: %s%%; background: %s;", symptom_pct[[i]], symptom_fill[[i]])
                  )
                ),
                tags$div(class = "qol-bar-pct", paste0(symptom_pct[[i]], "%"))
              )
            })
          )
        )
      } else {
        tags$p(tags$b("QOL Score: "), qol_score_text)
      }
    )
  })

  output$food_avoidance_card <- renderUI({
    result <- participant_match()
    if (nrow(result) == 0) {
      return(tags$p("No participant found."))
    }

    food_categories <- data.frame(
      Category = c(
        "Fruit",
        "Vegetables",
        "Whole grains",
        "Nuts / seeds",
        "Lactose",
        "Gluten",
        "Spicy foods",
        "High-fat foods"
      ),
      Active = c(
        format_avoidance_detail(result$Fruit_Avoidance_Active[1], result$Excluded_Fruits_Active[1]),
        format_avoidance_detail(result$Vegetable_Avoidance_Active[1], result$Excluded_Vegetables_Active[1]),
        format_avoidance_detail(result$Whole_Grain_Avoidance_Active[1], result$Excluded_Whole_Grains_Active[1]),
        format_avoidance_detail(result$Nut_Seed_Avoidance_Active[1], result$Excluded_Nuts_Seeds_Active[1]),
        format_avoidance_detail(result$Lactose_Avoidance_Active[1], result$Excluded_Lactose_Active[1]),
        format_avoidance_detail(result$Gluten_Avoidance_Active[1], result$Excluded_Gluten_Active[1]),
        format_avoidance_detail(result$Spicy_Food_Avoidance_Active[1], result$Excluded_Spicy_Foods_Active[1]),
        format_avoidance_detail(result$Fat_Food_Avoidance_Active[1], result$Excluded_Fat_Foods_Active[1])
      ),
      Remission = c(
        format_avoidance_detail(result$Fruit_Avoidance_Remission[1], result$Excluded_Fruits_Remission[1]),
        format_avoidance_detail(result$Vegetable_Avoidance_Remission[1], result$Excluded_Vegetables_Remission[1]),
        format_avoidance_detail(result$Whole_Grain_Avoidance_Remission[1], result$Excluded_Whole_Grains_Remission[1]),
        format_avoidance_detail(result$Nut_Seed_Avoidance_Remission[1], result$Excluded_Nuts_Seeds_Remission[1]),
        format_avoidance_detail(result$Lactose_Avoidance_Remission[1], result$Excluded_Lactose_Remission[1]),
        format_avoidance_detail(result$Gluten_Avoidance_Remission[1], result$Excluded_Gluten_Remission[1]),
        format_avoidance_detail(result$Spicy_Food_Avoidance_Remission[1], result$Excluded_Spicy_Foods_Remission[1]),
        format_avoidance_detail(result$Fat_Food_Avoidance_Remission[1], result$Excluded_Fat_Foods_Remission[1])
      ),
      stringsAsFactors = FALSE
    )

    rows <- lapply(seq_len(nrow(food_categories)), function(i) {
      tags$tr(
        tags$td(food_categories$Category[i], style = "padding:6px 10px; vertical-align:top;"),
        tags$td(food_categories$Active[i], style = "padding:6px 10px; vertical-align:top;"),
        tags$td(food_categories$Remission[i], style = "padding:6px 10px; vertical-align:top;")
      )
    })

    tags$table(
      style = "width:100%; font-size:13px; border-collapse:collapse;",
      tags$thead(
        tags$tr(
          tags$th("Category", style = "padding:6px 10px; text-align:left; border-bottom:1px solid #ddd;"),
          tags$th("Active Disease", style = "padding:6px 10px; text-align:left; border-bottom:1px solid #ddd;"),
          tags$th("Remission", style = "padding:6px 10px; text-align:left; border-bottom:1px solid #ddd;")
        )
      ),
      tags$tbody(rows)
    )
  })

  output$nutrient_vitamin_card <- renderUI({
    req(input$search_id)
    if (!selected_has_diet()) {
      return(tags$p("Not available yet.", style = "color:#888; font-style:italic;"))
    }

    selected_id <- toupper(trimws(input$search_id))
    selected_rows <- diet_lookup %>%
      filter(toupper(participant_id) == selected_id)

    validate(need(nrow(selected_rows) > 0, "No participant found."))

    available_dietary_columns <- unname(additional_dietary_columns[additional_dietary_columns %in% names(diet_lookup)])
    dietary_labels <- names(additional_dietary_columns[additional_dietary_columns %in% names(participant_data)])
    available_vitamin_columns <- unname(key_vitamin_columns[key_vitamin_columns %in% names(diet_lookup)])
    vitamin_labels <- names(key_vitamin_columns[key_vitamin_columns %in% names(participant_data)])

    validate(need(length(available_dietary_columns) > 0 || length(available_vitamin_columns) > 0, "No nutrient intake columns found."))

    dietary_summary <- selected_rows %>%
      mutate(across(all_of(available_dietary_columns), ~ suppressWarnings(as.numeric(.x)))) %>%
      summarise(across(all_of(available_dietary_columns), ~ mean(.x, na.rm = TRUE)))
    vitamin_summary <- selected_rows %>%
      mutate(across(all_of(available_vitamin_columns), ~ suppressWarnings(as.numeric(.x)))) %>%
      summarise(across(all_of(available_vitamin_columns), ~ mean(.x, na.rm = TRUE)))

    dietary_lookup <- stats::setNames(as.list(available_dietary_columns), dietary_labels)
    vitamin_lookup <- stats::setNames(as.list(available_vitamin_columns), vitamin_labels)

    build_intake_panel <- function(section_id, title, labels, lookup, summary_df) {
      section_labels <- labels[labels %in% names(lookup)]
      if (length(section_labels) == 0) {
        return(NULL)
      }

      expanded <- isTRUE(intake_expanded[[section_id]])
      visible_labels <- if (expanded) section_labels else utils::head(section_labels, 5)

      rows <- lapply(visible_labels, function(label) {
        column_name <- lookup[[label]]
        tags$tr(
          tags$td(label, class = "intake-label"),
          tags$td(format_numeric(summary_df[[column_name]][1]), class = "intake-value")
        )
      })

      toggle_needed <- length(section_labels) > 5

      tags$div(
        class = "intake-panel",
        tags$div(
          class = "intake-panel-header",
          tags$div(
            title,
            class = "intake-panel-title"
          ),
          tags$div(
            paste0(length(section_labels), " measures"),
            class = "intake-panel-subtitle"
          )
        ),
        tags$table(
          class = "intake-table",
          tags$tbody(rows)
        ),
        if (toggle_needed) {
          actionButton(
            inputId = paste0("show_more_", section_id),
            label = if (expanded) "Show less" else paste0("Show ", length(section_labels) - 5, " more"),
            class = "intake-toggle"
          )
        }
      )
    }

    section_definitions <- list(
      list(
        id = "fats_lipids",
        title = intake_sections[["fats_lipids"]],
        labels = additional_dietary_groups[["Fats and Lipids"]],
        lookup = dietary_lookup,
        summary = dietary_summary
      ),
      list(
        id = "compounds",
        title = intake_sections[["compounds"]],
        labels = additional_dietary_groups[["Amino Acids and Other Compounds"]],
        lookup = dietary_lookup,
        summary = dietary_summary
      ),
      list(
        id = "sugars",
        title = intake_sections[["sugars"]],
        labels = additional_dietary_groups[["Sugars"]],
        lookup = dietary_lookup,
        summary = dietary_summary
      ),
      list(
        id = "vitamins",
        title = intake_sections[["vitamins"]],
        labels = names(vitamin_lookup),
        lookup = vitamin_lookup,
        summary = vitamin_summary
      )
    )

    section_panels <- lapply(section_definitions, function(section) {
      build_intake_panel(
        section_id = section$id,
        title = section$title,
        labels = section$labels,
        lookup = section$lookup,
        summary_df = section$summary
      )
    })

    tagList(
      tags$p(
        "Participant average intake by nutrient category. Click 'Show more' to view all items.",
        class = "intake-overview-note"
      ),
      tags$div(
        class = "intake-grid",
        section_panels
      )
    )
  })

  output$cfg_card <- renderUI({
    req(input$search_id)
    if (!selected_has_diet()) {
      return(tags$p("Not available yet.", style = "color:#888; font-style:italic;"))
    }

    selected_id <- toupper(trimws(input$search_id))
    selected_rows <- diet_lookup %>%
      filter(toupper(participant_id) == selected_id)

    validate(need(nrow(selected_rows) > 0, "No participant found."))

    participant_summary <- selected_rows %>%
      mutate(across(all_of(c(score_columns, "TotalSugar..g.")), ~ as.numeric(.x))) %>%
      summarise(across(all_of(c(score_columns, "TotalSugar..g.")), ~ mean(.x, na.rm = TRUE)))

    cohort_summary <- diet_lookup %>%
      mutate(across(all_of(c(score_columns, "TotalSugar..g.")), ~ as.numeric(.x))) %>%
      summarise(across(all_of(c(score_columns, "TotalSugar..g.")), ~ mean(.x, na.rm = TRUE)))

    fibre_target <- get_fibre_target(selected_rows$gender[1])
    participant_targets <- c(
      cfg_targets,
      "TotFib..g." = fibre_target
    )

    intake_values <- unlist(participant_summary[1, score_columns], use.names = FALSE)
    names(intake_values) <- score_columns
    cohort_average_values <- unlist(cohort_summary[1, score_columns], use.names = FALSE)
    names(cohort_average_values) <- score_columns
    pct_reached <- round((intake_values / participant_targets[score_columns]) * 100, 0)
    pct_reached[!is.finite(pct_reached)] <- NA
    met_target <- intake_values >= participant_targets[score_columns]
    summary_score <- sum(met_target, na.rm = TRUE)
    summary_total <- length(score_columns)
    summary_class <- if (summary_score == summary_total) {
      "cfg-score-pill cfg-score-pill-ok"
    } else if (summary_score >= ceiling(summary_total / 2)) {
      "cfg-score-pill cfg-score-pill-mid"
    } else {
      "cfg-score-pill"
    }

    display_names <- c(
      "MPGrain..oz.eq." = "Grains (oz eq/day)",
      "MPVeg..c.eq." = "Vegetables (cups/day)",
      "MPFruit..c.eq." = "Fruit (cups/day)",
      "MPDairy..c.eq." = "Dairy (cups/day)",
      "MPProt..oz.eq." = "Protein (oz eq/day)",
      "TotFib..g." = "Fibre (g/day)",
      "TotalSugar..g." = "Total Sugar (g/day)"
    )

    rows <- lapply(score_columns, function(col) {
      current_met <- unname(met_target[col])
      status_text <- if (isTRUE(current_met)) "On target" else "Below target"
      status_color <- if (isTRUE(current_met)) "#2E8B57" else "#C0392B"

      tags$tr(
        tags$td(display_names[col], style = "padding:6px 10px;"),
        tags$td(format_numeric(intake_values[col]), style = "padding:6px 10px; text-align:right;"),
        tags$td(format_numeric(cohort_average_values[col]), style = "padding:6px 10px; text-align:right;"),
        tags$td(
          format_numeric(participant_targets[col]),
          style = "padding:6px 10px; text-align:right;"
        ),
        tags$td(
          ifelse(is.na(pct_reached[col]), "NA", paste0(pct_reached[col], "%")),
          style = "padding:6px 10px; text-align:right;"
        ),
        tags$td(
          status_text,
          style = paste0("padding:6px 10px; font-weight:bold; color:", status_color, ";")
        )
      )
    })

    rows <- append(
      rows,
      list(
        tags$tr(
          tags$td(display_names["TotalSugar..g."], style = "padding:6px 10px;"),
          tags$td(format_numeric(participant_summary$TotalSugar..g.[1]), style = "padding:6px 10px; text-align:right;"),
          tags$td(format_numeric(cohort_summary$TotalSugar..g.[1]), style = "padding:6px 10px; text-align:right;"),
          tags$td("NA", style = "padding:6px 10px; text-align:right;"),
          tags$td("NA", style = "padding:6px 10px; text-align:right;"),
          tags$td("No target", style = "padding:6px 10px; font-weight:bold; color:#5f6c7b;")
        )
      )
    )

    tagList(
      tags$div(
        class = summary_class,
        tags$span(class = "cfg-score-pill-icon", HTML("&#9888;")),
        tags$span(paste0(summary_score, " / ", summary_total, " targets met"))
      ),
      tags$table(
        style = "width:100%; font-size:13px; border-collapse:collapse;",
        tags$thead(
          tags$tr(
            tags$th("Food Group", style = "padding:6px 10px; text-align:left; border-bottom:1px solid #ddd;"),
            tags$th("Participant", style = "padding:6px 10px; text-align:right; border-bottom:1px solid #ddd;"),
            tags$th("Average", style = "padding:6px 10px; text-align:right; border-bottom:1px solid #ddd;"),
            tags$th("Target", style = "padding:6px 10px; text-align:right; border-bottom:1px solid #ddd;"),
            tags$th("% Target", style = "padding:6px 10px; text-align:right; border-bottom:1px solid #ddd;"),
            tags$th("Status", style = "padding:6px 10px; text-align:left; border-bottom:1px solid #ddd;")
          )
        ),
        tags$tbody(rows)
      )
    )
  })
}
