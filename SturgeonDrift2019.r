############
##Import Step
###########
library(vegan)
library(MASS)
library(ggplot2)
library(plyr)
library(dplyr)
library(magrittr)
library(scales)
library(grid)
library(reshape2)
library(phyloseq)
library(randomForest)
library(knitr)
library(ape)
library(lubridate)
library(ggpubr)
library(multcompView)
library(lme4)
library(tiff)

#DRIFT FILES all taxa
otufull=read.table("DataClean\\SturgeonDriftInvertAbundanceMatrix8.15.19.txt",header=TRUE)
head(otufull)
metadata=read.csv("DataClean\\SturgeonDriftMetadata8.15.19.csv",header=TRUE)
metadata<-subset(metadata,Ninverts!=0) #Remove sample dates where no inverts were collected
taxmatrixfull=as.matrix(read.table("DataClean\\SturgeonDriftInvertTaxNames8.15.19.txt"))
head(taxmatrixfull)
levels(metadata$MoonPhase)

cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#000000","#CC79A7")
theme_set(theme_bw(base_size = 12)+theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()))
#sets the plotting theme
OTU=otu_table(otufull, taxa_are_rows=TRUE)
#OTU
TAX=tax_table(taxmatrixfull)
colnames(TAX)=("Family")

sampdat=sample_data(metadata)
sample_names(sampdat)=sampdat$SampleID
#head(sampdat)
taxa_names(TAX)=row.names(OTU)
physeq=phyloseq(OTU,TAX,sampdat)#joins together OTU,TAX, and metadata 
physeq
levels(sample_data(physeq)$MoonPhase)
sample_data(physeq)$MoonPhase = factor(sample_data(physeq)$MoonPhase, levels = c("New Moon","Waxing Crescent","First Quarter","Waxing Gibbous","Full Moon","Waning Gibbous","Last Quarter","Waning Crescent"))
#levels(sample_data(physeq)$CODE)=c("NM","WXC","FQ","WXG","FM","WAG","LQ","WNC")


#####################
#General Result info
####################

AllData<-read.csv("DataClean\\AllDriftDataCombined2011-2018.csv",header=T)
AllData<-subset(AllData,Ninverts!=0) #Remove sample dates where no inverts were collected
head(AllData)
AllData$Year
SamplesByYear <- ddply(AllData, c("Year"), summarise,
                 N    = length(SampleID),
                 Sturgeon = sum(Nsturgeon),
                 Inverts5 = sum(Ninverts),
                 Inverts100 = sum(Ninverts100),
                 Catostomidae = sum(Nsuckers100)
)
SamplesByYear
mean(SamplesByYear$N) #Average number of days per year
sum(SamplesByYear$N) #Total number of sampling days
sum(AllData$Ninverts) #Number of invertebrates IDed
sum(AllData$Ninverts100) #100% numbers for inverts
sum(AllData$Nsturgeon) #Total number of sturgeon larvae collected
sum(AllData$Nsuckers100)#number of catostomidae larvae

SturgeonByYearByNight<- ggplot(SamplesByYear, aes(x=Year,y=Sturgeon/N))+geom_bar(stat="identity")+ylab("Sturgeon Per Night Sampled")
InvertsByYearByNight<-ggplot(SamplesByYear, aes(x=Year,y=Inverts100/N))+geom_bar(stat="identity")+ylab("Invertebrates Per Night Sampled")
SturgeonByYearByNight
InvertsByYearByNight
dev.off()
tiff("Figures/TotalsByYearPerNight.tiff", width = 6.85, height = 3.5, units = 'in', res = 300)
ggarrange(SturgeonByYearByNight,InvertsByYearByNight,
          labels = c("a", "b"),
          ncol = 2, nrow = 1)
dev.off()

SturgeonByYear<- ggplot(SamplesByYear, aes(x=Year,y=Sturgeon))+geom_bar(stat="identity")+ylab("Sturgeon larvae")
InvertsByYear<-ggplot(SamplesByYear, aes(x=Year,y=Inverts100))+geom_bar(stat="identity")+ylab("Invertebrates collected")


dev.off()
tiff("Figures/TotalsByYear.tiff", width = 6.85, height = 3.3, units = 'in', res = 300)
ggarrange(SturgeonByYear,InvertsByYear,
          labels = c("a", "b"),
          ncol = 2, nrow = 1)
dev.off()

dev.off()
tiff("Figures/TotalsByYearCombined.tiff", width = 6.85, height = 6.85, units = 'in', res = 300)
ggarrange(SturgeonByYear,InvertsByYear,SturgeonByYearByNight,InvertsByYearByNight,
          labels = c("a", "b","c","d"),
          ncol = 2, nrow = 2)
dev.off()

#Sucker abu by day and year
Trtdata <- ddply(AllData, c("DPFS","Year"), summarise,
                 N    = length(Nsuckers.100..),
                 meanSuckers = mean(Nsuckers.100..)
)
Trtdata

SuckersByDPFS<-ggplot(Trtdata, aes(x=DPFS,y=meanSuckers))+geom_bar(colour="black", stat="identity")+xlab("Days Post First Spawning")+ylab("Larval Sucker Abundance")+
 theme(axis.text.x = element_text(angle = 45, hjust = 1))+facet_grid(Year~.)#+scale_fill_manual(values=cbPalette)
SuckersByDPFS


#Sturgeon abu by day and year
Trtdata <- ddply(AllData, c("DPFS","Year"), summarise,
                 N    = length(Nsuckers100),
                 meanSturgeon = mean(Nsturgeon)
)
Trtdata
SturgeonByDPFS<-ggplot(Trtdata, aes(x=DPFS,y=meanSturgeon))+geom_bar(colour="black", stat="identity")+xlab("Days Post First Spawning")+ylab("Larval Sturgeon Abundance")+
  theme(axis.text.x = element_text(angle = 45, hjust = 1))+facet_grid(Year~.)#+scale_fill_manual(values=cbPalette)
SturgeonByDPFS

#Invertebrate abu by day and year
Trtdata <- ddply(AllData, c("DPFS","Year"), summarise,
                 N    = length(Ninverts100),
                 meanInvert = mean(Ninverts100)
)
Trtdata
InvertByDPFS<-ggplot(Trtdata, aes(x=DPFS,y=meanInvert))+geom_bar(colour="black", stat="identity")+xlab("Days Post First Spawning")+ylab("Invertebrate Abundance")+
  theme(axis.text.x = element_text(angle = 45, hjust = 1))+facet_grid(Year~.)#+scale_fill_manual(values=cbPalette)
InvertByDPFS

theme_set(theme_bw(base_size = 9)+theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()))

dev.off()
tiff("Figures/SturgeonInvertByDPFSByYear.tiff", width = 6.85, height = 6.85, units = 'in', res = 300)
ggarrange(SuckersByDPFS,SturgeonByDPFS, InvertByDPFS,
          labels = c("a", "b","c"),
          ncol = 2, nrow = 2)
dev.off()
theme_set(theme_bw(base_size = 12)+theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()))

#####################
#Alpha diversity
####################
#Shannon Richness
head(sample_data(physeq))
Richness=plot_richness(physeq, x="DPFS", measures=c("Shannon"))#+geom_boxplot(aes(x=DPFS, y=value, color=DPFS), alpha=0.05)
Richness+ theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())+xlab("Date")
#Richness$data

write.csv(Richness$data, "SturgeonMetadataWDiversity.csv")
ShannonRichness<-read.csv("SturgeonMetadataWDiversity.csv",header=T)
ShannonRichness
levels(ShannonRichness$MoonPhase)
levels(metadata$MoonPhase)
#Days post first spawn
Trtdata <- ddply(ShannonRichness, c("DPFS"), summarise,
                 N    = length(value),
                 meanShannon = mean(value),
                 sd   = sd(value),
                 se   = sd / sqrt(N)
)
#Trtdata
theme_set(theme_bw(base_size = 12)+theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()))
ggplot(Trtdata, aes(x=DPFS,y=meanShannon))+geom_bar(aes(),colour="black", stat="identity")+xlab("Days post first spawn")+ylab("Shannon (SEM)")+
  geom_errorbar(aes(ymin=meanShannon-se,ymax=meanShannon+se))

hist(ShannonRichness$percillum)
hist(log(ShannonRichness$Ninverts100))
hist((ShannonRichness$Ninverts100))


#ShannonSubset$percillum
hist(ShannonRichness$Ninverts100)
m1 = glmer(Ninverts100~1+(1|Year),data=ShannonRichness,family = poisson)
m2 = glmer(Ninverts100~percillum+(1|Year),data=ShannonRichness,family = poisson)
#m3 = glmer.nb(Ninverts100~DPFS+percillum+(1|Year),data=ShannonSubset)

m1=glm(Ninverts100~percillum,data=ShannonRichness,family=poisson)
summary(m1)


head(ShannonRichness)
AIC(m1,m2)
summary(m2)
plot(Ninverts100~percillum,data=ShannonRichness)
lines(predict(m2) ~ ShannonRichness$percillum)

ShannonRichness$MoonPhase = factor(ShannonRichness$MoonPhase, levels = c("New Moon","Waxing Crescent","First Quarter","Waxing Gibbous","Full Moon","Waning Gibbous","Last Quarter","Waning Crescent"))
levels(ShannonRichness$MoonPhase)
ggplot(ShannonRichness, aes(x=MoonPhase,y=Ninverts100))+geom_boxplot()








#By calendar date
Trtdata <- ddply(ShannonRichness, c("Date"), summarise,
                 N    = length(value),
                 meanShannon = mean(value),
                 sd   = sd(value),
                 se   = sd / sqrt(N)
)

ggplot(Trtdata, aes(x=Date2,y=meanShannon))+geom_bar(colour="black", stat="identity")+xlab("Calendar date")+ylab("Shannon (SEM)")+
  geom_errorbar(aes(ymin=meanShannon-se,ymax=meanShannon+se))+ theme(axis.text.x = element_text(angle = 45, hjust = 1))


#Moon phase
Trtdata <- ddply(ShannonRichness, c("MoonPhase"), summarise,
                 N    = length(value),
                 meanShannon = mean(value),
                 sd   = sd(value),
                 se   = sd / sqrt(N)
)
Trtdata
ggplot(Trtdata, aes(x=MoonPhase,y=meanShannon))+geom_bar(aes(fill = MoonPhase),colour="black", stat="identity")
ggplot(Trtdata, aes(x=MoonPhase,y=meanShannon))+geom_bar(aes(fill = MoonPhase),colour="black", stat="identity")+xlab("Moon Phase")+ylab("Shannon Diversity (SEM)")+
  geom_errorbar(aes(ymin=meanShannon-se,ymax=meanShannon+se))+ theme(axis.text.x = element_text(angle = 45, hjust = 1))+scale_fill_manual(values=cbPalette)+ theme(legend.position = "none")+
  geom_text(x=6.5,y=2,label="KW, Chi2=10.5, p= 0.158")

kruskal.test(value~MoonPhase,data=ShannonRichness)

hist(ShannonRichness$value)


ggplot(ShannonRichness,aes(x=LunarDay,y=value))+geom_point()

#Temperature 
ggplot(ShannonRichness, aes(x=Temp,y=value))+geom_point()+xlab("Calendar date")+ylab("Shannon (SEM)")+ theme(axis.text.x = element_text(angle = 45, hjust = 1))+
  geom_smooth()
Temps<-subset(ShannonRichness, Temp!= "NA")
Temps
head(Temps)
mean(Temps$Temp)
Temps$temp_centered = Temps$Temp - mean(Temps$Temp)
plot(Temps$value~Temps$temp_centered,xlab="Change from mean temp (19.027)", ylab="Shannon diversity")+abline(1.504,0.02275)

m = glm(value~ temp_centered, data=Temps)
summary(m)
m2 = lmer(value~temp_centered+(1|Year),data=Temps)
m1 = lmer(value~1+(1|Year),data=Temps)

anova(m1,m2,test='Chisq')
confint(m2)
summary(m2)

m4 = lmer(value~temp_centered*MoonPhase+(1|Year),data=Temps)
m5 = lmer(value~temp_centered+MoonPhase+(1|Year),data=Temps)
summary(m2)



AIC(m1,m3,m4,m5)

m1=glm(value~temp_centered+Year,data=Temps)

plot(residuals(m1)~Temp,data=Temps)
plot(resid(m1) ~ predict(m1))


m2 = lmer(value~DPFS+(1|Year),data=ShannonRichness,family)
m1 = lmer(value~1+(1|Year),data=ShannonRichness)
m1<-glm(value~temp_centered+percillum,data=Temps)
anova(m1,m2,test='Chisq')
confint(m2)
summary(m2)
head(Temps)

Percillum<-subset(ShannonRichness, percillum!= "#VALUE!")

Percillum$ni
plot(Ninverts100~percillum,data=Percillum)
Percillum$percillum<-as.numeric(Percillum$percillum)
m2<-(glm(value~percillum+Q,data=Percillum))
m2
plot(residuals(m2)~percillum,data=Percillum)

confint(m2)
hist(Percillum$percillum)
Percillum$percillum
#Total abundance percent illum test
m4 = glmer(Ninverts100~percillum+(1|Year),data=Percillum,family="poisson")
m5 = glmer(Ninverts100~1+(1|Year),data=Percillum,family="poisson")
anova(m4,m5,test='chisq')
confint(m4)
exp(.01)
m5 = glmer(value~temp_centered+MoonPhase+(1|Year),data=Temps,family="poisson")
summary(m4)
confint(m4)
summary(glm(Ninverts100~percillum,data=Percillum))
    
####################
##Total Abundance
####################
#Sturgeon
ggplot(ShannonRichness,aes(x=DPFS,y=Nsturgeon))+geom_point()#+geom_bar(aes(fill=DPFS),stat = "identity")

Trtdata <- ddply(ShannonRichness, c("DPFS","Year"), summarise,
                 N    = length(Nsturgeon),
                 meanSturgeon = mean(Nsturgeon),
                 sd   = sd(Nsturgeon),
                 se   = sd / sqrt(N)
)
Trtdata
#Subset<-subset(Trtdata,Year=="2018"|Year=="2017"|Year=="2016")

SturgeonByDPFS<-ggplot(Trtdata, aes(x=DPFS,y=meanSturgeon))+geom_bar(colour="black", stat="identity")+xlab("Days Post First Spawning")+ylab("Larval Sturgeon Abundance")+
  geom_errorbar(aes(ymin=meanSturgeon-se,ymax=meanSturgeon+se))+ theme(axis.text.x = element_text(angle = 45, hjust = 1))+facet_grid(Year~.)#+scale_fill_manual(values=cbPalette)

dev.off()
tiff("Figures/SturgeonByDPFSYear.tiff", width = 3.3, height = 3.3, units = 'in', res = 300)
SturgeonByDPFS
dev.off()



#SturgeonByMoonPhase
Trtdata <- ddply(ShannonRichness, c("DPFS","Year"), summarise,
                 N    = length(Nsturgeon),
                 meanSturgeon = mean(Nsturgeon),
                 sd   = sd(Nsturgeon),
                 se   = sd / sqrt(N)
)
Trtdata

ggplot(Trtdata, aes(x=DPFS,y=meanSturgeon))+geom_bar(colour="black", stat="identity")+xlab("DPFS")+ylab("Larval Sturgeon Abundance (SEM)")+
  geom_errorbar(aes(ymin=meanSturgeon-se,ymax=meanSturgeon+se))+ theme(axis.text.x = element_text(angle = 45, hjust = 1))+facet_grid(Year~.)#+scale_fill_manual(values=cbPalette)



#TotalInverts
ggplot(ShannonRichness,aes(x=DPFS,y=Ninverts100))+geom_point()#+geom_bar(aes(fill=DPFS),stat = "identity")

head(ShannonRichness)
Trtdata <- ddply(ShannonRichness, c("DPFS","Year"), summarise,
                 N    = length(Ninverts100),
                 meanSturgeon = mean(Ninverts100),
                 sd   = sd(Ninverts100),
                 se   = sd / sqrt(N)
)
#Trtdata
Subset<-subset(Trtdata,Year=="2018"|Year=="2017"|Year=="2016")
TotalInvertAbuDPFS<-ggplot(Trtdata, aes(x=DPFS,y=meanSturgeon))+geom_bar(colour="black", stat="identity")+xlab("DPFS")+ylab("Invertebrate Abundance")+xlab("Days Post First Spawning")+
  geom_errorbar(aes(ymin=meanSturgeon-se,ymax=meanSturgeon+se))+ theme(axis.text.x = element_text(angle = 45, hjust = 1))+facet_grid(Year~.)#+scale_fill_manual(values=cbPalette)
theme_set(theme_bw(base_size = 10)+theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()))
TotalInvertAbuDPFS

dev.off()
tiff("Figures/TotalInvertebrateAbuByDPFS.tiff", width = 3.3, height = 3.3, units = 'in', res = 300)
TotalInvertAbuDPFS
dev.off()


#By moon phase
Trtdata <- ddply(ShannonRichness, c("MoonPhase"), summarise,
                 N    = length(Ninverts100),
                 meanSturgeon = mean(Ninverts100),
                 sd   = sd(Ninverts100),
                 se   = sd / sqrt(N)
)
Trtdata
Trtdata$MoonPhase = factor(Trtdata$MoonPhase, levels = c("New Moon","Waxing Crescent","First Quarter","Waxing Gibbous","Full Moon","Waning Gibbous","Last Quarter","Waning Crescent"))

#hist(ShannonRichness$Ninverts100)

kruskal.test(Ninverts100~MoonPhase, data=ShannonRichness)

compare_means(Ninverts100 ~ MoonPhase, data = ShannonRichness, p.adjust.method = "fdr",method="wilcox.test")

Means=compare_means(Ninverts100 ~ MoonPhase, data = ShannonRichness, p.adjust.method = "fdr",method="wilcox.test")

Hyphenated<-as.character(paste0(Means$group1,"-",Means$group2))
difference<-Means$p.adj
names(difference)<-Hyphenated
Letters<-multcompLetters(difference)
Letters
vector<- c("a","ab","bc","c","bc","b","ab","ab")  #manually renamed due to some weirdness with plotting
Trtdata

theme_set(theme_bw(base_size = 8)+theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()))

ggplot(Trtdata, aes(x=MoonPhase,y=meanSturgeon))+geom_bar(aes(fill=MoonPhase),stat="identity")+xlab("Moon Phase")+ylab("Drift Invertebrate Abundance (SEM)")+
  geom_errorbar(aes(ymin=meanSturgeon-se,ymax=meanSturgeon+se))+scale_fill_manual(values=cbPalette)


TotalInvertAbuMoonPhase<-ggplot(Trtdata, aes(x=MoonPhase,y=meanSturgeon))+geom_bar(aes(fill=MoonPhase),stat="identity")+xlab("Moon Phase")+ylab("Drift Invertebrate Abundance (SEM)")+
  geom_errorbar(aes(ymin=meanSturgeon-se,ymax=meanSturgeon+se))+ theme(axis.text.x = element_text(angle = 45, hjust = 1))+scale_fill_manual(values=cbPalette)+
  geom_text(aes(x=MoonPhase, y=meanSturgeon+se+200,label=vector))+theme(legend.position = "none")+geom_text(aes(x=5,y=3000,label= "KW, chi-squared = 86.7, P <<0.001"),size=3)
TotalInvertAbuMoonPhase
dev.off()
tiff("Figures/TotalInvertebrateAbuByPhase.tiff", width = 3.3, height = 3.3, units = 'in', res = 300)
TotalInvertAbuMoonPhase
dev.off()

####################



#####
#Total invert biomass 
#####################
Trtdata <- ddply(ShannonRichness, c("MoonPhase"), summarise,
                 N    = length(Biomass_g100),
                 meanSturgeon = mean(Biomass_g100),
                 sd   = sd(Biomass_g100),
                 se   = sd / sqrt(N)
)
head(Trtdata)
Trtdata
Trtdata$MoonPhase = factor(Trtdata$MoonPhase, levels = c("NewMoon","WaxingCrescent","FirstQuarter","WaxingGibbous","FullMoon","WaningGibbous","LastQuarter","WaningCrescent"))


kruskal.test(Biomass_g100~MoonPhase, data=ShannonRichness)
ShannonRichness$MoonPhase = factor(ShannonRichness$MoonPhase, levels = c("NewMoon","WaxingCrescent","FirstQuarter","WaxingGibbous","FullMoon","WaningGibbous","LastQuarter","WaningCrescent"))

compare_means(Biomass_g100 ~ MoonPhase, data = ShannonRichness, p.adjust.method = "fdr",method="wilcox.test")

Means=compare_means(Biomass_g100 ~ MoonPhase, data = ShannonRichness, p.adjust.method = "fdr",method="wilcox.test")

Hyphenated<-as.character(paste0(Means$group1,"-",Means$group2))
difference<-Means$p.adj
names(difference)<-Hyphenated
Letters<-multcompLetters(difference)
Letters
Trtdata
vector<-c("bc","bc","ab","a","ab","b","ab","c")
DriftTotalInvertBiomass<-ggplot(Trtdata, aes(x=MoonPhase,y=meanSturgeon))+geom_bar(aes(fill=MoonPhase),stat="identity")+xlab("Moon Phase")+ylab("Drift Invertebrate Biomass (g/night, SEM)")+
  geom_errorbar(aes(ymin=meanSturgeon-se,ymax=meanSturgeon+se))+ theme(axis.text.x = element_text(angle = 45, hjust = 1))+scale_fill_manual(values=cbPalette)+theme(legend.position = "none")+
  geom_text(aes(x=MoonPhase, y=meanSturgeon+se+10,label=vector))+geom_text(aes(x=5,y=200,label= "KW, chi-squared = 49.7, P <<0.001"),size=3)
DriftTotalInvertBiomass
theme_set(theme_bw(base_size = 8)+theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()))

dev.off()
tiff("Figures/TotalInvertebrateBiomassByPhase.tiff", width = 3.3, height = 3.3, units = 'in', res = 300)
DriftTotalInvertBiomass
dev.off()




ShannonRichness
##############
#Temperature
###############
head(ShannonRichness)
ggplot(ShannonRichness,aes(x=Temp,y=Ninverts100))+geom_point()+geom_smooth()#+geom_bar(aes(fill=DPFS),stat = "identity")



model<-glm(Ninverts100~Temp,data=ShannonRichness,family = neg)

m2<-glm.nb(Ninverts100 ~ percillum, data = ShannonRichness)
summary(m2)
(est <- cbind(Estimate = coef(m2), confint(m2)))
exp(est)




summary(model)

hist(model$residuals)

hist(ShannonRichness$Ninverts100)








###############33
#Relative Abundance invertebrate taxa STILL IN PROGRESS
###############
#Relative abundance moon phase
######
GPr  = transform_sample_counts(physeq, function(x) x / sum(x) ) #transform samples based on relative abundance
RelTaxa1Per = filter_taxa(GPr, function(x) mean(x) > 1e-3, TRUE) #filter out any taxa lower tha 0.1%
#RelTaxa1Per  = transform_sample_counts(RelTaxa1Per, function(x) x / sum(x) ) #transform samples based on relative abundance

plot_bar(GPr, "MoonPhase","Abundance", "Family")+scale_colour_manual(values=cbPalette)#+scale_fill_manual(values=cbPalette),facet_grid="MoonPhase~."facet_grid will place each group of the specified category in a different plot
df <- psmelt(GPr)
df$Abundance=df$Abundance*100
Trtdata <- ddply(df, c("MoonPhase","Family"), summarise,
                 N    = length(Abundance),
                 mean = mean(Abundance),
                 sd   = sd(Abundance),
                 se   = sd / sqrt(N)
)




write.csv(Trtdata,file="FamilyLevelRelativeAbundanceMoonPhase.csv") #Write in other category sum to 100
Trtdata<-read.csv("FamilyLevelRelativeAbundanceMoonPhase.csv", header=T)
head(Trtdata)

FamilyRelativeAbu=ggplot(Trtdata, aes(x=MoonPhase,y=mean))+geom_bar(aes(fill = Family),colour="black", stat="identity")+
  xlab("Moon Phase")+ylab("Relative Invertebrate Abundance")+ theme(axis.text.x = element_text(angle = 45, hjust = 1))+ 
  scale_fill_manual(values=cbPalette)
  theme(legend.text = element_text(size = 8))+ theme(legend.background=element_blank())
FamilyRelativeAbu
dev.off()
tiff("Figures/PhylumLevelRelAbu.tiff", width = 3.5, height = 3.2, units = 'in', res = 300)
PhylumAbu
dev.off()































###############
#Beta diversity
##############

physeq
ord=ordinate(physeq,"PCoA", "jaccard")
ordplot=plot_ordination(physeq, ord,"samples", color="MoonPhase")+scale_colour_manual(values=cbPalette)+scale_fill_manual(values=cbPalette)
ordplotTax<-ordplot+ stat_ellipse(type= "norm",geom = "polygon", alpha = 0, aes(fill = MoonPhase))+
  theme(legend.text = element_text(size = 8))+ theme(legend.background=element_blank())+geom_point(size=2.5)
ordplotTax
dev.off()
tiff("Figures/PCoATax.tiff", width = 3.3, height = 3.3, units = 'in', res = 300)
ordplotTax
dev.off()


GPdist=phyloseq::distance(physeq, "jaccard")
adonis(GPdist ~ MoonPhase*, as(sample_data(physeq), "data.frame"))

######
#Envfit
######
physeqSubset<- subset_samples(physeq, percillum!="NA")
physeqSubset
GPdist=phyloseq::distance(physeq, "jaccard")

vare.mds= ordinate(physeq, "NMDS",GPdist)
#vare.mds <- metaMDS(VeganDist, trace = FALSE)
vare.mds
EnvFitMeta=data.frame(metadata$percillum,metadata$Q,metadata$DPFS)
#EnvFitMeta <- EnvFitMeta[!is.na(EnvFitMeta)]
EnvFitMeta
ef =envfit(vare.mds, EnvFitMeta, na.rm=TRUE, permu=999)
#tax=envfit(vare.mds, EnvFitMeta,na.rm=TRUE)
ef
tax
plot(vare.mds,display="sites")
envplot=plot(ef, p.max = 0.05)


GPdist=phyloseq::distance(physeq, "jaccard")
adonis(GPdist ~ MoonPhase, as(sample_data(physeq), "data.frame"))


###########
#RelAbuInvertsByMoonPhase
############

GPr  = transform_sample_counts(physeq, function(x) x / sum(x) ) #transform samples based on relative abundance
FilteredRelAbu = filter_taxa(GPr, function(x) mean(x) > 2e-2, TRUE) #filter out any taxa lower tha 2%
FilteredRelAbu
df <- psmelt(FilteredRelAbu)
df$Abundance=df$Abundance*100
Trtdata <- ddply(df, c("Family", "MoonPhase"), summarise,
                 N    = length(Abundance),
                 mean = mean(Abundance),
                 sd   = sd(Abundance),
                 se   = sd / sqrt(N)
)
Trtdata
write.csv(Trtdata,"RelAbuByMoonPhaseWOOther.csv")
RelAbuByMoonPhase<-read.csv("RelAbuByMoonPhaseWOther.csv",header=T)
head(RelAbuByMoonPhase)
RelAbuByMoonPhase$MoonPhase = factor(RelAbuByMoonPhase$MoonPhase, levels = c("NewMoon","WaxingCrescent","FirstQuarter","WaxingGibbous","FullMoon","WaningGibbous","LastQuarter","WaningCrescent"))

RelAbuByMoonPhase2<-RelAbuByMoonPhase

cdataplot=ggplot(RelAbuByMoonPhase, aes(x=MoonPhase,y=mean))+geom_bar(aes(fill = Family),colour="black", stat="identity")+xlab("Moon Phase")+
  ylab("Relative Invertebrate Abundance (>1%)") + theme(axis.text.x = element_text(angle = 45, hjust = 1))
cdataplot
SubsetRelAbuMoon<-subset(RelAbuByMoonPhase, Family=="Crayfish"|Family=="Isonychiidae"|Family=="Heptageniidae")
  
cdataplot=ggplot(SubsetRelAbuMoon, aes(x=MoonPhase,y=mean))+geom_bar(aes(fill = Family),colour="black", stat="identity")+xlab("Moon Phase")+
  ylab("Relative Invertebrate Abundance (SEM)") + theme(axis.text.x = element_text(angle = 45, hjust = 1))+geom_errorbar(aes(ymin=mean-se,ymax=mean+se))+facet_grid(Family~.)+scale_fill_manual(values=cbPalette)
cdataplot

length(cbPalette)
compare_means(Abundance ~ MoonPhase, data = df, group.by = "Family", p.adjust.method = "fdr",method="kruskal.test")
Means<-compare_means(Abundance ~ MoonPhase, data = df, group.by = "Family", p.adjust.method = "fdr",method="wilcox.test")

SigList<-length(unique(Trtdata$Family))
for (i in levels(Means$Family)){
  Tax<-i
  TaxAbundance<-subset(Means,Family==i )
  Hyphenated<-as.character(paste0(TaxAbundance$group1,"-",TaxAbundance$group2))
  difference<-TaxAbundance$p.adj
  names(difference)<-Hyphenated
  Letters<-multcompLetters(difference)
  #print(Letters)
  SigList[i]<-Letters
  
}
vec<-unlist(SigList)
vec<-vec[-1]

vec
vector<-c("","","","","","","","","ab","ab","ab","a","ab","b","ab","ab","abc","ab","abc","c","abc","a","abc","b")

SubsetRelAbuMoon
cdataplot=ggplot(SubsetRelAbuMoon, aes(x=MoonPhase,y=mean))+geom_bar(aes(fill = Family),colour="black", stat="identity")+xlab("Moon Phase")+
  ylab("Relative Invertebrate Abundance (SEM)") + theme(axis.text.x = element_text(angle = 45, hjust = 1))+geom_errorbar(aes(ymin=mean-se,ymax=mean+se))+
  facet_grid(Family~.)+scale_fill_manual(values=cbPalette)+theme(legend.position = "none")
cdataplot

###########
#Total abundance top invert taxa
##########


allDrift<-read.table("C:\\Users\\Joe Receveur\\Documents\\MSU data\\Sturgeon\\DataAll\\AllDriftDataCombined2011-2018.txt",header=T)
head(allDrift)
Trtdata <- ddply(allDrift, c("CODE"), summarise,
                 N    = length(Crayfish),
                 mean = mean(Crayfish),
                 sd   = sd(Crayfish),
                 se   = sd / sqrt(N)
)
Trtdata


#################
#Discharge
########

library(lme4)
library(nlme)
library(arm)

model1<-glm(Ninverts100~Temp+percillum+Year+Q, family= poisson,data=ShannonRichness)
summary(model1)

head(ShannonRichness)

ggplot(ShannonRichness,aes(x=Temp,y=Ninverts100))+geom_point()+geom_smooth()#+geom_bar(aes(fill=DPFS),stat = "identity")



model<-glmer(Ninverts100~Q+percillum+Temp,data=ShannonRichness,family = poisson)
summary(model)
(est <- cbind(Estimate = coef(model), confint(model)))
exp(est)


#Old code
##################
