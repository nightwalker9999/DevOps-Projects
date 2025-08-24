FROM python:3.11-slim
WORKDIR /srv
RUN pip install --no-cache-dir boto3 pymysql
COPY worker.py /srv/worker.py
COPY db.py /srv/db.py
COPY main.py /srv/main.py
CMD ["python", "/srv/worker.py"]