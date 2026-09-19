# ============================================================
# plot_theme.R
# ------------------------------------------------------------
# Purpose:
#   Centralize all visual parameters used by ggplot figures.
#   Source this file once at the beginning of an R Markdown file:
#
#     source("plot_theme.R")
#     setup_plot_theme()
#
#   Then every plot can reuse the same fonts, margins, line widths,
#   colors, and geometry settings.
# ============================================================

library(ggplot2)
library(grid)


# ============================================================
# 1. Unit conversion parameters
# ============================================================

# Convert point size to millimeters when needed.
pt_to_mm <- 0.57

# Convert millimeters to point size when needed.
mm_to_pt <- 2.8346

pt_to_mm_y <- 0.9

# ============================================================
# 2. Default export size
# ============================================================

# These values follow your current R Markdown setting:
#   fig.width  = width_in_inches
#   fig.height = height_in_inches
#
# Keep these large values if you want very high-resolution source figures.
# For manuscript output, common alternatives are:
#   single-column figure: width_in_inches = 3.35
#   double-column figure: width_in_inches = 7.20
width_in_inches <- 35
height_in_inches <- 35

# Default resolution for raster output such as PNG or TIFF.
# Use 150-300 for fast preview, 600 for final submission-quality export.
default_dpi <- 600


# ============================================================
# 4. Font and text parameters
# ============================================================

  
# Whether to show legends by default.
legend_position <- "none"


# ============================================================
# 5. Axis parameters
# ============================================================

# Axis line thickness.
axis_linewidth <- 1.2

# Tick mark thickness.
tick_linewidth <- 1.2

# Tick mark length, in millimeters.
tick_length <- 6


# ============================================================
# 13. Theme function
# ============================================================

# Build the reusable ggplot theme.
# You can override any major text parameter when calling the function:
#
#   theme_pub(title_size = 80, text_size = 70)
#
theme_pub <- function(
    base_family = base_font,
    axis_title_y_size = title_y_size,
    axis_title_x_size = title_x_size,
    axis_text_y_size = text_y_size,
    axis_text_x_size = text_x_size,
    axis_title_x_margin = title_x_margin,
    axis_title_y_margin = title_y_margin,
    axis_text_x_margin = text_x_margin,
    axis_text_y_margin = text_y_margin,
    axis_line_width = axis_linewidth,
    tick_line_width = tick_linewidth,
    tick_length_mm = tick_length,
    legend_pos = legend_position
) {
  theme_classic(base_family = base_family) +
    theme(
      legend.position = legend_pos,

      axis.title.y = element_text(
        margin = margin(r = axis_title_y_margin),
        size = axis_title_y_size
      ),
      axis.title.x = element_text(
        margin = margin(t = axis_title_x_margin),
        size = axis_title_x_size
      ),

      axis.text.y = element_text(
        margin = margin(r = axis_text_y_margin),
        size = axis_text_y_size
      ),
      axis.text.x = element_text(
        margin = margin(t = axis_text_x_margin),
        size = axis_text_x_size
      ),

      axis.line = element_line(
        color = "black",
        linewidth = axis_line_width
      ),
      axis.ticks = element_line(
        color = "black",
        linewidth = tick_line_width
      ),
      axis.ticks.length = unit(tick_length_mm, "mm")
    )
}

# 
# # ============================================================
# # 14. Helper functions for repeated scales
# # ============================================================
# 
# # Reuse this in plots instead of writing scale_fill_manual() every time.
# scale_fill_outcome <- function(values = fill_palette) {
#   scale_fill_manual(values = values)
# }
# 
# # Reuse this in plots instead of writing scale_color_manual() every time.
# scale_color_outcome <- function(values = color_palette) {
#   scale_color_manual(values = values)
# }
# 
# # Reuse this in plots instead of writing scale_x_discrete() every time.
# scale_x_outcome <- function(labels = outcome_labels) {
#   scale_x_discrete(labels = labels)
# }


# ============================================================
# 15. One-line setup function
# ============================================================

# Apply theme_pub() as the default ggplot theme.
# Call this once in the setup chunk of your R Markdown file.
setup_plot_theme <- function() {
  theme_set(theme_pub())
}

