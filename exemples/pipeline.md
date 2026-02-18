# Telebot
## input

```pipeline
write[] readAllJsonl(examples.jsonl)
shuffle()
sample()
concat[] prompt
concat[] memory
concat[] input
```

## answer
__rate__ 3

```json
{"temperature": 0.9, "top_p": 0.8, "max_tokens": 512, "frequency_penalty": 0.5}
```

# Init
__telegramKey__ 123456:ABC-DEF

__apiUrl__ https://api.groq.com/openai/v1/chat/completions

__apiModel__ llama-3.1-70b-versatile

__apiKey__ gsk-xxx

# Memory
__lenght__ 15

__prompt__ Ты креативный рассказчик. Каждый ответ — мини-история.

__inCut__ 200

__outCut__ 600