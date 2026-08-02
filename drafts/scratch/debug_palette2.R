library(devtools); load_all(quiet=TRUE)
library(ggplot2)
d <- data.frame(source=c('Coal','Solar','Wind'), value=1:3)
sc <- ggplot_build(ggplot(d,aes(x=1,y=value,fill=source))+geom_col()+scale_fill_energy(direction=1, palette_direction=1, data=d))$plot$scales$scales[[1]]
str(sc$values)
print(sc$values)
print(names(sc$values))
print(sc$get_limits())
