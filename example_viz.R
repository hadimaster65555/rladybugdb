# rladybugdb — graph visualization example
# Demonstrates: igraph (base), ggraph (ggplot2), visNetwork (interactive HTML)
#
# Prerequisites:
#   pip install real_ladybug pandas
#   install.packages(c("igraph", "ggraph", "tidygraph", "ggplot2", "visNetwork"))

library(reticulate)
use_python(Sys.which("python3"), required = TRUE)
devtools::load_all(".", quiet = TRUE)

library(igraph)
library(ggraph)
library(tidygraph)
library(ggplot2)
library(visNetwork)

# ── 1. Build the database ──────────────────────────────────────────────────
db   <- lb_database(":memory:")
conn <- lb_connection(db)

# Schema: people, topics, and two relationship types
invisible(lb_execute(conn, "CREATE NODE TABLE Person (
  name       STRING,
  role       STRING,
  PRIMARY KEY (name)
)"))

invisible(lb_execute(conn, "CREATE NODE TABLE Topic (
  name  STRING,
  field STRING,
  PRIMARY KEY (name)
)"))

invisible(lb_execute(conn, "CREATE REL TABLE Knows (
  FROM Person TO Person,
  since  INT64,
  weight DOUBLE
)"))

invisible(lb_execute(conn, "CREATE REL TABLE Interested (
  FROM Person TO Topic,
  level STRING
)"))

# ── 2. Insert nodes ────────────────────────────────────────────────────────
people <- data.frame(
  name = c("Alice","Bob","Carol","Dave","Eve","Frank","Grace"),
  role = c("Engineer","Researcher","Designer","Engineer","Researcher","Manager","Designer"),
  stringsAsFactors = FALSE
)
invisible(lb_copy_from_df(conn, people, "Person"))

topics <- data.frame(
  name  = c("Machine Learning","Graph Databases","UI/UX","Systems","Statistics"),
  field = c("AI","Data","Design","Engineering","Math"),
  stringsAsFactors = FALSE
)
invisible(lb_copy_from_df(conn, topics, "Topic"))

# ── 3. Insert relationships ────────────────────────────────────────────────
knows <- list(
  list("Alice",  "Bob",   2020, 0.9),
  list("Alice",  "Carol", 2019, 0.7),
  list("Alice",  "Dave",  2021, 0.5),
  list("Bob",    "Eve",   2018, 0.8),
  list("Bob",    "Frank", 2022, 0.6),
  list("Carol",  "Grace", 2020, 0.9),
  list("Dave",   "Frank", 2019, 0.7),
  list("Eve",    "Grace", 2021, 0.4),
  list("Frank",  "Grace", 2020, 0.6)
)
for (k in knows) {
  invisible(lb_execute(conn,
    sprintf("MATCH (a:Person {name:'%s'}),(b:Person {name:'%s'})
             CREATE (a)-[:Knows {since:%d, weight:%s}]->(b)", k[[1]], k[[2]], k[[3]], k[[4]])
  ))
}

interested <- list(
  list("Alice",  "Machine Learning",  "expert"),
  list("Alice",  "Graph Databases",   "beginner"),
  list("Bob",    "Machine Learning",  "expert"),
  list("Bob",    "Statistics",        "intermediate"),
  list("Carol",  "UI/UX",             "expert"),
  list("Carol",  "Graph Databases",   "intermediate"),
  list("Dave",   "Systems",           "expert"),
  list("Dave",   "Graph Databases",   "beginner"),
  list("Eve",    "Statistics",        "expert"),
  list("Eve",    "Machine Learning",  "intermediate"),
  list("Frank",  "Systems",           "intermediate"),
  list("Grace",  "UI/UX",             "expert"),
  list("Grace",  "Statistics",        "beginner")
)
for (i in interested) {
  invisible(lb_execute(conn,
    sprintf("MATCH (p:Person {name:'%s'}),(t:Topic {name:'%s'})
             CREATE (p)-[:Interested {level:'%s'}]->(t)", i[[1]], i[[2]], i[[3]])
  ))
}

# ── 4. Query and convert to igraph ─────────────────────────────────────────
# ─ 4a. Person–Person network
result_pp <- lb_execute(conn,
  "MATCH (a:Person)-[r:Knows]->(b:Person) RETURN a, r, b"
)
g_social <- as_igraph(result_pp)

# Annotate vertices with role (already in _LABEL/properties via as_igraph)
# Also query person attributes separately to enrich the graph
roles_df <- lb_query(conn, "MATCH (p:Person) RETURN p.name AS name, p.role AS role")
role_map  <- setNames(roles_df$role, roles_df$name)
V(g_social)$role <- role_map[V(g_social)$name]

# Edge weight from the 'weight' edge attribute
weights_df <- lb_query(conn,
  "MATCH (a:Person)-[r:Knows]->(b:Person) RETURN a.name AS from, b.name AS to, r.weight AS weight, r.since AS since")

# ── 5. Visualization A: igraph base plot ───────────────────────────────────
role_colors <- c(
  Engineer   = "#4E79A7",
  Researcher = "#F28E2B",
  Designer   = "#59A14F",
  Manager    = "#E15759"
)

png("viz_igraph.png", width = 900, height = 700, res = 120)
set.seed(42)
plot(
  g_social,
  layout          = layout_with_fr(g_social),
  vertex.color    = role_colors[V(g_social)$role],
  vertex.size     = 30,
  vertex.label    = V(g_social)$name,
  vertex.label.color = "white",
  vertex.label.cex   = 0.8,
  vertex.frame.color = "white",
  edge.arrow.size    = 0.4,
  edge.color         = "#999999",
  edge.width         = 1.5,
  main = "Social Network (igraph)"
)
legend("bottomleft",
  legend = names(role_colors),
  fill   = role_colors,
  border = NA, bty = "n", cex = 0.8, title = "Role"
)
dev.off()
cat("Saved: viz_igraph.png\n")

# ── 6. Visualization B: ggraph (ggplot2-style) ─────────────────────────────
# Edge attrs (weight, since) are already on g_social from as_igraph()
tg <- as_tbl_graph(g_social)

p_ggraph <- ggraph(tg, layout = "fr") +
  geom_edge_link(
    aes(width = weight, alpha = weight),
    arrow      = arrow(length = unit(3, "mm"), type = "closed"),
    end_cap    = circle(6, "mm"),
    color      = "#666666"
  ) +
  geom_node_point(aes(color = role), size = 10) +
  geom_node_text(aes(label = name), color = "white", size = 3, fontface = "bold") +
  scale_color_manual(values = role_colors, name = "Role") +
  scale_edge_width(range = c(0.5, 2.5), name = "Strength") +
  scale_edge_alpha(range = c(0.4, 1.0), guide = "none") +
  labs(title = "Social Network", subtitle = "Edge width = relationship strength") +
  theme_graph(base_family = "sans") +
  theme(legend.position = "right")

ggsave("viz_ggraph.png", p_ggraph, width = 10, height = 7, dpi = 150)
cat("Saved: viz_ggraph.png\n")

# ── 7. Visualization C: bipartite Person–Topic network with ggraph ─────────
result_pt <- lb_execute(conn,
  "MATCH (p:Person)-[r:Interested]->(t:Topic) RETURN p, r, t"
)

# Build bipartite igraph manually from query results
pt_edges <- lb_query(conn,
  "MATCH (p:Person)-[r:Interested]->(t:Topic)
   RETURN p.name AS person, t.name AS topic, r.level AS level"
)

level_width <- c(expert = 2.5, intermediate = 1.5, beginner = 0.7)

all_nodes <- data.frame(
  name      = c(unique(pt_edges$person), unique(pt_edges$topic)),
  node_type = c(rep("Person", length(unique(pt_edges$person))),
                rep("Topic",  length(unique(pt_edges$topic)))),
  # igraph bipartite layout needs logical 'type': TRUE = left side, FALSE = right
  type      = c(rep(TRUE,  length(unique(pt_edges$person))),
                rep(FALSE, length(unique(pt_edges$topic)))),
  stringsAsFactors = FALSE
)
all_nodes$role <- role_map[all_nodes$name]

g_bipartite <- graph_from_data_frame(
  d        = pt_edges[, c("person","topic","level")],
  vertices = all_nodes,
  directed = TRUE
)

tg_bp <- as_tbl_graph(g_bipartite)

field_colors <- c(
  AI          = "#B07AA1",
  Data        = "#FF9DA7",
  Design      = "#9C755F",
  Engineering = "#BAB0AC",
  Math        = "#EDC948"
)

p_bipartite <- ggraph(tg_bp, layout = "bipartite") +
  geom_edge_link(
    aes(edge_width = level_width[level], alpha = level),
    color = "#555555",
    arrow = arrow(length = unit(2.5, "mm"), type = "closed"),
    end_cap = circle(5, "mm")
  ) +
  geom_node_point(
    aes(color = ifelse(node_type == "Person", role, name),
        shape = node_type,
        size  = node_type)
  ) +
  geom_node_text(aes(label = name), size = 2.8, fontface = "bold",
                 nudge_y = 0.08, color = "#222222") +
  scale_color_manual(
    values = c(role_colors, field_colors),
    name   = "Person role / Topic field",
    na.value = "#AAAAAA"
  ) +
  scale_shape_manual(values = c(Person = 16, Topic = 15), name = "Node type") +
  scale_size_manual(values  = c(Person = 8,  Topic = 7),  name = "Node type") +
  scale_edge_width(range = c(0.5, 2.5), guide = "none") +
  scale_edge_alpha_manual(
    values = c(expert = 1, intermediate = 0.7, beginner = 0.4),
    name   = "Interest level"
  ) +
  labs(title    = "Person–Topic Interest Network",
       subtitle = "Edge opacity = interest level") +
  theme_graph(base_family = "sans")

ggsave("viz_bipartite.png", p_bipartite, width = 12, height = 7, dpi = 150)
cat("Saved: viz_bipartite.png\n")

# ── 8. Visualization D: visNetwork interactive HTML ────────────────────────
vis_nodes <- data.frame(
  id    = V(g_social)$name,
  label = V(g_social)$name,
  group = V(g_social)$role,
  title = paste0("<b>", V(g_social)$name, "</b><br>Role: ", V(g_social)$role),
  stringsAsFactors = FALSE
)

vis_edges_df <- lb_query(conn,
  "MATCH (a:Person)-[r:Knows]->(b:Person)
   RETURN a.name AS from, b.name AS to, r.weight AS weight, r.since AS since"
)
vis_edges <- data.frame(
  from   = vis_edges_df$from,
  to     = vis_edges_df$to,
  width  = vis_edges_df$weight * 4,
  title  = paste0("Since: ", vis_edges_df$since,
                  "<br>Strength: ", vis_edges_df$weight),
  arrows = "to",
  stringsAsFactors = FALSE
)

vis_colors <- lapply(names(role_colors), function(r) {
  list(background = role_colors[r], border = "#ffffff",
       highlight  = list(background = role_colors[r], border = "#333333"))
})
names(vis_colors) <- names(role_colors)

vnet <- visNetwork(vis_nodes, vis_edges,
                   main = "Social Network (interactive)",
                   width = "100%", height = "600px") |>
  visGroups(groupname = "Engineer",   color = role_colors["Engineer"])   |>
  visGroups(groupname = "Researcher", color = role_colors["Researcher"]) |>
  visGroups(groupname = "Designer",   color = role_colors["Designer"])   |>
  visGroups(groupname = "Manager",    color = role_colors["Manager"])    |>
  visLegend(position = "right", main = "Role") |>
  visOptions(highlightNearest = list(enabled = TRUE, degree = 1),
             nodesIdSelection  = TRUE) |>
  visPhysics(solver = "forceAtlas2Based",
             forceAtlas2Based = list(gravitationalConstant = -60)) |>
  visInteraction(navigationButtons = TRUE)

visNetwork::visSave(vnet, "viz_interactive.html", selfcontained = TRUE)
cat("Saved: viz_interactive.html  (open in browser)\n")

# ── 9. Graph metrics from LadybugDB data ──────────────────────────────────
cat("\n--- Network metrics ---\n")
cat(sprintf("Nodes          : %d\n", vcount(g_social)))
cat(sprintf("Edges          : %d\n", ecount(g_social)))
cat(sprintf("Density        : %.3f\n", edge_density(g_social)))
cat(sprintf("Avg path length: %.3f\n", mean_distance(g_social, directed = FALSE)))

deg <- degree(g_social, mode = "all")
cat("\nDegree centrality (total connections):\n")
print(sort(deg, decreasing = TRUE))

betw <- betweenness(g_social, normalized = TRUE)
cat("\nBetweenness centrality (top connectors):\n")
print(round(sort(betw, decreasing = TRUE), 3))

# ── 10. Cleanup ────────────────────────────────────────────────────────────
lb_close(conn)
lb_close(db)
cat("\nDone. Output files:\n")
cat("  viz_igraph.png       — base igraph plot\n")
cat("  viz_ggraph.png       — ggplot2/ggraph plot\n")
cat("  viz_bipartite.png    — bipartite Person–Topic plot\n")
cat("  viz_interactive.html — interactive visNetwork (open in browser)\n")
