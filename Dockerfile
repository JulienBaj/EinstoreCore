FROM einstore/einstore-core

RUN chown -R 1000 /app

RUN chmod -R /app

USER 1000
