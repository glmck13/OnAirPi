from __future__ import print_function
from lxml import html
import requests
import os

def radio_handler(event, context):

    query = {}
    speech = ''; audio = ''; stopplay = False
    requesttype = event['request']['type']
    shouldEndSession = True
    help = "This skill streams a live broadcast of the event if it is currently in progress, or plays back a recording of the event if it has already concluded"

    if requesttype == "LaunchRequest":
        query['Intent'] = "StreamAudio"
        query['Request'] = requesttype
        query['Station'] = os.environ.get('ALEXA_STATION')

    elif requesttype == "IntentRequest":
        intent = event['request']['intent']
        intentname = intent['name']

        if intentname == "StreamAudio":
            query['Intent'] = intentname
            query['Request'] = requesttype
            query['Station'] = os.environ.get('ALEXA_STATION')

        elif intentname == "AMAZON.FallbackIntent" or intentname == "AMAZON.HelpIntent":
            speech = help

        elif intentname == "AMAZON.PauseIntent" or intentname == "AMAZON.CancelIntent" or intentname == "AMAZON.StopIntent":
            stopplay = True

        elif intentname == "AMAZON.ResumeIntent":
            pass

    else:
        speech = "Come back any time! Goodbye!"

    if query:
        page = requests.get(os.environ.get('ALEXA_URL'), auth=(os.environ.get('ALEXA_USER'), os.environ.get('ALEXA_PASS')), params=query)
        tree = html.fromstring(page.content)
        speech = tree.xpath('//body/p/text()')[0]
        try:
            audio = tree.xpath('//body//audio/source/@src')[0]
        except:
            audio = ''

    if audio:
        shouldEndSession = True

    response = {
        "version": "1.0",
        "sessionAttributes": {},
        "response": {
            "outputSpeech": {
                "type": "PlainText",
                "text": speech
            },
            "reprompt": {
                "outputSpeech": {
                    "type": "PlainText",
                    "text": ""
                }
            },
            "card": {
                "type": "Simple",
                "title": "Radio Cast",
                "content": speech
            },
            "shouldEndSession": shouldEndSession
        }
    }

    if audio:
        response['response']['directives'] = [
            {
            "type": "AudioPlayer.Play",
            "playBehavior": "REPLACE_ALL",
              "audioItem": {
                "stream": {
                  "token": audio,
                  "url": audio,
                "offsetInMilliseconds": 0
                }
              }
            }
        ]

    if stopplay:
        response['response']['directives'] = [
            {
            "type": "AudioPlayer.ClearQueue",
            "clearBehavior": "CLEAR_ALL"
            }
        ]

    return response
