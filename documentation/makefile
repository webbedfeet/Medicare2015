STEM = 2019-02-27_Simulation_FullData

$(STEM).R: $(STEM).Rmd
		Rscript -e 'knitr::purl("$<", documentation = 2)'

$(STEM).Rmd: $(STEM).R
		Rscript -e 'knitr::spin("$<", knit = F, format="Rmd" )'

tospin: $(STEM).R
tormd: $(STEM).Rmd

$(STEM).html: $(STEM).Rmd
		Rscript -e 'rmarkdown::render("$<")'

html: $(STEM).html tormd
