library(readxl)
library(dplyr)
library(ggplot2)
library(forcats)
library(scales)

# =========================
# User settings
# =========================

# Read one sheet from the xlsx file into df, then extract three columns.
input_xlsx <- "model_result_260413.xlsx"
sheet <- 'Sheet1'

fig_dir <- "04_pic"
fig_name <- "model_comparison_delta_looic_bar"

# Column names in your xlsx sheet.
model_col <- "model"
delta_looic_col <- "delta_looic"
family_col <- "family"

# Font sizes.
axis_title_x_size <- 18
axis_title_y_size <- 18
axis_text_x_size <- 15
legend_title_size <- 15
legend_text_size <- 13
bar_label_size <- 4.5
model_label_size <- 4.8

# Colors and label position.
winner_color <- "#D62828"
model_label_x_offset <- 0.04

# Figure size.
fig_width <- 8
fig_height <- 5.8

# Optional: manually define colors for your five model families.
# Keep the names exactly the same as the family names in your xlsx.
family_colors_manual <- c(
  # "Family 1" = "#E76F51",
  # "Family 2" = "#F4A261",
  # "Family 3" = "#2A9D8F",
  # "Family 4" = "#457B9D",
  # "Family 5" = "#8A5A9E"
)

default_family_palette <- c(
  "#E76F51",
  "#F4A261",
  "#2A9D8F",
  "#457B9D",
  "#8A5A9E",
  "#6C757D",
  "#B56576",
  "#7F5539"
)

# =========================
# Read and clean data
# =========================

if (!file.exists(input_xlsx)) {
  stop("Cannot find input xlsx file: ", input_xlsx)
}

df <- readxl::read_xlsx(input_xlsx, sheet = sheet)

required_cols <- c(model_col, delta_looic_col, family_col)
missing_cols <- setdiff(required_cols, names(df))

if (length(missing_cols) > 0) {
  stop(
    "These required columns were not found in df: ",
    paste(missing_cols, collapse = ", "),
    "\nAvailable columns are: ",
    paste(names(df), collapse = ", ")
  )
}

model_data <- df %>%
  select(
    model = all_of(model_col),
    delta_looic = all_of(delta_looic_col),
    family = all_of(family_col)
  ) %>%
  mutate(
    model = as.character(model),
    delta_looic = as.numeric(delta_looic),
    family = as.character(family)
  ) %>%
  filter(!is.na(model), !is.na(delta_looic), !is.na(family))

family_levels <- model_data %>%
  distinct(family) %>%
  pull(family)

auto_family_colors <- setNames(
  grDevices::colorRampPalette(default_family_palette)(length(family_levels)),
  family_levels
)

family_colors <- auto_family_colors
family_colors[names(family_colors_manual)] <- family_colors_manual

model_data <- model_data %>%
  mutate(
    family = factor(family, levels = family_levels),
    is_winner = delta_looic == min(delta_looic, na.rm = TRUE),
    fill_group = ifelse(is_winner, "Winning model", as.character(family)),
    model = fct_reorder(model, delta_looic, .desc = TRUE)
  )

plot_colors <- c(family_colors, "Winning model" = winner_color)

max_delta_looic <- max(model_data$delta_looic, na.rm = TRUE)
if (max_delta_looic == 0) max_delta_looic <- 1

model_label_data <- model_data %>%
  distinct(model, is_winner) %>%
  mutate(
    label_x = -model_label_x_offset * max_delta_looic,
    label_color = ifelse(is_winner, winner_color, "black"),
    label_fontface = ifelse(is_winner, "bold", "plain")
  )

# =========================
# Plot
# =========================

if (!dir.exists(fig_dir)) {
  dir.create(fig_dir, recursive = TRUE)
}

p_model_comparison <- ggplot(
  model_data,
  aes(x = model, y = delta_looic, fill = fill_group)
) +
  geom_col(width = 0.72, color = "black", linewidth = 0.35) +
  geom_text(
    aes(label = number(delta_looic, accuracy = 0.1)),
    hjust = -0.15,
    size = bar_label_size
  ) +
  geom_text(
    data = model_label_data,
    aes(
      x = model,
      y = label_x,
      label = as.character(model),
      color = label_color,
      fontface = label_fontface
    ),
    inherit.aes = FALSE,
    hjust = 1,
    size = model_label_size
  ) +
  coord_flip(clip = "off") +
  scale_fill_manual(values = plot_colors, drop = FALSE) +
  scale_color_identity() +
  scale_y_continuous(
    limits = c(-0.18 * max_delta_looic, NA),
    expand = expansion(mult = c(0, 0.16))
  ) +
  xlab("Model") +
  ylab(expression(Delta * "LOOIC")) +
  theme_classic() +
  theme(
    axis.title.x = element_text(size = axis_title_x_size, margin = margin(t = 10)),
    axis.title.y = element_text(size = axis_title_y_size, margin = margin(r = 10)),
    axis.text.x = element_text(size = axis_text_x_size, color = "black"),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    axis.line = element_line(color = "black", linewidth = 0.9),
    legend.title = element_text(size = legend_title_size),
    legend.text = element_text(size = legend_text_size),
    legend.position = "right",
    plot.margin = margin(t = 8, r = 28, b = 8, l = 80)
  ) +
  guides(fill = guide_legend(title = "Model family"))

print(p_model_comparison)

ggsave(
  filename = file.path(fig_dir, paste0(fig_name, ".svg")),
  plot = p_model_comparison,
  width = fig_width,
  height = fig_height,
  units = "in",
  dpi = 300
)

ggsave(
  filename = file.path(fig_dir, paste0(fig_name, ".png")),
  plot = p_model_comparison,
  width = fig_width,
  height = fig_height,
  units = "in",
  dpi = 300
)

write.csv(
  model_data,
  file = file.path(fig_dir, paste0(fig_name, "_processed_data.csv")),
  row.names = FALSE
)
