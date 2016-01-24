library(shiny)
library(ggplot2)

cartridgeTagList = c("300Blk", "308Win", "300WinMag")

readLoadDataFile <- function(tag) {
  fileName = paste(tag,"StartingLoads.csv",sep = "")
  loadData <- read.csv(fileName, header = T)
#   print("before cleaning")
#   print(head(loadData))
  loadData$PowderType <- gsub("( |\\.|/|-)*","",as.character(loadData$PowderType))
  loadData$PowderManufacturer <- as.character(loadData$PowderManufacturer)
  loadData$BulletManufacturer <- as.character(loadData$BulletManufacturer)
  loadData$BulletType <- as.character(loadData$BulletType)
  # print(loadData[1,])
  loadData$StartLoad <- as.numeric(as.character(loadData$StartLoad))
  # print(loadData[1,])
  loadData <- loadData[order(loadData$BulletMass),]
#   print("after cleaning and sorting")
#   print(head(loadData))
  loadData
}

initializePowderRank <- function(directory = "") {
  
  oldWD = getwd()
  setwd(ifelse(directory != "",directory,oldWD))
  powderRank <- read.csv("SmokelessPowdersRankedByBurnRate.csv",header = T, skip = 1)
  powderRank$Notes <- as.character(powderRank$Notes)
  powderRank$Product <- gsub("( |\\.|/|-)*","",as.character(powderRank$Product))
  powderRank$Manufacturer <- as.character(powderRank$Manufacturer)
  powderRank
}

initializePowderPredictor <- function (directory = "") {
  #TBD: dynamic loading for load data by cartridge selection.
  #TBD: refactor data cleaning code: DONE
  AllLoads = readLoadDataFile(cartridgeTagList[1])
  AllLoads$Cartridge <- cartridgeTagList[1]
  for (cartridgeTag in cartridgeTagList[-1]) {
    loadData <- readLoadDataFile(cartridgeTag)
    loadData$Cartridge <- cartridgeTag
    AllLoads = rbind(AllLoads,loadData)
  }
  # print(AllLoads)
  RankedLoadData <-  merge(AllLoads,PowderRank,
                           by.x=c("PowderManufacturer", "PowderType"),
                           by.y = c("Manufacturer","Product"))
  # print(RankedLoadData)
}

getBulletMasses <- function(x) {
  sort(unique(x$BulletMass))
}

getBulletsInfo <- function(x,mass) {
  unique(x[x$BulletMass == mass,c("BulletManufacturer","BulletType", "BulletMass")])
}

getPowderRange <- function(x,bulletMass) {
  sort(x[x$BulletMass == bulletMass,"Rank"])
}

getStartLoadVel <- function(x,bulletInfo) {
  getStartLoadVel1(x,bulletInfo$BulletMass, bulletInfo$BulletType, bulletInfo$BulletManufacturer)
}
getStartLoadVel1 <- function(x,bulletMass,bulletType,bulletManufacturer) {
  x[x$BulletMass == bulletMass & x$BulletType == bulletType & x$BulletManufacturer == bulletManufacturer,
    c("StartLoad","Rank", "PowderType", "PowderManufacturer")]
}

findOtherPowders <- function(range) {
  if (length(range) > 1)   PowderRank[range[1]:range[length(range)],c("Rank","Manufacturer","Product")]
  else PowderRank[range[1],c("Rank","Manufacturer","Product")]
}


findPowdersForBullet <- function(x,bulletMass) {
  #TODO: should only match specific bullets, not bullet mass,  due to length/seating depth variations!
  bulletsInfo = getBulletsInfo(x,bulletMass)
  startLoads = getStartLoadVel(x,getBulletsInfo(x,bulletMass)[1,])
  if (dim(bulletsInfo)[1] > 1) {
    for(ii in 2:dim(bulletsInfo)[1]) {
      startLoads = rbind(startLoads,
                         getStartLoadVel(x,getBulletsInfo(x,bulletMass)[ii,]))
    }
  }
  # browser()
  startLoads$Interpolated <- FALSE
  if (dim(startLoads)[1] > 0) { 
    # print(startLoads)
    interpolatedLoads =  findOtherPowders(getPowderRange(x,bulletMass))
    loadsDF = merge(
      interpolatedLoads,
      startLoads,
      all.x = T,x.by=c("Rank","Manufacturer","Product"), 
      y.by=c("Rank","PowderManufacturer","PowderType")
    )[,c("Rank","Manufacturer","Product","StartLoad", "Interpolated")]
    #now model the starting loads
    naLoads = which(is.na(loadsDF$StartLoad))
    if (length(naLoads) > 0 && dim(loadsDF[-naLoads,])[1] > 0) {
      loadsDF[naLoads,]$Interpolated <- TRUE
      #interpolation is necessary
      loadModel = lm(StartLoad ~ Rank, data = loadsDF[-naLoads,])
      loadsDF[naLoads,"StartLoad"] = predict(loadModel, newdata = loadsDF[naLoads,])
      loadsDF$StartLoad = round(loadsDF$StartLoad,1)
    } 
    loadsDF
  }
}

getBulletsForCartridge <- function(x,cartridge) {
  if (cartridge %in% cartridgeTagList) {
    bulletsDF <- x[,c("BulletMass", "BulletManufacturer", "BulletType")]
    sort(unique(paste(bulletsDF[,1],bulletsDF[,2],bulletsDF[,3])))
  } 
}


PowderRank <- initializePowderRank() #reads powder rank data  from current dir
RankedLoadData <- initializePowderPredictor() #reads load data files from current dir

shinyServer(
  function(input, output) {
    reactiveDataTable <- reactive({
      if (!is.null(input$bullet) && input$bullet != "" && !is.null(input$cartridge) && input$cartridge != "") 
        findPowdersForBullet(RankedLoadData[RankedLoadData$Cartridge == input$cartridge,], 
                                                                             as.integer(strsplit(as.character(input$bullet)," ")[[1]][1]))})
    
    output$bulletControls <- renderUI(
      {
        bullets <- getBulletsForCartridge(RankedLoadData[RankedLoadData$Cartridge == input$cartridge,],
                                          input$cartridge)
        selectInput("bullet", "Choose Bullet (grains, manufacturer, type):", bullets)
      }
    )
    
    
    output$selectedBullet <- renderText({input$bullet})
    output$resultsTable <- 
      renderDataTable({
        if (is.null(input$bullet))  ""
        else reactiveDataTable()
      })
    
   
    output$resultsPlot <- renderPlot({
      outputTable <- reactiveDataTable()
      gplot = ggplot(outputTable[,c("Rank","StartLoad")], aes(x = Rank, y = StartLoad )) +
        geom_point() + xlab("Powder Burn Rate Ranking (fast-slow)") + ylab("Starting Loads (grains)") 
        # + main(paste("Starting Loads for ",output$selectedBullet))
      gplot = gplot + geom_point(data = outputTable[outputTable$Interpolated == TRUE,],aes(x=Rank,y=StartLoad, color=Interpolated))
      # print(outputTable)
      if (!is.null(outputTable)) gplot
      })
  }
)
