# Native packages
import random
import boto3
import os
# import io
import json
import logging
import sys

# Custom packages
# Set up package path
package_directory = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'package')
sys.path.append(package_directory)


import requests
import yaml

# Initialize S3 client
S3_CLIENT = boto3.client('s3')

# Set up logging
LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)


TELEGRAM_BOT_TOKEN = os.environ.get('TELEGRAM_BOT_TOKEN')

CONFIG_FILE_PATH = 'config.yml'


def set_webhook(bot_token):
    """Set up webhook for use with Telegram"""
    url = f"https://api.telegram.org/bot{bot_token}/setWebhook"
    params = {'url': os.environ.get('AWS_WEBHOOK_URL')}
    response = requests.get(url, params=params)
    return response


def load_config():
    """Load configuration from YAML file."""
    with open(CONFIG_FILE_PATH, 'r') as config_file:
        CONFIG = yaml.safe_load(config_file)
    return CONFIG



def random_image(bucket_name):
    """Retrieve a random image from the specified S3 bucket."""
    # Inefficient - the larger bucket, the longer return time
    # However it works for now
    response = S3_CLIENT.list_objects_v2(Bucket=bucket_name)
    # print(response)
    
    if 'Contents' in response:
        objects = response['Contents']
        random_object = random.choice(objects)
        object_key = random_object['Key']
        response = S3_CLIENT.get_object(Bucket=bucket_name, Key=object_key)
        image_data = response['Body'].read()
        # https://boto3.amazonaws.com/v1/documentation/api/latest/guide/s3-example-download-file.html

        return image_data


def pick_random_line(file_path):
    """Pick a random line from the specified text file."""
    with open(file_path, 'r') as file:
        lines = file.readlines()
        random_line = random.choice(lines).strip()
        return random_line

def send_telegram_photo(bot_token, chat_id, photo_data):
    url = f"https://api.telegram.org/bot{bot_token}/sendPhoto"
    files = {'photo': ('image.jpg', photo_data, 'image/jpeg')}
    params = {'chat_id': chat_id}
    response = requests.post(url, files=files, params=params)
    return response


def send_telegram_message(bot_token, chat_id, text):
    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    params = {'chat_id': chat_id, 'parse_mode': 'HTML', 'text': text}
    response = requests.get(url, params=params)
    return response

def handle_image_command(bot_token, chat_id, storage_location):
    """Handle commands of type 'image'."""
    image_data = random_image(storage_location)
    send_telegram_photo(bot_token, chat_id, image_data)
    return 'Success'


def handle_text_command(bot_token, chat_id, file_path):
    """Handle commands of type 'text'."""
    if file_path:
        message = pick_random_line(file_path)
        send_telegram_message(bot_token, chat_id, message)
        return 'Success'
    else:
        return 'Invalid configuration: "file" property not found for text command.'


def handle_command(command, chat_id, bot_token, config):
    """Handle the specified command."""
    # Iterate through each command in the configuration
    for cmd_config in config.get('commands', []):
        # Check if the command name matches the specified command in config
        if 'name' in cmd_config and cmd_config['name'] == command:
            # Get the type of the command (e.g., 'image' or 'text')
            cmd_type = cmd_config.get('type', None)
            # Based on the command type, call the appropriate handler function
            if cmd_type == 'image':
                storage_location = cmd_config.get('storage', None)
                return handle_image_command(bot_token, chat_id, storage_location)
            elif cmd_type == 'text':
                file_path = cmd_config.get('file', None)
                return handle_text_command(bot_token, chat_id, file_path)


    # Default response when no matching command is found
    
    # Fetch "command not found" message from config or use a default
    default_not_found_message = 'Command not found. Please choose a valid command.'
    not_found_message = config.get('command_not_found_message', default_not_found_message)

    send_telegram_message(bot_token, chat_id, not_found_message)

    return 'Command not found'


def lambda_handler(event, context):
    LOGGER.info("Lambda incoming event: %s", json.dumps(event))
    # bot_token = os.environ.get('TELEGRAM_BOT_TOKEN')

    # This is used for testing on AWS Lambda
    try:
        if event.get('setWebhook', {}) != {}:
            if event.get("setWebhook"):
                response = set_webhook(TELEGRAM_BOT_TOKEN)
                return {'statusCode': 200, 'body': str(response)}
        # Check if 'body' in the event is a string or JSON object
        if isinstance(event['body'], str):
            # Parse as JSON if 'body' is a string
            request_body = json.loads(event['body'])
        else:
            # Assume 'body' is already a JSON object
            request_body = event.get('body', {})

        # Extract chat ID and command from the request body
        CHAT_ID = request_body['message']['chat']['id']
        COMMAND = request_body['message']['text'].strip('"')

        # Load configuration from 'config.yml'
        CONFIG = load_config()

        # Handle the specified command and get the response body
        response_body = handle_command(COMMAND, CHAT_ID, TELEGRAM_BOT_TOKEN, CONFIG)
        return {'statusCode': 200, 'body': response_body}
    
    except KeyError as e:
        # Handle KeyError if required fields are missing
        LOGGER.error(f"KeyError: {str(e)}")
        return {'statusCode': 400, 'body': 'Invalid request: Missing required field.'}
    
    except json.JSONDecodeError as e:
        # Handle JSONDecodeError if there is an issue with JSON decoding
        LOGGER.error(f"JSONDecodeError: {str(e)}")
        return {'statusCode': 400, 'body': 'Invalid JSON format in the request body.'}

    
    except Exception as e:
        # Handle other exceptions and log the error
        LOGGER.error(f"Error handling request: {str(e)}")
        return {'statusCode': 500, 'body': 'Internal Server Error'}

