# Telebot
## input

```pipeline
write[] readAnJsonl(examples.jsonl)
concat[] prompt
concat[] memory
concat[] input
```

## answer
__rate__ 1

```json
{"temperature": 1.2, "top_p": 0.95, "max_tokens": 2048}
```

# Init
__telegramKey__ 123456:ABC-DEF

__apiUrl__ https://api.openai.com/v1/chat/completions

__apiModel__ gpt-4o

__apiKey__ sk-xxx

# Memory
__lenght__ 30

__prompt__ Ты персонаж фэнтези-мира. Говори от первого лица как эльф-маг. Используй архаичную речь.

__inCut__ 500

__outCut__ 1000