### functions


library(tidyverse)
library(lubridate)
require(sf)


downloaddata<-function(opsd_data,ninja_data,shape_data){
  
  dir.create("downloads", showWarnings = FALSE)
  
  if(!file.exists(opsd_data)){
    
    download.file("https://data.open-power-system-data.org/time_series/2018-06-30/time_series_60min_singleindex.csv",
                  destfile=opsd_data)
  }
  
  if(!file.exists(ninja_data)){ 
    download.file("https://www.renewables.ninja/static/downloads/ninja_europe_wind_v1.1.zip",
                  mode="wb",
                  destfile=ninja_data)
  }
  
  unzip(ninja_data,overwrite=TRUE,
        exdir="downloads")
  
  if(!file.exists(shape_data)){
    download.file("http://thematicmapping.org/downloads/TM_WORLD_BORDERS-0.3.zip",
                  mode="wb",
                  destfile=shape_data)
  }
  unzip(shape_data,exdir="downloads")
  
}

circleFun <- function(center = c(0,0),diameter = 1, npoints = 100){
  r = diameter / 2
  tt <- seq(0,2*pi,length.out = npoints)
  xx <- center[1] + r * cos(tt)*20
  yy <- (center[2] + r * sin(tt))
  return(data.frame(x = xx, y = yy))
}




createOutputTablesAndFigures<-function(tab_ninja,fileappout,map=FALSE){
  tab_agg_ninja<-tab_ninja %>% gather(Country,CapFact,-time) %>% 
    mutate(year=year(time),month=month(time)) %>% 
    group_by(Country,year,month) %>% 
    summarize(CapFact=mean(CapFact,na.rm=TRUE)) %>% 
    na.omit()
  
  tab_fin<-tab_agg_ninja %>% filter(month %in% c(12)) %>% group_by(Country) %>% filter(CapFact==min(CapFact))
  
  write_csv(tab_fin,paste0(fileappout,"lowest_wind_years.csv"))
  
  tab_fin_1<-tab_agg_ninja %>% filter(month %in% c(12)) %>% group_by(Country) %>%
    mutate(meanCap=mean(CapFact)) %>% 
    filter(CapFact<meanCap) %>% filter(year==2016) %>% mutate(Category="Below Mean")
  
  tab_fin_2<-tab_agg_ninja %>% filter(month %in% c(12)) %>% group_by(Country) %>%
    mutate(meanCap=mean(CapFact)) %>% 
    filter(CapFact>meanCap) %>% filter(year==2016) %>% mutate(Category="Above Mean")
  
  means<-bind_rows(tab_fin_1,tab_fin_2) %>% mutate(ISO2=Country)
  means %>% write_csv(paste0(fileappout,"below_above_mean.csv"))
  
  
  
  
  
  tab_agg_ninja %>% filter(month %in% c(12)) %>% 
    group_by(Country) %>% mutate(meanCapFact=mean(CapFact)) %>% 
    ungroup() %>% 
    ggplot(aes(x=year,y=CapFact-meanCapFact)) + 
    geom_line(col="red",size=1) + 
    ylab("Mean Capacity Factor") + 
    xlab("Year") +
    facet_wrap( ~ Country)
  
  ggsave(paste0(fileappout,"CapFactDecembreDeviation.png"))
  
  if(map) {
    
    
    shape <-st_read(
      "downloads/TM_WORLD_BORDERS-0.3.shp", 
      quiet = TRUE) 
    
    shape_merge<-merge(shape,means,all.x=FALSE,by="ISO2")
    shape_merge %>% ggplot() + 
      geom_sf(aes(fill = CapFact-meanCap), colour = "black") + theme_void()
    ggsave(paste0(fileappout,"map.png"))
    
    
    
  }
}