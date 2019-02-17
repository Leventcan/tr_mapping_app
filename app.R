library(shiny)
library(readxl)
library(tibble)
library(ggplot2)
library(dplyr)
library(RColorBrewer)
library(sf)


options(shiny.sanitize.errors=FALSE)

tr2_map <- st_read("https://raw.githubusercontent.com/Leventcan/spatial_files/master/TR2_Map.json")
tr3_map <- st_read("https://raw.githubusercontent.com/Leventcan/spatial_files/master/TR3_Map.json")
nc <- st_read(system.file("shape/nc.shp", package="sf"))

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
              legend.title=element_blank(),
              legend.spacing.x = unit(0.1, 'cm')
        ) 
}

pal_info <-brewer.pal.info
pal_info <- rownames_to_column(pal_info, "palette")

# Define UI for data upload app ----
ui <- fluidPage(
    
    # App title ----
    titlePanel("Tematik Harita Oluşturucu"),
    
    # Sidebar layout with input and output definitions ----
    sidebarLayout(
        
        # Sidebar panel for inputs ----
        sidebarPanel(
            
            # Input: Select a file ----
            fileInput("file1", "Excel Dosyası Yükleyin",
                      multiple = TRUE,
                      accept = c("text/csv",
                                 "text/comma-separated-values,text/plain",
                                 ".csv",
                                 ".xls",
                                 ".xlsx")),
            
            selectInput("olcek", label = h4("Ölçek Seçiniz"), 
                        choices = list("Düzey-2", "Düzey-3"), 
                        selected = "Düzey-3"),
            
            selectInput("veri_tip", label = h4("Verinizin Tipini Seçiniz"),
                        choices = list("Ardışık" = "seq", "Kategorik" = "qual",
                                       "Ayrıksı" = "div"),
                        selected = "seq"),
            
            uiOutput("map_palette"),
            
            selectInput("colour_order", label = h4("Renk Sırası"), 
                        choices = list("Düz" = 1 , "Ters" = 2), 
                        selected = "Düz"),
            
            numericInput("legend_col", label = h4("Lejand Kolon Sayısı"), value = 1),
            
            checkboxInput("etiket", label = "Etiket Olsun", value = FALSE),
            
            tags$h5("Yükleyeceğiniz excel dosyalarında ", 
                    tags$a(href = "https://github.com/Leventcan/tr_mapping_app/raw/master/sample_excel_tr2.xlsx", "Düzey-2"),
                    " ve ",
                    tags$a(href = "https://github.com/Leventcan/tr_mapping_app/raw/master/sample_excel_tr3.xlsx", "Düzey-3"),
                    " verileri için linkte belirtilen excel dosyalarının kullanılmasında fayda bulunmaktadır."),
            
            actionButton("map_button", "Haritayı Oluştur"),
            
            tags$br(),
            tags$br(),
            
            tags$h3(tags$b("İndirme")),
            
            fluidRow(
               column(4,numericInput("num_width", label = h5("Genişlik"), value = 14)),
               column(4, numericInput("num_height", label = h5("Yükseklik"), value = 7))
                
            ),
            
            
            downloadButton('downloadPlot', label = "İndir")
            
        ),
        
        
        mainPanel(
            
            plotOutput("map01")
            
        )
        
    )
)

# Define server logic to read selected file ----
server <- function(input, output) {
    
    
    df_data <- reactive({
        
        validate(
            need(input$file1$datapath != "", "Lütfen öncelikle excel dosyasını yükleyiniz...")
        )
        
        read_excel(input$file1$datapath) 
        
    })
    
    map_data <- reactive(
        
        if (input$olcek == "Düzey-3") {
            tr3_map %>% left_join(df_data(), by = c("NUTS_ID" = "NUTS_ID")) %>% 
                mutate(DATA =as.factor(DATA)) %>% rename(LABEL = IL_ADI)
        } else {
            tr2_map %>% left_join(df_data(), by = c("NUTS_ID" = "NUTS_ID")) %>% 
                mutate(DATA =as.factor(DATA)) %>% mutate(LABEL = NUTS_ID)
        }
    )
    
    
    map_data1 <- eventReactive(input$map_button, {
        
        map_data()
        
    })
    
    output$map_palette <- renderUI({
        
        chosen_pal <- filter(pal_info, category == input$veri_tip)$palette 
        selectInput("palette", label = h4("Palet Seçiniz"),
                    choices = chosen_pal)
    })
    

    plotInput <-  reactive( {
        p = ggplot(map_data1()) + geom_sf(aes(fill = DATA),size = 0.4) + 
            map_theme1() + 
            scale_fill_brewer(palette = input$palette , 
                                  direction = if(input$colour_order == 1){
                                      1
                                  } else{
                                      -1
                                  }
                                      ) +
            guides(fill=guide_legend(ncol=input$legend_col))
        
        if (input$etiket == TRUE){
            p + geom_sf_text( aes(label = LABEL), size = 2.3)
        } else {
            p
        }
    })
    
    
    output$map01 <- renderPlot({
        
        plotInput()
        
    })
    
    
    #Belki daha sonra kullanılabilir
    # output$deneme <- renderTable({
    #     return(df_data())
    #     
    # })
    
    output$downloadPlot <- downloadHandler(
        filename = 'test.png',
        content = function(file) {
            device <- function(..., width, height) {
                grDevices::png(..., width = width, height = height,
                               res = 300, units = "in")
            }
            ggsave(file, plot = plotInput(), device = device, width = input$num_width, height = input$num_height)
        })
    
}
# Run the app ----
shinyApp(ui, server)