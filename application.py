import os
import time
import logging
from flask import Flask, request, jsonify
import boto3
import openai
from openai import OpenAI
from werkzeug.utils import secure_filename
from dotenv import load_dotenv
from convert import convert_video_to_aws_rekognition

# =============================================================================
# Environment & Configuration Setup
# =============================================================================

# Load environment variables from the .env file
load_dotenv()

# OpenAI configuration
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
openai.api_key = OPENAI_API_KEY

# AWS configuration
AWS_REGION = "us-east-1"
S3_BUCKET = "jchang-fbla-bucket"

# Upload configuration
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_FOLDER = os.path.join(BASE_DIR, "uploads")
ALLOWED_EXTENSIONS = {'mp4', 'mov', 'avi'}
MAX_CONTENT_LENGTH = 100 * 1024 * 1024  # 100MB

# =============================================================================
# Logging Setup
# =============================================================================

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# =============================================================================
# AWS Client Initialization Functions
# =============================================================================

def get_s3_client():
    """
    Initialize and return an AWS S3 client.
    
    Raises:
        Exception: If the client initialization fails.
    """
    try:
        logger.info("Initializing S3 client...")
        client = boto3.client("s3", region_name=AWS_REGION)
        logger.info("S3 client initialized successfully.")
        return client
    except Exception as e:
        logger.error(f"Error initializing S3 client: {str(e)}")
        raise

def get_rekognition_client():
    """
    Initialize and return an AWS Rekognition client.
    
    Raises:
        Exception: If the client initialization fails.
    """
    try:
        logger.info("Initializing Rekognition client...")
        client = boto3.client("rekognition", region_name=AWS_REGION)
        logger.info("Rekognition client initialized successfully.")
        return client
    except Exception as e:
        logger.error(f"Error initializing Rekognition client: {str(e)}")
        raise

# Create AWS clients
s3_client = get_s3_client()
rekognition_client = get_rekognition_client()

# =============================================================================
# OpenAI Client Initialization
# =============================================================================

# Initialize the OpenAI client (GPT) using the provided API key
gpt_client = OpenAI(api_key=OPENAI_API_KEY)

# =============================================================================
# Utility Functions
# =============================================================================

def allowed_file(filename):
    """
    Check if the uploaded file has an allowed extension.
    
    Args:
        filename (str): Name of the file.
    
    Returns:
        bool: True if file extension is allowed, False otherwise.
    """
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def save_uploaded_file(file, upload_folder):
    """
    Save the uploaded file to the specified folder.
    
    Args:
        file: The uploaded file object from the request.
        upload_folder (str): The directory where the file will be saved.
    
    Returns:
        str: The absolute path to the saved file.
    """
    filename = secure_filename(file.filename)
    file_path = os.path.join(upload_folder, filename)
    logger.info(f"Saving uploaded file to: {file_path}")
    file.save(file_path)
    return file_path

def poll_face_detection(job_id):
    """
    Poll the AWS Rekognition face detection job until completion.
    
    Args:
        job_id (str): The ID of the Rekognition face detection job.
    
    Returns:
        dict: A dictionary containing the detection results including video metadata and faces.
    
    Raises:
        Exception: If the face detection job fails.
    """
    while True:
        response = rekognition_client.get_face_detection(JobId=job_id)
        status = response['JobStatus']
        logger.info(f"Job status for ID {job_id}: {status}")

        if status == 'SUCCEEDED':
            return {
                "status": "SUCCEEDED",
                "video_metadata": response.get('VideoMetadata', {}),
                "faces": response.get('Faces', []),
                "next_token": response.get('NextToken', '')
            }
        elif status == 'IN_PROGRESS':
            logger.info("Face detection still in progress, waiting...")
            time.sleep(5)
        else:
            error_message = response.get('StatusMessage', 'Face detection failed')
            logger.error(f"Face detection failed: {error_message}")
            raise Exception(error_message)

def process_face_detection(video_name):
    """
    Initiate and poll AWS Rekognition face detection on a video stored in S3.
    
    Args:
        video_name (str): The name of the video file in the S3 bucket.
    
    Returns:
        Flask response: A JSON response containing the face detection results.
    """
    try:
        logger.info(f"Starting face detection for video: {video_name}")
        response = rekognition_client.start_face_detection(
            Video={"S3Object": {"Bucket": S3_BUCKET, "Name": video_name}},
            FaceAttributes='ALL'
        )
        job_id = response["JobId"]
        logger.info(f"Face detection started with job ID: {job_id}")

        # Poll the job until it completes successfully or fails
        result = poll_face_detection(job_id)
        return jsonify(result), 200

    except Exception as e:
        logger.error(f"Face detection error: {str(e)}")
        return jsonify({"error": str(e)}), 500

# =============================================================================
# Flask Application Factory
# =============================================================================

def create_app():
    """
    Create and configure the Flask application.
    
    Returns:
        Flask: The configured Flask app instance.
    """
    app = Flask(__name__)
    
    # Configure upload settings
    app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER
    app.config["MAX_CONTENT_LENGTH"] = MAX_CONTENT_LENGTH
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    
    # -------------------------------------------------------------------------
    # Home Route
    # -------------------------------------------------------------------------
    @app.route("/", methods=["GET"])
    def home():
        """
        Home endpoint to check if the app is running.
        
        Returns:
            str: A welcome message.
        """
        return "Welcome to the Flask app!"

    # -------------------------------------------------------------------------
    # GPT API Route
    # -------------------------------------------------------------------------
    @app.route("/gpt", methods=["POST"])
    def gpt_api():
        """
        Endpoint to interact with the GPT API.
        
        Expects a JSON payload with a key 'input' containing the user's prompt.
        
        Returns:
            JSON: The GPT response or an error message.
        """
        logger.info("Received request for GPT API.")
        data = request.get_json()
        user_input = data.get("input", "")

        if not user_input:
            logger.warning("No input provided.")
            return jsonify({"error": "No input provided"}), 400

        try:
            response = gpt_client.chat.completions.create(
                model="gpt-3.5-turbo",  # Change to "gpt-4" if available
                messages=[{"role": "user", "content": user_input}],
                max_tokens=150
            )
            gpt_response = response.choices[0].message.content
            logger.info("Returning response from GPT API.")
            return jsonify({"response": gpt_response}), 200

        except Exception as e:
            logger.error(f"Error processing GPT API: {str(e)}")
            return jsonify({"error": str(e)}), 500

    # -------------------------------------------------------------------------
    # Video Upload Route
    # -------------------------------------------------------------------------
    @app.route("/upload", methods=["POST"])
    def upload_video():
        """
        Endpoint to handle video uploads, conversion, S3 upload, and face detection.
        
        Expects a multipart/form-data request with a 'file' key.
        
        Returns:
            JSON: The face detection results or an error message.
        """
        logger.info("Received request for video upload.")

        # Validate file upload
        if "file" not in request.files:
            logger.error("No file part in request")
            return jsonify({"error": "No file part"}), 400

        file = request.files["file"]

        if file.filename == "":
            logger.error("No selected file")
            return jsonify({"error": "No file selected"}), 400

        if not allowed_file(file.filename):
            logger.error(f"Invalid file type: {file.filename}")
            return jsonify({"error": "Invalid file type. Allowed types: mp4, mov, avi"}), 400

        try:
            # Save the uploaded file locally
            saved_file_path = save_uploaded_file(file, app.config["UPLOAD_FOLDER"])
            logger.info(f"File saved at: {saved_file_path}")

            # Convert the video to a format suitable for AWS Rekognition
            logger.info("Converting video to AWS Rekognition format...")
            converted_path = convert_video_to_aws_rekognition(saved_file_path)
            logger.info(f"Converted video saved at: {converted_path}")

            # Upload the converted video to S3
            converted_filename = os.path.basename(converted_path)
            logger.info(f"Uploading converted video to S3: {converted_filename}")
            s3_client.upload_file(converted_path, S3_BUCKET, converted_filename)

            # Initiate and process face detection
            return process_face_detection(converted_filename)

        except Exception as e:
            logger.error(f"Upload processing error: {str(e)}")
            return jsonify({"error": str(e)}), 500

    return app

# =============================================================================
# Main Entry Point
# =============================================================================

if __name__ == "__main__":
    app = create_app()
    app.run(host='0.0.0.0', port=8000, debug=True)
