# Use an appropriate base image with Python pre-installed
FROM python:3.9

# Set the working directory inside the container
WORKDIR /app

# Copy the requirements.txt file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the app code to the container
COPY . .

# A threaded process preserves an accurate in-process Prometheus registry; GKE
# provides process-level horizontal scaling. All versions were available in 2023.
ENV GUNICORN_WORKERS=1
CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:5050 --workers ${GUNICORN_WORKERS} --threads 32 --timeout 30 app:app"]
