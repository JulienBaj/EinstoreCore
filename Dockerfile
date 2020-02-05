FROM einstore/einstore-core

RUN chown -R 1000 /app

RUN chmod -R 755 /app

USER 1000
