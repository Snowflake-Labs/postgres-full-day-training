FROM postgis/postgis:18-3.6

# Install additional extensions
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-18-hypopg \
        postgresql-18-pgaudit \
        postgresql-18-pgvector \
    && rm -rf /var/lib/apt/lists/*
