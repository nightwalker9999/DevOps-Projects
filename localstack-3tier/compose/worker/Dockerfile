FROM python:3.11-slim
WORKDIR /srv
RUN pip install --no-cache-dir boto3
COPY worker.py /srv/worker.py
