FROM python:3.11-slim
WORKDIR /srv
RUN pip install --no-cache-dir flask boto3
COPY app.py /srv/app.py
EXPOSE 8000
