FROM einstore/einstore-base:2.0

WORKDIR /app
COPY . /app

USER 1000

ARG CONFIGURATION="release"
RUN swift build --configuration ${CONFIGURATION} --product EinstoreRun

WORKDIR /app
RUN mv /app/.build/${CONFIGURATION}/EinstoreRun /app

ENTRYPOINT ["/app/EinstoreRun"]
CMD ["serve", "--hostname", "0.0.0.0", "--port", "8080"]
