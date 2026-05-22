# ============================================================================
#  Render the self-paced reading figure for the MInDReading page.
#
#  Shows the full 2x2 design: Nynorsk / Bokmål  ×  number-agreement /
#  definite-plural.
#    - number-agreement = CONTROL: the two standards are grammatically
#      aligned here, so processing should be congruent across them.
#    - definite-plural  = CRITICAL: the standards diverge (-ane / -ene),
#      so processing is variety-specific (contrastive).
#
#  Writes a single transparent PNG into the personal webpage's images/
#  folder. Run inside the analysis project where `reading_data_clean`
#  exists. Requires: dplyr/ggplot2 (tidyverse), ggtext, ggh4x, and Hmisc
#  (for ggplot2::mean_cl_boot).
#
#  NOTE: the output filename is kept as reading_definite_plural.png so the
#  current page reference still resolves; rename later if desired.
# ============================================================================
library(dplyr); library(ggplot2); library(ggtext); library(ggh4x)

# --- USER KNOBS -------------------------------------------------------------
OUT_PNG  <- "/Users/jadesandstedt/Library/CloudStorage/Dropbox/R_projects/Personal_webpage_development/Personal webpage/images/reading_definite_plural.png"
PNG_W    <- 10.0   # inches — 2x2 facet grid
PNG_H    <- 7.5    # inches
PNG_DPI  <- 200

# --- Prepare the data -------------------------------------------------------
plot_data <- reading_data_clean %>%
  mutate(
    Critical_word = as.character(Critical_word),
    Facet = factor(
      paste(Language, Condition, sep = ": "),
      levels = c(
        "Nynorsk: num.agreement", "Nynorsk: definite.pl",
        "Bokmål: num.agreement", "Bokmål: definite.pl"
      )
    ),
    Subcondition = factor(
      Subcondition,
      levels = c("agreement", "non-agreement", "ANE", "ENE")
    )
  ) %>%
  group_by(Subject, Language) %>%
  mutate(sd = sd(Read_time, na.rm = TRUE)) %>%
  ungroup() %>%
  filter(
    Position >= -5, Position <= 3,
    !is.na(Subcondition)
  )

# Common breaks across facets (expects -5:3 present)
global_breaks <- sort(unique(plot_data$Position))

facet_labeller <- as_labeller(c(
  "Nynorsk: num.agreement"  = "**Nynorsk** (number agreement)",
  "Nynorsk: definite.pl"    = "**Nynorsk** (definite plural)",
  "Bokmål: num.agreement"   = "**Bokmål** (number agreement)",
  "Bokmål: definite.pl"     = "**Bokmål** (definite plural)"
))

# Custom x-labels (ggtext)
custom_labels <- list(
  "Nynorsk: num.agreement" = c(
    "...denne", "retninga", "fordi", "vegane", "er",
    "smal*(<span style=\"color:#4F94CD\">e</span>)",
    "med", "bratte", "og..."
  ),
  "Bokmål: num.agreement" = c(
    "...denne", "retningen", "fordi", "veiene", "er",
    "smal*(<span style=\"color:#4F94CD\">e</span>)",
    "med", "bratte", "og..."
  ),
  "Nynorsk: definite.pl" = c(
    "...kan", "sjå", "førestillinga", "godt,", "fordi",
    "stol(<span style=\"color:#458BBA\">a</span>/*<span style=\"color:#BA7445\">e</span>)ne",
    "er", "plasserte", "med...."
  ),
  "Bokmål: definite.pl" = c(
    "...kan", "se", "forestillingen", "godt,", "fordi",
    "stol(<span style=\"color:#BA7445\">e</span>/*<span style=\"color:#458BBA\">a</span>)ne",
    "er", "plassert", "med..."
  )
)

facet_names <- levels(plot_data$Facet)
scale_x_list <- setNames(lapply(facet_names, function(facet_name) {
  labs <- custom_labels[[facet_name]]
  stopifnot(length(labs) == length(global_breaks))
  scale_x_continuous(
    breaks = global_breaks,
    labels = function(x) labs[match(x, global_breaks)]
  )
}), facet_names)

# --- aesthetics -------------------------------------------------------------
subcondition_colors <- c(
  "agreement"     = "steelblue4",
  "non-agreement" = "red4",
  "ANE"           = "#458BBA",
  "ENE"           = "#BA7445"
)
subcondition_labels <- c(
  "agreement"     = "Agreement (+agr)",
  "non-agreement" = "Non-agreement (Ø)",
  "ANE"           = "-ANE (Nynorsk std)",
  "ENE"           = "-ENE (Bokmål std)"
)
# Open vs filled points
subcondition_shapes <- c(
  "agreement"     = 1,   # open circle
  "non-agreement" = 16,  # filled circle
  "ANE"           = 1,
  "ENE"           = 16
)
# Line width redundancy
subcondition_linewidths <- c(
  "agreement"     = 0.90,
  "non-agreement" = 1.05,
  "ANE"           = 0.90,
  "ENE"           = 1.05
)
legend_breaks <- names(subcondition_colors)

# Shading to highlight integration costs
group_shaded_data <- plot_data %>%
  filter(Position >= 0 & Position <= 3) %>%
  group_by(Facet, Position) %>%
  summarise(
    ymin_def = mean(Read_time[Subcondition == "ANE"], na.rm = TRUE),
    ymax_def = mean(Read_time[Subcondition == "ENE"], na.rm = TRUE),
    ymin_num = mean(Read_time[Subcondition == "agreement"], na.rm = TRUE),
    ymax_num = mean(Read_time[Subcondition == "non-agreement"], na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    ymin = ifelse(grepl("definite", Facet), ymin_def, ymin_num),
    ymax = ifelse(grepl("definite", Facet), ymax_def, ymax_num),
    shading_color = case_when(
      Facet == "Nynorsk: definite.pl" ~ "#BA7445",
      Facet == "Bokmål: definite.pl"  ~ "#458BBA",
      grepl("num.agreement", Facet)   ~ "red4",
      TRUE ~ "gray50"
    )
  )

# --- Plot -------------------------------------------------------------------
group_level_plot <- ggplot(
  plot_data,
  aes(
    x = Position,
    y = Read_time,
    color = Subcondition,
    shape = Subcondition,
    linewidth = Subcondition,
    group = Subcondition
  )
) +
  geom_ribbon(
    data = group_shaded_data,
    aes(x = Position, ymin = ymin, ymax = ymax, fill = shading_color),
    inherit.aes = FALSE,
    alpha = 0.15
  ) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(
    fun.data = ggplot2::mean_cl_boot,
    geom = "errorbar",
    width = 0.2,
    linewidth = 0.7,
    alpha = 0.7
  ) +
  stat_summary(fun = mean, geom = "line") +
  scale_color_manual(
    values = subcondition_colors,
    breaks = legend_breaks,
    labels = subcondition_labels
  ) +
  scale_shape_manual(
    values = subcondition_shapes,
    breaks = legend_breaks,
    labels = subcondition_labels
  ) +
  scale_linewidth_manual(
    values = subcondition_linewidths,
    breaks = legend_breaks,
    labels = subcondition_labels,
    guide = "none"
  ) +
  scale_fill_identity() +
  facet_wrap(~Facet, scales = "free_x", ncol = 2, labeller = facet_labeller) +
  ggh4x::facetted_pos_scales(x = scale_x_list) +
  labs(
    x = "Sentence Position",
    y = "Read time (ms)",
    color = "Morphological variant"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x        = ggtext::element_markdown(size = 9, angle = 45, hjust = 1),
    axis.text.x.bottom = ggtext::element_markdown(size = 9, angle = 45, hjust = 1),
    strip.text.x = ggtext::element_markdown(size = 11, face = "plain"),
    strip.text.y = ggtext::element_markdown(size = 11, face = "plain"),
    legend.position = "bottom",
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 10),
    panel.grid.minor = element_blank(),
    plot.background    = element_rect(fill = "transparent", colour = NA),
    panel.background   = element_rect(fill = "transparent", colour = NA),
    legend.background  = element_rect(fill = "transparent", colour = NA)
  ) +
  # Force a single legend
  guides(
    color = guide_legend(
      nrow = 2,
      override.aes = list(
        shape     = unname(subcondition_shapes[legend_breaks]),
        linewidth = unname(subcondition_linewidths[legend_breaks])
      )
    ),
    shape = "none"
  )

# --- Save (transparent) -----------------------------------------------------
dir.create(dirname(OUT_PNG), recursive = TRUE, showWarnings = FALSE)
ggsave(OUT_PNG, group_level_plot,
       width = PNG_W, height = PNG_H, units = "in", dpi = PNG_DPI,
       bg = "transparent")
message("Wrote ", OUT_PNG)
