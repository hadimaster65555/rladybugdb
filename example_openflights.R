# example_openflights.R — Real-world graph analysis and visualization
#
# Dataset: OpenFlights (https://openflights.org/data)
#   - ~7,700 airports worldwide with coordinates
#   - ~67,000 airline routes (directed edges)
#
# What this does:
#   1. Downloads airports.dat and routes.dat
#   2. Loads them into an in-memory LadybugDB graph
#   3. Runs several Cypher queries
#   4. Produces 4 visualizations (saved as PNG files)
#
# Requirements: ggplot2, dplyr  (core)
#               ggraph, igraph  (network plot)
#               maps            (world map overlay)
#
# Run:
#   Rscript example_openflights.R

library(rladybugdb)
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
})

cat("rladybugdb", as.character(packageVersion("rladybugdb")), "— OpenFlights example\n")
cat("LadybugDB C library:", ladybugdb_version(), "\n\n")

# ── 0. Setup ──────────────────────────────────────────────────────────────────
out_dir <- "example_openflights_plots"
dir.create(out_dir, showWarnings = FALSE)

# ── 1. Download OpenFlights data ──────────────────────────────────────────────
cat("1. Downloading OpenFlights data...\n")

base_url <- "https://raw.githubusercontent.com/jpatokal/openflights/master/data"

airports_file <- file.path(tempdir(), "airports.dat")
routes_file   <- file.path(tempdir(), "routes.dat")

download.file(paste0(base_url, "/airports.dat"), airports_file, quiet = TRUE)
download.file(paste0(base_url, "/routes.dat"),   routes_file,   quiet = TRUE)

# ── 2. Parse into data frames ──────────────────────────────────────────────────
cat("2. Parsing raw data...\n")

airports_raw <- read.csv(airports_file, header = FALSE, quote = '"',
                         stringsAsFactors = FALSE, na.strings = c("", "\\N"),
                         col.names = c("id","name","city","country","iata","icao",
                                       "lat","lng","alt","tz","dst","tz_name","type","source"))

routes_raw <- read.csv(routes_file, header = FALSE, quote = '"',
                       stringsAsFactors = FALSE, na.strings = c("", "\\N"),
                       col.names = c("airline","airline_id","src_iata","src_id",
                                     "dst_iata","dst_id","codeshare","stops","equipment"))

# Keep only real airports with valid coordinates and IATA codes
airports <- airports_raw |>
  filter(type == "airport", nchar(iata) == 3,
         !is.na(lat), !is.na(lng), !is.na(id)) |>
  transmute(
    id      = as.integer(id),
    name    = name,
    city    = city,
    country = country,
    iata    = iata,
    lat     = as.double(lat),
    lng     = as.double(lng),
    alt     = as.integer(ifelse(is.na(alt), 0L, as.integer(alt)))
  )

# Keep routes where both src_id and dst_id are valid integers referencing known airports
known_ids <- airports$id
routes <- routes_raw |>
  filter(!is.na(src_id), !is.na(dst_id),
         suppressWarnings(!is.na(as.integer(src_id))),
         suppressWarnings(!is.na(as.integer(dst_id)))) |>
  transmute(
    src_id   = as.integer(src_id),
    dst_id   = as.integer(dst_id),
    airline  = ifelse(is.na(airline), "Unknown", airline),
    stops    = as.integer(ifelse(is.na(stops), 0L, stops))
  ) |>
  filter(src_id %in% known_ids, dst_id %in% known_ids, src_id != dst_id)

cat(sprintf("   %d airports | %d routes\n\n", nrow(airports), nrow(routes)))

# ── 3. Load into LadybugDB ─────────────────────────────────────────────────────
cat("3. Loading into LadybugDB...\n")

db   <- lb_database(":memory:")
conn <- lb_connection(db)

lb_execute(conn, "
  CREATE NODE TABLE Airport (
    id      INT64,
    name    STRING,
    city    STRING,
    country STRING,
    iata    STRING,
    lat     DOUBLE,
    lng     DOUBLE,
    alt     INT64,
    PRIMARY KEY(id)
  )")

lb_execute(conn, "
  CREATE REL TABLE Route (
    FROM Airport TO Airport,
    airline STRING,
    stops   INT64
  )")

cat("   Inserting airport nodes...\n")
lb_copy_from_df(conn, airports, "Airport")

cat("   Inserting route edges...\n")
lb_copy_from_df(conn, routes, "Route")

cat("   Done.\n\n")

# ── 4. Query: overview statistics ────────────────────────────────────────────
cat("4. Graph statistics\n")

stats <- lb_query(conn, "
  MATCH (a:Airport)
  RETURN count(a) AS total_airports")
cat(sprintf("   Total airports : %d\n", stats$total_airports))

rstats <- lb_query(conn, "
  MATCH ()-[r:Route]->()
  RETURN count(r) AS total_routes")
cat(sprintf("   Total routes   : %d\n\n", rstats$total_routes))

# ── 5. Query: top airports by outbound route count ───────────────────────────
cat("5. Querying top hubs by outbound routes...\n")

top_hubs <- lb_query(conn, "
  MATCH (a:Airport)-[r:Route]->()
  WITH a.iata AS iata, a.name AS name, a.country AS country,
       a.lat AS lat, a.lng AS lng, count(r) AS routes
  WHERE routes > 10
  RETURN iata, name, country, lat, lng, routes
  ORDER BY routes DESC
  LIMIT 30")

cat(sprintf("   Top hub: %s (%s) — %d outbound routes\n\n",
            top_hubs$name[1], top_hubs$iata[1], top_hubs$routes[1]))

# ── 6. Query: countries with most airports ───────────────────────────────────
cat("6. Querying airports per country...\n")

by_country <- lb_query(conn, "
  MATCH (a:Airport)
  WITH a.country AS country, count(a) AS n_airports
  RETURN country, n_airports
  ORDER BY n_airports DESC
  LIMIT 20")

# ── 7. Query: route network for a major hub (Frankfurt) ──────────────────────
cat("7. Extracting Frankfurt hub subgraph...\n")

hub_iata <- "FRA"
hub_net <- lb_query(conn, paste0("
  MATCH (src:Airport {iata: '", hub_iata, "'})-[r:Route]->(dst:Airport)
  RETURN src.iata AS src, dst.iata AS dst,
         dst.name AS dst_name, dst.country AS dst_country,
         dst.lat AS dst_lat, dst.lng AS dst_lng,
         r.airline AS airline
  LIMIT 80"))

cat(sprintf("   %d direct destinations from %s\n\n", nrow(hub_net), hub_iata))

# ── 8. Query: geographic route sample (for map) ──────────────────────────────
cat("8. Sampling routes for world map...\n")

route_map <- lb_query(conn, "
  MATCH (src:Airport)-[r:Route]->(dst:Airport)
  WHERE src.lng IS NOT NULL AND dst.lng IS NOT NULL
  RETURN src.lat AS src_lat, src.lng AS src_lng,
         dst.lat AS dst_lat, dst.lng AS dst_lng,
         src.country AS country
  LIMIT 3000")

cat(sprintf("   %d route segments for map\n\n", nrow(route_map)))

# ── 9. Visualizations ─────────────────────────────────────────────────────────
cat("9. Creating visualizations...\n")

# --- Plot 1: Top 30 airports by outbound routes (bar chart) ------------------
p1 <- top_hubs |>
  mutate(label = paste0(iata, "\n", sub(" International.*", "", name))) |>
  ggplot(aes(x = reorder(label, routes), y = routes, fill = routes)) +
  geom_col(width = 0.7) +
  scale_fill_gradient(low = "#4da6ff", high = "#003380", guide = "none") +
  coord_flip() +
  labs(
    title    = "Top 30 Airport Hubs — Outbound Routes",
    subtitle = "Source: OpenFlights  |  LadybugDB graph query",
    x        = NULL,
    y        = "Number of outbound routes"
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"))

ggsave(file.path(out_dir, "01_top_hubs.png"), p1,
       width = 9, height = 7, dpi = 150)
cat("   Saved: 01_top_hubs.png\n")

# --- Plot 2: Top 20 countries by airport count (lollipop) --------------------
p2 <- by_country |>
  mutate(country = factor(country, levels = rev(country))) |>
  ggplot(aes(x = country, y = n_airports)) +
  geom_segment(aes(xend = country, y = 0, yend = n_airports),
               colour = "#4da6ff", linewidth = 0.8) +
  geom_point(colour = "#003380", size = 3.5) +
  geom_text(aes(label = n_airports), hjust = -0.4, size = 3.2) +
  coord_flip(ylim = c(0, max(by_country$n_airports) * 1.12)) +
  labs(
    title    = "Top 20 Countries by Airport Count",
    subtitle = "Source: OpenFlights  |  LadybugDB graph query",
    x        = NULL,
    y        = "Number of airports"
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"))

ggsave(file.path(out_dir, "02_airports_by_country.png"), p2,
       width = 8, height = 6, dpi = 150)
cat("   Saved: 02_airports_by_country.png\n")

# --- Plot 3: World map of sampled routes -------------------------------------
world_map <- tryCatch(map_data("world"), error = function(e) NULL)

if (!is.null(world_map)) {
  p3 <- ggplot() +
    geom_map(data = world_map, map = world_map,
             aes(map_id = region),
             fill = "#1a1a2e", colour = "#2a2a4e", linewidth = 0.15) +
    expand_limits(x = range(world_map$long), y = range(world_map$lat)) +
    geom_segment(
      data    = route_map,
      aes(x = src_lng, y = src_lat, xend = dst_lng, yend = dst_lat),
      alpha   = 0.06, colour = "#4da6ff", linewidth = 0.25
    ) +
    geom_point(
      data  = top_hubs,
      aes(x = lng, y = lat, size = routes),
      colour = "#ffd700", alpha = 0.85
    ) +
    scale_size_continuous(range = c(1.5, 6), name = "Outbound\nroutes") +
    coord_fixed(1.3, xlim = c(-180, 180), ylim = c(-60, 85)) +
    labs(
      title    = "Global Airline Route Network",
      subtitle = paste0("3,000 sampled routes  |  top hubs in gold  |  LadybugDB query on ",
                        nrow(airports), " airports & ", nrow(routes), " routes"),
      x = NULL, y = NULL
    ) +
    theme_void(base_size = 11) +
    theme(
      plot.background  = element_rect(fill = "#0d0d1a", colour = NA),
      plot.title       = element_text(colour = "white", face = "bold", size = 14),
      plot.subtitle    = element_text(colour = "#aaaacc", size = 9),
      legend.text      = element_text(colour = "white"),
      legend.title     = element_text(colour = "white"),
      plot.margin      = margin(10, 10, 10, 10)
    )

  ggsave(file.path(out_dir, "03_world_map.png"), p3,
         width = 14, height = 7, dpi = 150)
  cat("   Saved: 03_world_map.png\n")
} else {
  cat("   [SKIP] 03_world_map.png (maps package not available)\n")
}

# --- Plot 4: Network graph of Frankfurt hub ----------------------------------
has_ggraph <- requireNamespace("ggraph", quietly = TRUE) &&
              requireNamespace("igraph", quietly = TRUE)

if (has_ggraph) {
  library(igraph)
  library(ggraph)

  # Build igraph from hub_net rows
  vertices <- data.frame(
    name    = unique(c(hub_iata, hub_net$dst)),
    country = c(
      "Germany",
      hub_net$dst_country[match(unique(hub_net$dst), hub_net$dst)]
    ),
    stringsAsFactors = FALSE
  )

  edges_ig <- hub_net |>
    count(src, dst, name = "weight")

  g <- graph_from_data_frame(edges_ig, directed = TRUE, vertices = vertices)

  # Colour nodes by continent proxy (simple country list)
  europe <- c("Germany","France","United Kingdom","Spain","Italy","Netherlands",
               "Switzerland","Austria","Belgium","Poland","Sweden","Norway",
               "Denmark","Finland","Portugal","Greece","Czech Republic","Romania",
               "Hungary","Ireland","Croatia","Slovakia","Bulgaria","Serbia")

  V(g)$region <- ifelse(V(g)$name == hub_iata, "Hub",
                  ifelse(V(g)$country %in% europe, "Europe", "Intercontinental"))

  region_colours <- c(Hub = "#ffd700", Europe = "#4da6ff", Intercontinental = "#ff6b6b")

  set.seed(42)
  p4 <- ggraph(g, layout = "stress") +
    geom_edge_arc(aes(width = weight), alpha = 0.3, colour = "#4da6ff",
                  strength = 0.2, arrow = arrow(length = unit(2, "mm"), type = "closed"),
                  end_cap = circle(3, "mm")) +
    geom_node_point(aes(colour = region,
                        size   = ifelse(name == hub_iata, 6, 3))) +
    geom_node_text(aes(label = name,
                       colour = region,
                       size   = ifelse(name == hub_iata, 3.5, 2.2)),
                   repel = TRUE, max.overlaps = 20) +
    scale_colour_manual(values = region_colours, name = "Region") +
    scale_size_identity() +
    scale_edge_width(range = c(0.3, 1.5), guide = "none") +
    labs(
      title    = paste0("Direct Route Network: Frankfurt (", hub_iata, ")"),
      subtitle = paste0(nrow(hub_net), " destinations  |  LadybugDB Cypher query"),
      caption  = "Node colour: gold = hub, blue = Europe, red = intercontinental"
    ) +
    theme_graph(base_size = 11) +
    theme(
      plot.title    = element_text(face = "bold"),
      legend.position = "bottom"
    )

  ggsave(file.path(out_dir, "04_fra_network.png"), p4,
         width = 12, height = 10, dpi = 150)
  cat("   Saved: 04_fra_network.png\n")
} else {
  cat("   [SKIP] 04_fra_network.png (install ggraph + igraph for network plot)\n")
}

# ── 10. Cleanup ───────────────────────────────────────────────────────────────
lb_close(conn)
lb_close(db)

cat(sprintf("\nPlots written to: %s/\n", out_dir))
cat("Done.\n")
