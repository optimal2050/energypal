library(devtools); load_all(quiet=TRUE)
if(!requireNamespace('ggplot2', quietly=TRUE)) quit('no')
library(ggplot2)
d <- data.frame(source=c('Coal','Solar','Wind'), value=1:3)
sc1 <- ggplot_build(ggplot(d,aes(x=1,y=value,fill=source))+geom_col()+scale_fill_energy(direction=1, palette_direction=1, data=d))$plot$scales$scales[[1]]
sc2 <- ggplot_build(ggplot(d,aes(x=1,y=value,fill=source))+geom_col()+scale_fill_energy(direction=1, palette_direction=-1, data=d))$plot$scales$scales[[1]]
lim <- sc1$get_limits()
cat('Limits:', paste(lim, collapse=', '), '\n')
cat('Colors dir=1:', paste(sc1$values[lim], collapse=', '), '\n')
cat('Colors dir=-1:', paste(sc2$values[lim], collapse=', '), '\n')
print(data.frame(source=lim, col1=sc1$values[lim], col2=sc2$values[lim]))
