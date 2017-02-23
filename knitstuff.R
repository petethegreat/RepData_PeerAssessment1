#!/usr/bin/Rscript

library(knitr)
library(markdown)
knit('PA1_template.Rmd') 
markdownToHTML('PA1_template.md','PA1_template.html') 
#file.copy(from='PA1_template.html',to='/home/pete/petes_stuff/PA1_template.html',overwrite=TRUE)
cp PA1_template.html ~/petes_stuff
message('knittted to html, copied to /home/pete/petes_stuff/PA1_template.html')
