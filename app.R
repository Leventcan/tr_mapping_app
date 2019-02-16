library(shiny)
library(readxl)
library(sf)
library(ggplot2)
library(dplyr)


tr2_map <- st_read("maps/TR2_Map.json")
tr3_map <- st_read("maps/TR3_Map.json")

map_theme1 <- function(){
    theme_minimal() +
        theme(panel.grid.major = element_line(colour = 'transparent'),
              axis.line=element_blank(),
              axis.text=element_blank(),
              axis.title = element_blank(),
              legend.position= c(0.75, 0), #sol değeri artırırsan sağa kayar, sağdakini azaltırsan aşağıya
              legend.direction="vertical",
              plot.caption = element_text(size=5),
              plot.title = element_text(size=17),
              legend.title=element_blank()
        ) 
}


# Define UI for data upload app ----
ui <- fluidPage(
    
    # App title ----
    titlePanel("Tematik Harita Oluşturucu"),
    
    # Sidebar layout with input and output definitions ----
    sidebarLayout(
        
        # Sidebar panel for inputs ----
        sidebarPanel(
            
            # Input: Select a file ----
            fileInput("file1", "Choose CSV File",
                      multiple = TRUE,
                      accept = c("text/csv",
                                 "text/comma-separated-values,text/plain",
                                 ".csv")),
            
            # Horizontal line ----
            tags$hr()
            
        ),
        
        # Main panel for displaying outputs ----
        mainPanel(
            
            # Output: Data file ----
            tableOutput("contents"),
            plotOutput("map01")
            
        )
        
    )
)

# Define server logic to read selected file ----
server <- function(input, output) {
    
    output$contents <- renderTable({
        
        # input$file1 will be NULL initially. After the user selects
        # and uploads a file, head of that data file by default,
        # or all rows if selected, will be shown.
        
        req(input$file1)
        
        df <- read_excel(input$file1$datapath)
        
        return(df)
        
        
             
        })
    
    
    output$map01 <- renderPlot({
        
        ggplot(tr3_map) + geom_sf() + map_theme1()
        
        
        
    })
    
}
# Run the app ----
shinyApp(ui, server)