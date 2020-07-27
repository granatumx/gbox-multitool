## Emacs, make this -*- mode: sh; -*-
 
# [tkwolf 20180712] Using specific dated version
FROM ubuntu:rolling
#FROM bioconductor/bioconductor_docker:latest
# FROM r-base:3.6.3
#debian:testing-20180426

## This handle reaches Carl and Dirk
MAINTAINER "Carl Boettiger and Dirk Eddelbuettel" rocker-maintainers@eddelbuettel.com

## Set a default user. Available via runtime flag `--user docker` 
## Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
## User should also have & own a home directory (for rstudio or linked volumes to work properly). 
# RUN useradd docker \
# 	&& mkdir /home/docker \
# 	&& chown docker:docker /home/docker \
# 	&& addgroup docker staff

ENV DEBIAN_FRONTEND noninteractive
ENV TZ America/New_York

RUN apt-get update
RUN apt-get install -y apt-utils

RUN apt-get install -y --no-install-recommends \
		build-essential \
		libxml2-dev
#		ed
#		less \
#		locales \
#		vim-tiny \
#		wget \
#		ca-certificates \
#		fonts-texgyre \
#		libcurl4-openssl-dev \
#		libc6-dev \
#		libcairo2-dev \
#		libssl-dev \
#		libxt-dev \
#		r-cran-slam \
#		libxml2-dev
#	&& rm -rf /var/lib/apt/lists/*

#--># Configure default locale, see https://github.com/rocker-org/rocker/issues/19
#RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
#	&& locale-gen en_US.utf8 \
#	&& /usr/sbin/update-locale LANG=en_US.UTF-8

#ENV LC_ALL en_US.UTF-8
#ENV LANG en_US.UTF-8

## Use Debian unstable via pinning -- new style via APT::Default-Release
# NOTE: "sid" is always "unstable"; better to set a specific version, e.g., "stretch" [tkwolf 20180712]
#RUN echo "deb http://http.debian.net/debian sid main" > /etc/apt/sources.list.d/debian-unstable.list \
#RUN echo "deb http://http.debian.net/debian stretch main" > /etc/apt/sources.list.d/debian-testing.list \
#	&& echo 'APT::Default-Release "testing";' > /etc/apt/apt.conf.d/default

# Changes to Debian repository led to loss of 3.4.4 in sid; looks like stretch has 3.3.3 and 3.5.1.
# Versions 3.3.3 and 3.5.1 have problems with the current configuration - fgsea didn't install [tkwolf 20180712]
#ENV R_BASE_VERSION 3.4.4
#ENV R_BASE_VERSION 3.3.3-1
#ENV R_BASE_VERSION 3.5.1-1

## Now install R and littler, and create a link for littler in /usr/local/bin
## Also set a default CRAN repo, and make sure littler knows about it too
#RUN apt-get update \
	#&& apt-get install -t unstable -y --no-install-recommends \
#	&& apt-get install -y --no-install-recommends \
#		littler \
#                r-cran-littler \
#		r-base=${R_BASE_VERSION} \
#		r-base-dev=${R_BASE_VERSION} \
#		r-recommended=${R_BASE_VERSION} \
#        && echo 'options(repos = c(CRAN = "https://cran.rstudio.com/"), download.file.method = "libcurl")' >> /etc/R/Rprofile.site \
#        && echo 'source("/etc/R/Rprofile.site")' >> /etc/littler.r \
#	&& ln -s /usr/share/doc/littler/examples/install.r /usr/local/bin/install.r \
#	&& ln -s /usr/share/doc/littler/examples/install2.r /usr/local/bin/install2.r \
#	&& ln -s /usr/share/doc/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
#	&& ln -s /usr/share/doc/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
#	&& install.r docopt \
#	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
#	&& rm -rf /var/lib/apt/lists/*

RUN apt-get install -y gnupg
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN echo "deb http://cloud.r-project.org/bin/linux/ubuntu focal-cran40/" >> /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y r-base-core r-base r-base-dev r-recommended

WORKDIR /usr/src/app

# Installs based on Granatum v1 depenencies install and likely have redundancies,
#   but using the full set of install commands with versions indicated to be clear.
# Performing multiple RUN calls to allow caching to speedup additing future
#   dependencies at the end of the Dockerfile.
# BASH install section
# RUN ["bash","./install.sh"]
# Note: warning about apt-utils likely can be ignored, according to forum: https://github.com/phusion/baseimage-docker/issues/319

# R install section
RUN R -e 'install.packages("BiocManager")'
RUN apt-get install -y libcurl4-gnutls-dev curl libcurl4-gnutls-dev libxml2-dev libssl-dev
RUN R -e 'install.packages("devtools")'
# devtools_1.13.5 (above)
RUN R -e 'install.packages(c("NMF", "Rtsne", "htmltools", "htmlwidgets", "plotly", "Rlof"))'
RUN R -e 'install.packages(c("scales", "reshape2", "purrr", "readr", "stringr", "tidyr"))'
RUN R -e 'install.packages(c("tibble", "forcats", "dplyr", "igraph", "visNetwork"))'

RUN R -e 'BiocManager::install(c("preprocessCore", "futile.logger", "snow"))'
RUN R -e 'BiocManager::install(c("BiocParallel", "gridExtra", "fastmatch"))'
RUN R -e 'BiocManager::install(c("BiocGenerics", "Biobase", "S4Vectors"))'

RUN R -e 'BiocManager::install(c("IRanges"))'

RUN R -e 'install.packages(c("DBI", "RSQLite", "RCurl"))'

RUN R -e 'BiocManager::install(c("AnnotationDbi", "KEGG.db", "GO.db", "org.Hs.eg.db", "org.Mm.eg.db"))'

RUN R -e 'BiocManager::install(c("GenomeInfoDbData", "GenomeInfoDb", "zlibbioc"))'

RUN R -e 'install.packages(c("matrixStats", "XML"))'
RUN R -e 'BiocManager::install(c("XVector", "DelayedArray", "annotate", "genefilter"))'
RUN R -e 'BiocManager::install(c("impute"))'

RUN R -e 'install.packages(c("locfit", "MetaDE", "VGAM", "DDRTree"))'

RUN R -e 'BiocManager::install(c("HSMMSingleCell"))'

RUN R -e 'install.packages(c("fastICA", "densityClust", "qlcMatrix", "pheatmap"))'
RUN R -e 'install.packages(c("proxy", "viridis"))'

RUN R -e 'BiocManager::install(c("graph", "RBGL"))'
RUN R -e 'install.packages(c("RUnit", "RANN"))'
RUN R -e 'BiocManager::install(c("biocViews", "limma"))'

RUN R -e 'devtools::install_github("mohuangx/SAVER", ref="v0.3.0")'

RUN apt-get install -y python3-igraph python3-pip python3-dev libcairo2-dev
RUN pip3 install --upgrade pip setuptools wheel pandas
RUN pip3 install pycairo
RUN pip3 install scanpy
RUN pip3 install plotly
RUN pip3 install mpld3
RUN apt-get install -y python3-tk

RUN R -e 'install.packages(c("flexmix", "RcppArmadillo", "Rook", "rjson"))'
RUN R -e 'install.packages(c("Cairo", "quantreg", "RMTstat", "extRemes"))'
RUN R -e 'BiocManager::install(c("pcaMethods"))'

RUN R -e 'install.packages(c("jsonlite", "rmarkdown", "base64enc"))'

# Updated/added installs
RUN R -e 'BiocManager::install(c("edgeR", "fgsea", "GenomicRanges", "SummarizedExperiment", "sva"))'
RUN R -e 'BiocManager::install(c("scde"))'
RUN apt-get install -y wget
RUN wget https://www.dropbox.com/s/pno78mmlj0exv7s/NODES_0.0.0.9010.tar.gz
RUN R -e 'install.packages("NODES_0.0.0.9010.tar.gz", repos = NULL, type = "source")'
RUN R -e 'BiocManager::install(c("monocle"))'

RUN R -e 'install.packages("pROC")'

COPY . .

# Set version correctly so user can install gbox
# Requires bash and sed to set version in yamls
# Can modify if base OS does not support bash/sed
RUN apt-get update
RUN apt-get install -y sed bash
ARG VER=1.0.0
ARG GBOX=granatumx/gbox-multitool:1.0.0
ENV VER=$VER
ENV GBOX=$GBOX
WORKDIR /usr/src/app
RUN ./GBOXtranslateVERinYAMLS.sh
RUN ./GBOXgenTGZ.sh

CMD ./run_usage.sh
