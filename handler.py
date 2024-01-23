import random
import boto3
import os
import io
import json
# import base64

import sys
package_directory = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'package')
sys.path.append(package_directory)
# import telegram
import requests

s3_client = boto3.client('s3')

def random_image(bucket_name):
    response = s3_client.list_objects_v2(Bucket=bucket_name)
    # print(response)
    
    if 'Contents' in response:
        objects = response['Contents']
        # print(objects)
        random_object = random.choice(objects)
        # print('random_object',random_object)
        object_key = random_object['Key']
        # print('object_key', object_key)
        response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
        
        image_data = response['Body'].read()
        # print("image_data", image_data)
        # https://boto3.amazonaws.com/v1/documentation/api/latest/guide/s3-example-download-file.html

        return image_data


def pick_random_line(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()
        random_line = random.choice(lines).strip()
        return random_line


# Base64 trick
# https://docs.aws.amazon.com/apigateway/latest/developerguide/lambda-proxy-binary-media.html
def lambda_handler(event, context):
    # bucket_name = os.environ.get('S3_BUCKET')
    bot_token = os.environ.get('TELEGRAM_BOT_TOKEN')
    # print("event", event)

    request_body = json.loads(event['body']) # EXtract the Body from the call
    # request_body = event['body'] # EXtract the Body from the call
    # print("request_body", request_body)
    request_msg = json.dumps(request_body['message'])#['chat']['id'] # Extract the message object which contrains chat id and text
    # request_msg = request_body['message'] #['chat']['id'] # Extract the message object which contrains chat id and text
    # print("request_msg", request_msg)

    chat_id = json.dumps(request_body['message']['chat']['id']) # Extract the chat id from message
    command = json.dumps(request_body['message']['text']).strip('"') # Extract the text from the message

    # chat_id = request_body['message']['chat']['id'] # Extract the chat id from message
    # command = request_body['message']['text'].strip('"') # Extract the text from the message
    # command = request_body['message']['text'] # Extract the text from the message
    

    # chat_id # Updating the Bot Chat Id to be dynamic instead of static one earlier

    # if command == '/random':
    match command:
        case '/pepe':
            bucket_name = os.environ.get('S3_BUCKET_PEPE')
            if bucket_name:
                image_data = random_image(bucket_name)
                if image_data:
                    # print(image_data)
                    # bot = telegram.Bot(token=os.environ.get('TELEGRAM_BOT_TOKEN'))
                    # print("bot", bot)
                    # chat_id = os.environ.get('CHAT_ID')
                    # print("chat_id", chat_id)
                    # bot.send_photo(chat_id=int(chat_id), photo=telegram.InputFile.from_bytes(image_data))
                    
                    url = f"https://api.telegram.org/bot{bot_token}/sendPhoto"
                    files = {'photo': ('image.jpg', image_data, 'image/jpeg')}
                    params = {'chat_id': chat_id}
                    requests.post(url, files=files, params=params)
                    # response = requests.post(url, files=files, params=params)
                    # print(response.status_code)
                    
                    # return {
                    #     'isBase64Encoded': True,
                    #     'statusCode': 200,
                    #     'body': base64.b64encode(image_data).decode('utf-8'),
                    #     'headers': {
                    #         'Content-Type': 'image/jpeg'
                    #     }
                    # }

                    return {
                        'statusCode': 200,
                        'body': 'Success'
                    }
                
        case '/kiepscy':
            bucket_name = os.environ.get('S3_BUCKET_KIEPSCY')
            if bucket_name:
                image_data = random_image(bucket_name)
                if image_data:
                    # print(image_data)
                    # bot = telegram.Bot(token=os.environ.get('TELEGRAM_BOT_TOKEN'))
                    # print("bot", bot)
                    # chat_id = os.environ.get('CHAT_ID')
                    # print("chat_id", chat_id)
                    # bot.send_photo(chat_id=int(chat_id), photo=telegram.InputFile.from_bytes(image_data))
                    
                    url = f"https://api.telegram.org/bot{bot_token}/sendPhoto"
                    files = {'photo': ('image.jpg', image_data, 'image/jpeg')}
                    params = {'chat_id': chat_id}
                    requests.post(url, files=files, params=params)
                    # response = requests.post(url, files=files, params=params)
                    # print(response.status_code)
                    
                    # return {
                    #     'isBase64Encoded': True,
                    #     'statusCode': 200,
                    #     'body': base64.b64encode(image_data).decode('utf-8'),
                    #     'headers': {
                    #         'Content-Type': 'image/jpeg'
                    #     }
                    # }

                    return {
                        'statusCode': 200,
                        'body': 'Success'
                    }

    # else if command == '/toast':
        case '/toast':
            file_path = "./toasts.txt"
            message = pick_random_line(file_path)
            # send_text = 'https://api.telegram.org/bot' + bot_token + '/sendMessage?chat_id=' + chat_id + '&parse_mode=HTML&text=' + message
            send_text = f'https://api.telegram.org/bot{bot_token}/sendMessage?chat_id={chat_id}&parse_mode=HTML&text={message}'

            
            response = requests.get(send_text)

            return {
                    'statusCode': 200,
                    'body': 'Success'
                }
        
        case '/laski':
            file_path = "./laski.txt"
            message = pick_random_line(file_path)
            # send_text = 'https://api.telegram.org/bot' + bot_token + '/sendMessage?chat_id=' + chat_id + '&parse_mode=HTML&text=' + message
            send_text = f'https://api.telegram.org/bot{bot_token}/sendMessage?chat_id={chat_id}&parse_mode=HTML&text={message}'

            
            response = requests.get(send_text)

            return {
                    'statusCode': 200,
                    'body': 'Success'
                }

    # else:
        case _:
            message = """Panie, co ja nie rozumiem co Pan do mnie mówisz! 
            Prosze wybrać inną komendę: /memes, /toast"""
            # send_text = 'https://api.telegram.org/bot' + bot_token + '/sendMessage?chat_id=' + chat_id + '&parse_mode=HTML&text=' + message
            send_text = f'https://api.telegram.org/bot{bot_token}/sendMessage?chat_id={chat_id}&parse_mode=HTML&text={message}'

            response = requests.get(send_text)

            return {
                    'statusCode': 200,
                    'body': 'Success (command not found)'
                }

    return {
        'statusCode': 400,
        'body': 'Invalid request'
    }
