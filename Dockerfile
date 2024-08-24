FROM jenkins/jenkins

USER root

# Instalar Maven
RUN apt-get update && \
    apt-get install -y maven && \
    rm -rf /var/lib/apt/lists/*

# Configurar el entorno de Maven
ENV M2_HOME=/usr/share/maven
ENV PATH="${M2_HOME}/bin:${PATH}"

# Configurar JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

USER jenkins