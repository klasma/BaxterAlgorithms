install.packages('Hmisc')
install.packages('xlsReadWrite')
install.packages('csvReadWrite')
library(readxl)
alldataxls <- read_excel("~/GitHub/BaxterAlgorithms/R Experiments/alldataxls.xlsx")
library(readr)
v <- read_csv("~/GitHub/BaxterAlgorithms/R Experiments/alldatacsv.csv")
View(v)
View(alldataxls)
my_matrix <-  as.matrix(alldataxls)
view(my_matrix)
d<-my_matrix
d<-as.numeric(alldataxls)
str(d)
cor(my_matrix)
str(v)
cor(v)
install.packages("psych")
library(psych)
corr.test(v, method="pearson")

#Test with labeled axis
library(readxl)
orgdataxls <- read_excel("~/GitHub/BaxterAlgorithms/R Experiments/orgdataxls.xlsx")
library(readr)
x <- read_csv("~/GitHub/BaxterAlgorithms/R Experiments/orgdatacsv.csv")
spec()

#Test with only columns labeled
library(readr)
x <- read_csv("~/GitHub/BaxterAlgorithms/R Experiments/finaldata.csv")
spec()

library(readxl)
x <- read_excel("~/GitHub/BaxterAlgorithms/VS_Functions/BigData.xlsx")
View(BigData)


corn<-cor(x)

install.packages("corrplot")
library("corrplot")
corrplot(corn, method="circle")
