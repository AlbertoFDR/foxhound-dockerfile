FROM mcr.microsoft.com/playwright:v1.42.0-jammy 
ENV TZ=Europe/Berlin
ENV DEBIAN_FRONTEND noninteractive

# Set container timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install -y build-essential software-properties-common

RUN mkdir -p /foxhound

# Install VNC and fluxbox to interact with headfull runs
RUN apt-get install -y x11vnc fluxbox

# Install python3 and 
RUN apt-get install -y python3.10 python3-pip

# Install dependencies for cxss experiment (exploit generator)
RUN apt-get install -y libxml2-dev libxslt-dev cmake pkg-config 
RUN mkdir -p /install 
WORKDIR /install

# Build foxhound if enabled
RUN apt-get install -y wget autoconf2.13 ccache libnspr4-dev software-properties-common git bash findutils gzip libxml2 m4 make perl tar unzip watchman
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y  
RUN ${HOME}/.cargo/bin/rustup install 1.72
RUN ${HOME}/.cargo/bin/rustup default 1.72
RUN ${HOME}/.cargo/bin/rustup override set 1.72
RUN . "$HOME/.cargo/env"
RUN mkdir -p /foxhound/build 
RUN mkdir -p /foxhound/playwright 
RUN git clone --branch v1.42.0 https://github.com/microsoft/playwright.git /foxhound/playwright 
RUN GIT_SSL_NO_VERIFY=true git clone https://github.com/SAP/project-foxhound -b main /foxhound/build 
WORKDIR /foxhound/build 
RUN git checkout firefox-release 
RUN ./mach --no-interactive bootstrap --application-choice=browser 
RUN git checkout b7b14a34b37fc820fcdf65384798cfb888cfa73b 
RUN git apply --index --whitespace=nowarn /foxhound/playwright/browser_patches/firefox/patches/* 
RUN cp -r /foxhound/playwright/browser_patches/firefox/juggler /foxhound/build/juggler 
RUN cp taintfox_mozconfig_ubuntu .mozconfig 
RUN sed -i 's/ac_add_options --enable-bootstrap/# ac_add_options --enable-bootstrap/g' .mozconfig 
RUN echo "ac_add_options --disable-crashreporter" >> .mozconfig 
RUN echo "ac_add_options --disable-backgroundtasks" >> .mozconfig 
RUN echo "ac_add_options --enable-release" >> .mozconfig 
RUN echo "ac_add_options --without-wasm-sandboxed-libraries" >> .mozconfig 
RUN ./mach build 
RUN cp /foxhound/playwright/browser_patches/firefox/preferences/00-playwright-prefs.js /foxhound/build/obj-tf-release/dist/bin/browser/defaults/preferences/00-playwright-prefs.js
RUN cp /foxhound/playwright/browser_patches/firefox/preferences/playwright.cfg /foxhound/build/obj-tf-release/dist/bin/playwright.cfg

RUN useradd -ms /bin/bash bubu
RUN chown -R bubu /foxhound
USER bubu
WORKDIR /foxhound
ENTRYPOINT ["tail -n /dev/null"]
