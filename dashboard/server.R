source(file.path("R", "individual_server.R"), local = TRUE)
source(file.path("R", "population_server.R"), local = TRUE)

server <- function(input, output, session) {
  individual_server(input, output, session)
  population_server(input, output, session)
}
