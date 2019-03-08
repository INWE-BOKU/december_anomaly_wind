### Clim2power project
### Winter sea ice: how was wind power generation in December 2016 compared to average generation?
### Author: Johannes Schmidt



#### This works in R-Studio only
scriptDir<-dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(paste0(scriptDir,"/../"))

source("scripts/functions.R")

#### Download all necessary data. If data is already on disk, it is not downloaded again
opsd_data<-"downloads/time_series_60min_singleindex.csv"
ninja_data<-"downloads/renewables_ninja.zip"
shape_data<-"downloads/world_shape.zip"


downloaddata(opsd_data,ninja_data,shape_data)


##### First analysis: observed wind capacity factors for Germany. ####

opsd<-read.csv(opsd_data,sep=",")

opsd<-as_tibble(opsd)

opsd$utc_timestamp<-as.POSIXct(as.character(opsd$utc_timestamp))

opsd<-opsd %>% gather(Variable,val,-utc_timestamp,-cet_cest_timestamp)

opsd_reduced<-opsd %>% filter(Variable == "DE_wind_profile") 

circle<-circleFun(c(2016,0.25),0.1,npoints=100)

opsd_reduced %>%   mutate(year=year(utc_timestamp),month=month(utc_timestamp)) %>% 
  group_by(year,month) %>% 
  summarize(mean_v=mean(as.numeric(val),na.rm=TRUE)) %>% 
  na.omit() %>% filter(month %in% c(11,12,1)) %>% 
  ggplot(aes(x=year,y=mean_v)) + 
  geom_line(col="red",size=2) + 
  ylab("Mean Capacity Factor Decembre") + 
  xlab("Year") +
  facet_wrap(~month)
#  geom_path(data=circle,aes(x,y))+
 
ggsave("output/opsd_wind_germany.png")

##### Second analysis: simulated capacity factors for 1980-2016 from renewables.ninja #####
##### The function creates various tables and output figures in the respective directory #####
##### A map is only drawn for onshore wind results #####

tab_ninja1<-read_csv("downloads/ninja_wind_europe_v1.1_current_national.csv")
createOutputTablesAndFigures(tab_ninja1,"output/onshore/",TRUE)

tab_ninja2<-read_csv("downloads/ninja_wind_europe_v1.1_current_on-offshore.csv")
createOutputTablesAndFigures(tab_ninja2,"output/onshore_offshore/")
