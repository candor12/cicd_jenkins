FROM openjdk:11 AS BUILD_IMAGE
RUN apt update && apt install maven -y
RUN git clone -b master https://github.com/azka-begh/CICD-with-Jenkins.git
RUN cd CICD-with-Jenkins && mvn install -DskipTests

FROM tomcat:9-jre11
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=BUILD_IMAGE CICD-with-Jenkins/target/*.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
