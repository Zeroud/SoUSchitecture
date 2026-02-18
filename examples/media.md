# Telebot
## input
* sticker
* photo
* video
* videonote
* animation
* caption

__cut__ 200

```pipeline
concat[] prompt
concat[] input
```

## answer
__rate__ 1

```json
{"temperature": 0.5, "max_tokens": 256}
```

# Init
__telegramKey__ 123456:ABC-DEF

__apiUrl__ https://api.openai.com/v1/chat/completions

__apiModel__ gpt-4o

__apiKey__ sk-xxx

# Memory
__lenght__ 5

__inCut__ 100

__outCut__ 300