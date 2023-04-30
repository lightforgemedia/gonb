# Jupyter Notebook + GoNB docker
#
# To use it, go to a directory that you want to make available to the Jupyter notebook
# (your home directory, or a directory where to store the notebook files). It will be
# mounted on the `work/` sub-directory in JupyterLab.
#
# To start it:
#
# ```
# docker pull janpfeifer/gonb_jupyter:latest
# docker run -it --rm -p 8888:8888 -v "${PWD}":/home/jovyan/work janpfeifer/gonb_jupyterlab:latest
# ```
#
# Then copy&paste the URL it outputs in your browser.

#######################################################################################################
# Base image from JupyterLab
#######################################################################################################
ARG BASE_IMAGE=jupyter/base-notebook
ARG BASE_TAG=latest
FROM ${BASE_IMAGE}:${BASE_TAG}

# Update apt and install basic utils
USER root
RUN apt-get update --yes && apt-get install --yes --no-install-recommends wget

#######################################################################################################
# Go and GoNB Libraries
#######################################################################################################
ENV GO_VERSION=1.20.3
ENV GOROOT=/usr/local/go
ENV GOPATH=${HOME}/go
ENV PATH=$PATH:$GOROOT/bin:$GOPATH/bin

USER root
WORKDIR /usr/local
RUN wget --quiet --output-document=- "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" | tar -xz \
    && go version

# Other tools that may be useful for Go users -- including gcc for CGO libraries support.
RUN apt-get install -y \
    git libtool pkg-config build-essential autoconf automake uuid-dev libzmq3-dev \
    gcc g++

# Install GoNB (https://github.com/janpfeifer/gonb) in the jovyan's user account (default user)
USER $NB_USER
WORKDIR ${HOME}
RUN go install github.com/janpfeifer/gonb@latest && \
    go install golang.org/x/tools/cmd/goimports@latest && \
    go install golang.org/x/tools/gopls@latest && \
    gonb --install

# Make tutorial available by default, so it can be used.
COPY --link examples/tutorial.ipynb ${HOME}

#######################################################################################################
# Finishing touches
#######################################################################################################

# Clean up space used by apt.
USER root
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Start-up.
WORKDIR ${HOME}
EXPOSE 8888
USER $NB_USER
