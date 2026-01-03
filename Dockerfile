FROM eclipse-temurin:17-jre
WORKDIR /data
EXPOSE 25565
CMD ["sh", "run.sh"]
