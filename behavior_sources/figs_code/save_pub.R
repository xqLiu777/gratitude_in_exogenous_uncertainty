# ============================================================
# save_pub.R
# ------------------------------------------------------------
# Purpose:
#   Provide one consistent save function for ggplot figures.
#   Source this file after plot_theme.R:
#
#     source("plot_theme.R")
#     source("save_pub.R")
#
#   Then save figures with:
#
#     save_pub(p, "02_fig/figure1.svg")
#     save_pub(p, "02_fig/figure1.tiff", dpi = 600)
#
#   The function keeps width, height, units, dpi, background, and device
#   behavior centralized so you do not need to repeat ggsave() settings.
# ============================================================

library(ggplot2)


# ============================================================
# 1. Default save parameters
# ============================================================

# Default figure width.
# Uses width_in_inches from plot_theme.R if that file has been sourced.
save_width <- if (exists("width_in_inches")) width_in_inches else 25

# Default figure height.
# Uses height_in_inches from plot_theme.R if that file has been sourced.
save_height <- if (exists("height_in_inches")) height_in_inches else 25

# Default width/height unit.
# Your original script uses inches.
save_units <- "in"

# Default raster resolution.
# Uses default_dpi from plot_theme.R if that file has been sourced.
save_dpi <- if (exists("default_dpi")) default_dpi else 600

# Default background.
# "white" is safest for manuscript figures and PowerPoint insertion.
save_bg <- "white"

# Whether to create parent folders automatically.
save_create_dir <- TRUE


# ============================================================
# 2. Device selector
# ============================================================

# Pick a graphics device from the file extension.
# This keeps save_pub() simple:
#   save_pub(p, "figure.svg")
#   save_pub(p, "figure.pdf")
#   save_pub(p, "figure.png")
#   save_pub(p, "figure.tiff")
#
# If svglite or ragg is not installed, ggsave() will use its default device.
choose_pub_device <- function(filename) {
  ext <- tolower(tools::file_ext(filename))

  if (ext == "svg" && requireNamespace("svglite", quietly = TRUE)) {
    return(svglite::svglite)
  }

  if (ext %in% c("png") && requireNamespace("ragg", quietly = TRUE)) {
    return(ragg::agg_png)
  }

  if (ext %in% c("tif", "tiff") && requireNamespace("ragg", quietly = TRUE)) {
    return(ragg::agg_tiff)
  }

  # Returning NULL lets ggsave() infer the device from the extension.
  NULL
}


# ============================================================
# 3. Main save function
# ============================================================

save_pub <- function(
    plot,
    filename,
    width = save_width,
    height = save_height,
    units = save_units,
    dpi = save_dpi,
    bg = save_bg,
    create_dir = save_create_dir,
    limitsize = FALSE,
    device = choose_pub_device(filename)
) {
  # Create the output directory when it does not already exist.
  # This prevents ggsave() from failing when a folder such as "02_fig"
  # has not been created yet.
  output_dir <- dirname(filename)
  if (
    isTRUE(create_dir) &&
      !is.na(output_dir) &&
      output_dir != "." &&
      !dir.exists(output_dir)
  ) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  # Save the figure with centralized parameters.
  ggsave(
    filename = filename,
    plot = plot,
    width = width,
    height = height,
    units = units,
    dpi = dpi,
    bg = bg,
    limitsize = limitsize,
    device = device
  )

  invisible(filename)
}


# ============================================================
# 4. Multi-format helper
# ============================================================

# Save the same plot to several formats with one command.
# Example:
#
#   save_pub_multi(
#     p,
#     filename_base = "02_fig/01_exp1_grati_cost_stats_bar_260604",
#     formats = c("svg", "pdf", "tiff")
#   )
save_pub_multi <- function(
    plot,
    filename_base,
    formats = c("svg", "pdf", "tiff"),
    width = save_width,
    height = save_height,
    units = save_units,
    dpi = save_dpi,
    bg = save_bg,
    create_dir = save_create_dir,
    limitsize = FALSE
) {
  output_files <- paste0(filename_base, ".", formats)

  for (filename in output_files) {
    save_pub(
      plot = plot,
      filename = filename,
      width = width,
      height = height,
      units = units,
      dpi = dpi,
      bg = bg,
      create_dir = create_dir,
      limitsize = limitsize
    )
  }

  invisible(output_files)
}

