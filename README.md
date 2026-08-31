> [!WARNING]  
> This project is still **highly experimental**, but we would be
> delighted to receive feedback (but please be careful with
> production).

# pidgio

> **Pidgio** is a very small JSONRPC library for defining servers that
> uses Pidgin to serialize results and deserialize requests. It writes
> to `stdout` and reads from `stdin`. It was designed primarily to be
> called by another program (such as Emacs).

## Trivia

Pidgio is a broadly generic implementation of the experiment described
in [Kohai](https://github.com/xvw/kohai) for **controlling software
from within Emacs** (and potentially other editors). Its goal is not
to be very strict in how it handles JSON-RPC, but to make it easy to
take advantage of a code editor’s toolkit to get a user interface
“_for free_” when building software. The general idea is described in
the [following
presentation](https://docs.google.com/presentation/d/e/2PACX-1vSarzOfan3JksrwgEZ2xlEBcJfafD_VoGsad3J37I8HvynUGUJETLxHH6RVl6IP_2na4UxKMscZZJLo/pub?start=false&loop=false&delayms=60000#slide=id.p).
