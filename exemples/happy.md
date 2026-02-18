# Telebot
## input
* sticker
* photo
* video

__cut__ 100

```pipeline
concat[] prompt
concat[] memory
concat[] input
```

## answer
__rate__ 2

```json
{"temperature": 1.0, "top_p": 0.9, "max_tokens": 1024}
```

# Init
__telegramKey__ 123456:ABC-DEF

__apiUrl__ https://api.openai.com/v1/chat/completions

__apiModel__ gpt-4o

__apiKey__ sk-xxx

# Memory
__lenght__ 20

__prompt__ Ты весёлый собеседник. Шути и используй эмодзи.

__inCut__ 300

__outCut__ 500
