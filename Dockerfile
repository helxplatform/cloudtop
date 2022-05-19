FROM library/tomcat:9-jre8 as tomcat
# Env for Guacamole
ENV ARCH=amd64 \
  GUAC_VER=1.3.0 \
  GUAC_AUTH_HEADER_VER=1.2.0 \
  GUACAMOLE_HOME=/app/guacamole

# Env for VNC
ENV DISPLAY=:1 \
    VNC_PORT=5901
EXPOSE $VNC_PORT

ENV HOME=/headless \
    TERM=xterm \
    STARTUPDIR=/headless/dockerstartup \
    INST_SCRIPTS=/headless/install \
    NO_VNC_HOME=/headless/noVNC \
    DEBIAN_FRONTEND=noninteractive \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1980x1024 \
    VNC_PW="" \
    VNC_VIEW_ONLY=false \
    TOMCAT_PORT=8080 \
    USER_NAME="" \
    USER_HOME="" \
    USER_ID=1000

ENV USER=$USERID

RUN mkdir $HOME
RUN mkdir $STARTUPDIR
RUN mkdir $INST_SCRIPTS
RUN mkdir -p /usr/local/renci/bin

# Apply the s6-overlay
RUN curl -SLO "https://github.com/just-containers/s6-overlay/releases/download/v1.20.0.0/s6-overlay-${ARCH}.tar.gz" \
  && tar -xzf s6-overlay-${ARCH}.tar.gz -C / \
  && tar -xzf s6-overlay-${ARCH}.tar.gz -C /usr ./bin \
  && rm -rf s6-overlay-${ARCH}.tar.gz \
  && mkdir -p ${GUACAMOLE_HOME} \
    ${GUACAMOLE_HOME}/lib \
    ${GUACAMOLE_HOME}/extensions

# Copy in the static GUACAMOLE configuration files.
ADD ./src/common/guacamole/guacamole.properties ${GUACAMOLE_HOME}
ADD ./src/common/guacamole/user-mapping-template.xml ${GUACAMOLE_HOME}
ADD ./src/common/guacamole/add-user-template.sql ${GUACAMOLE_HOME}

# Copy in the TOMCAT server file as well
ADD ./src/common/tomcat/server-template.xml ${GUACAMOLE_HOME}

WORKDIR ${GUACAMOLE_HOME}

# Install dependencies
RUN apt-get update
RUN apt-get install -y \
  build-essential \
  libcairo2-dev \
  libjpeg62-turbo-dev \
  libpng-dev \
  libtool-bin \
  libossp-uuid-dev \
  libvncserver-dev \
  freerdp2-dev \
  libssh2-1-dev \
  libtelnet-dev \
  libwebsockets-dev \
  libpulse-dev \
  libvorbis-dev \
  libwebp-dev libssl-dev \
  libpango1.0-dev \
  libswscale-dev \
  libavcodec-dev \
  libavutil-dev \
  libavformat-dev

# RUN rm -rf /var/lib/apt/lists/*

# Link FreeRDP to where guac expects it to be
RUN [ "$ARCH" = "armhf" ] && ln -s /usr/local/lib/freerdp /usr/lib/arm-linux-gnueabihf/freerdp || exit 0
RUN [ "$ARCH" = "amd64" ] && ln -s /usr/local/lib/freerdp /usr/lib/x86_64-linux-gnu/freerdp || exit 0

# Install guacamole-server
RUN curl -SLO "http://apache.osuosl.org/guacamole/${GUAC_VER}/source/guacamole-server-${GUAC_VER}.tar.gz" \
  && tar -xzf guacamole-server-${GUAC_VER}.tar.gz \
  && cd guacamole-server-${GUAC_VER} \
  && ./configure \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make install \
  && cd .. \
  && rm -rf guacamole-server-${GUAC_VER}.tar.gz guacamole-server-${GUAC_VER} \
  && ldconfig

# Install guacamole-client
RUN set -x \
  && rm -rf ${CATALINA_HOME}/webapps/ROOT \
  && curl -SLo ${CATALINA_HOME}/webapps/ROOT.war "http://apache.osuosl.org/guacamole/${GUAC_VER}/binary/guacamole-${GUAC_VER}.war" \
  && curl -SLO "http://apache.osuosl.org/guacamole/${GUAC_VER}/binary/guacamole-auth-jdbc-${GUAC_VER}.tar.gz" \
  && tar -xzf guacamole-auth-jdbc-${GUAC_VER}.tar.gz \
  && rm -rf guacamole-auth-jdbc-${GUAC_VER} guacamole-auth-jdbc-${GUAC_VER}.tar.gz

# Add auth-header extensions
RUN set -xe \
  && mkdir ${GUACAMOLE_HOME}/extensions-available \
  && for i in auth-header ; do \
    echo "http://apache.osuosl.org/guacamole/${GUAC_VER}/binary/guacamole-${i}-${GUAC_AUTH_HEADER_VER}.tar.gz" \
    && curl -SLO "http://apache.osuosl.org/guacamole/${GUAC_VER}/binary/guacamole-${i}-${GUAC_AUTH_HEADER_VER}.tar.gz" \
    && tar -xzf guacamole-${i}-${GUAC_AUTH_HEADER_VER}.tar.gz \
    && cp guacamole-${i}-${GUAC_AUTH_HEADER_VER}/guacamole-${i}-${GUAC_AUTH_HEADER_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
    && cp guacamole-${i}-${GUAC_AUTH_HEADER_VER}/guacamole-${i}-${GUAC_AUTH_HEADER_VER}.jar ${GUACAMOLE_HOME}/extensions/ \
    && rm -rf guacamole-${i}-${GUAC_VER} guacamole-${i}-${GUAC_VER}.tar.gz \
  ;done

# Add auth-jdbc extensions
RUN set -xe \
  && for i in auth-jdbc ; do \
    echo "http://apache.osuosl.org/guacamole/${GUAC_VER}/binary/guacamole-${i}-${GUAC_VER}.tar.gz" \
    && curl -SLO "http://apache.osuosl.org/guacamole/${GUAC_VER}/binary/guacamole-${i}-${GUAC_VER}.tar.gz" \
    && tar -xvzf guacamole-${i}-${GUAC_VER}.tar.gz \
    && cp -v guacamole-${i}-${GUAC_VER}/mysql/guacamole-${i}-mysql-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
    && cp -v guacamole-${i}-${GUAC_VER}/mysql/guacamole-${i}-mysql-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions/ \
    && rm -rf guacamole-${i}-${GUAC_VER}.tar.gz \
  ;done

# Grab and install the needed mysql driver
RUN set -xe \
  && curl -SLO "http://ftp.jaist.ac.jp/pub/mysql/Downloads/Connector-J/mysql-connector-java_8.0.26-1debian11_all.deb" \
  && ar x mysql-connector-java_8.0.26-1debian11_all.deb data.tar.xz \
  && tar xvf data.tar.xz \
  && cp -v usr/share/java/mysql-connector-java-8.0.26.jar ${GUACAMOLE_HOME}/extensions-available/ \
  && cp -v usr/share/java/mysql-connector-java-8.0.26.jar ${GUACAMOLE_HOME}/lib/ 
# && rm -rf postgresql-42.2.16.jar

ENV GUACAMOLE_HOME=/config/guacamole

WORKDIR /config

COPY root /

# Reset the WORKDIR for the vnc/desktop install
WORKDIR $HOME

### Add all install scripts for further steps
ADD ./src/common/install/ $INST_SCRIPTS/
ADD ./src/debian/install/ $INST_SCRIPTS/
RUN find $INST_SCRIPTS -name '*.sh' -exec chmod a+x {} +

### Install some common tools
RUN $INST_SCRIPTS/tools.sh
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

### Install custom fonts
RUN $INST_SCRIPTS/install_custom_fonts.sh

### Install xvnc-server & noVNC - HTML5 based VNC viewer
RUN $INST_SCRIPTS/tigervnc.sh

### Install firefox and chrome browser
#RUN $INST_SCRIPTS/firefox.sh

### Install xfce UI
RUN $INST_SCRIPTS/xfce_ui.sh
ADD ./src/common/xfce/ $HOME/

ADD ./src/common/scripts $STARTUPDIR
RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOME

### Make the /usr/local/bin/renci directory
RUN mkdir -p /usr/local/renci/bin

# Remove the light-locker as it's causing trouble
RUN apt purge light-locker -y

EXPOSE 80
EXPOSE 443

ENTRYPOINT [ "/init" ]
