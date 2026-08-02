library(devtools); load_all(quiet=TRUE)
if(!requireNamespace('ggplot2', quietly=TRUE)) quit('no')
library(ggplot2)
d <- data.frame(source=c('Coal','Solar','Wind'), value=1:3)
sc1 <- ggplot_build(ggplot(d,aes(1,value,fill=source))+geom_col()+scale_fill_energy(direction=1,palette_direction=1,data=d))$plot$scales$scales[[1]]
sc2 <- ggplot_build(ggplot(d,aes(1,value,fill=source))+geom_col()+scale_fill_energy(direction=1,palette_direction=-1,data=d))$plot$scales$scales[[1]]
print(list(limits1=sc1$get_limits(), values1=sc1$values, limits2=sc2$get_limits(), values2=sc2$values))
