install.packages('Hmisc')
install.packages('xlsReadWrite')
install.packages('csvReadWrite')

library(readxl)
x <- read_excel("~/GitHub/BaxterAlgorithms/VS_Functions/BigData.xlsx")
View(BigData)

corn<-cor(x)

install.packages("corrplot")
library("corrplot")
corrplot(corn, method="circle")
