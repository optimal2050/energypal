library(devtools); load_all(quiet=TRUE); library(ggplot2)
d <- data.frame(source=c('Coal','Solar','Wind'), value=1:3)
sc1 <- ggplot_build(ggplot(d,aes(1,value,fill=source))+geom_col()+scale_fill_energy(direction=1,palette_direction=1,data=d))$plot$scales$scales[[1]]
sc2 <- ggplot_build(ggplot(d,aes(1,value,fill=source))+geom_col()+scale_fill_energy(direction=1,palette_direction=-1,data=d))$plot$scales$scales[[1]]
lims <- sc1$get_limits()
col1 <- sc1$palette(length(lims))
col2 <- sc2$palette(length(lims))
print(lims)
print(col1)
print(col2)
