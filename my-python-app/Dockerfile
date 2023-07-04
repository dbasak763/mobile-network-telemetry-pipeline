# Use an appropriate base image with Python pre-installed
FROM python:3.9

# Set the working directory inside the container
WORKDIR /app

# Copy the requirements.txt file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the app code to the container
COPY . .

# Set the entrypoint command to run your Python application
CMD [ "python", "app.py" ]
