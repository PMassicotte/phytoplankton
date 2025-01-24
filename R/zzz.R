
# Color palette -----------------------------------------------------------

# paletteer::paletteer_d("ggthemes::gdoc")
#
# read_csv(here("data","clean","stations.csv")) %>%
#   distinct(area) %>%
#   pull(area)

area_breaks <-
  c(
    "Labrador",
    "Scotian Shelf",
    "NAB"
  )

area_pch <- c(2, 0, 3)

season_breaks <- c("Winter", "Spring", "Summer", "Autumn")
season_colors <- c("#041E42FF", "#00A9E0FF", "#BE3A34FF", "#FFA400FF")

str_wrap_factor <- function(x, ...) {
  levels(x) <- str_wrap(levels(x), ...)
  x
}

pdf2png <- function(pdf_file, dpi = 300) {

  png_file <- fs::path_ext_set(fs::path_file(pdf_file), "png")
  png_folder <- "graphs/png/"

  fs::dir_create(png_folder)

  outfile <- fs::path(png_folder, png_file)

  png_file <- pdftools::pdf_convert(
    pdf_file,
    format = "png",
    filenames = outfile,
    dpi = dpi,
    verbose = FALSE
  )

  return(png_file)
}
